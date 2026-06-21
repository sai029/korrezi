import { createHash } from "node:crypto";

import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import { VertexAI } from "@google-cloud/vertexai";

initializeApp();

// Firestore と同じ東京リージョンで動かす。
setGlobalOptions({ region: "asia-northeast1" });

// GNews.io の API キー。`firebase functions:secrets:set GNEWS_API_KEY` で登録する。
const GNEWS_API_KEY = defineSecret("GNEWS_API_KEY");

// Vertex AI（Gemini）の設定。認証は関数の実行サービスアカウント（ADC）を使うため
// API キーは不要。モデルが広く利用可能な us-central1 を既定にする。
const VERTEX_LOCATION = "us-central1";
const GEMINI_MODEL = "gemini-2.5-flash";

/** GNews API のレスポンス記事。 */
interface GNewsArticle {
  title: string;
  description: string | null;
  content: string | null;
  url: string;
  image: string | null;
  publishedAt: string;
  source: { name: string; url: string } | null;
}

interface GNewsResponse {
  totalArticles: number;
  articles: GNewsArticle[];
}

/** Gemini が返す子ども向け変換結果。 */
interface ChildFriendly {
  displayTitle: string;
  displayTagline: string;
  childBodyWithRuby: string;
  parentSummary: string;
}

/** 記事 URL から安定した doc id を作る（再取得時は冪等に上書き）。 */
function newsIdFromUrl(url: string): string {
  const hash = createHash("sha1").update(url).digest("hex").slice(0, 16);
  return `news_${hash}`;
}

/** description を表示用タグラインへ整える（長い場合は切り詰め）。 */
function toTagline(description: string | null): string {
  const text = (description ?? "").trim();
  if (text.length <= 80) return text;
  return `${text.slice(0, 79)}…`;
}

/** Gemini 変換に失敗したときの素朴なフォールバック（生記事のまま）。 */
function rawFallback(a: GNewsArticle): ChildFriendly {
  return {
    displayTitle: a.title,
    displayTagline: toTagline(a.description),
    childBodyWithRuby: a.content ?? a.description ?? "",
    parentSummary: a.description ?? "",
  };
}

// Vertex AI クライアントは関数インスタンス内で使い回す。
let cachedModel: ReturnType<VertexAI["getGenerativeModel"]> | null = null;
function getGeminiModel() {
  if (cachedModel) return cachedModel;
  const project = process.env.GCLOUD_PROJECT;
  const vertex = new VertexAI({ project, location: VERTEX_LOCATION });
  cachedModel = vertex.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: {
      temperature: 0.7,
      responseMimeType: "application/json",
    },
  });
  return cachedModel;
}

/**
 * 1記事を子ども向け（やさしい言葉＋ルビ）に変換する。
 *
 * ルビは `〔漢字｜よみ〕` markup（アプリの FuriganaText が解釈する形式）で埋め込む。
 * 失敗時は生記事へフォールバックして処理を止めない。
 */
async function toChildFriendly(a: GNewsArticle): Promise<ChildFriendly> {
  const source = [
    `タイトル: ${a.title}`,
    `概要: ${a.description ?? ""}`,
    `本文: ${a.content ?? ""}`,
  ].join("\n");

  const prompt = [
    "あなたは小学生向けニュースの編集者です。次のニュース記事を、6〜10歳の子どもが",
    "読めるように、やさしい日本語で書き直してください。難しい言葉は避け、",
    "短い文にします。事実は変えないでください。",
    "",
    "出力は必ず次の4キーを持つJSONだけにしてください（前後に説明文を付けない）:",
    '- "display_title": 子ども向けの短いタイトル（20文字以内・記号や煽りは不要）',
    '- "display_tagline": 興味を引く一言（30文字以内）',
    '- "child_body_with_ruby": 本文（2〜4文）。小学校で習わない漢字には',
    "  〔漢字｜よみ〕 の形式でルビを付ける（例: 〔環境｜かんきょう〕）。ひらがなだけにしない。",
    '- "parent_summary": 保護者向けの箇条書き要約。各行を「・」で始め、2〜3項目。',
    "",
    "記事:",
    source,
  ].join("\n");

  try {
    const model = getGeminiModel();
    const result = await model.generateContent({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
    });
    const text =
      result.response.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const parsed = JSON.parse(text) as Record<string, unknown>;

    const pick = (k: string, fallback: string): string => {
      const v = parsed[k];
      return typeof v === "string" && v.trim().length > 0 ? v.trim() : fallback;
    };
    const fb = rawFallback(a);
    return {
      displayTitle: pick("display_title", fb.displayTitle),
      displayTagline: pick("display_tagline", fb.displayTagline),
      childBodyWithRuby: pick("child_body_with_ruby", fb.childBodyWithRuby),
      parentSummary: pick("parent_summary", fb.parentSummary),
    };
  } catch (err) {
    logger.warn("Gemini transform failed; using raw fallback", {
      url: a.url,
      err: `${err}`,
    });
    return rawFallback(a);
  }
}

/**
 * GNews から日本語トップ記事を取得し、Gemini で子ども向けに変換して Firestore へ書き込む。
 *
 * - `/news_pool/{id}`                     … 全ユーザー共通の元記事（子ども向け本文＋親要約）
 * - `/users/{uid}/personalized_feed/{id}` … 呼び出しユーザー向けフィード
 */
export const fetchNews = onCall(
  { secrets: [GNEWS_API_KEY], timeoutSeconds: 300, memory: "512MiB" },
  async (request): Promise<{ count: number }> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "ログインが必要です。");
    }

    const params = new URLSearchParams({
      lang: "ja",
      country: "jp",
      max: "10",
      apikey: GNEWS_API_KEY.value(),
    });
    const endpoint = `https://gnews.io/api/v4/top-headlines?${params.toString()}`;

    let data: GNewsResponse;
    try {
      const res = await fetch(endpoint);
      if (!res.ok) {
        const body = await res.text();
        logger.error("GNews request failed", { status: res.status, body });
        throw new HttpsError(
          "unavailable",
          `GNews API エラー (status ${res.status})`,
        );
      }
      data = (await res.json()) as GNewsResponse;
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logger.error("GNews fetch threw", err);
      throw new HttpsError("unavailable", "GNews への接続に失敗しました。");
    }

    const articles = data.articles ?? [];
    if (articles.length === 0) {
      return { count: 0 };
    }

    // 各記事を Gemini で子ども向けに変換（並列）。失敗分は生記事へフォールバック。
    const converted = await Promise.all(articles.map(toChildFriendly));

    const db = getFirestore();
    const batch = db.batch();

    articles.forEach((a, i) => {
      const id = newsIdFromUrl(a.url);
      const cf = converted[i];

      // /news_pool/{id} … firestore_seeder と同じ snake_case スキーマ。
      batch.set(db.collection("news_pool").doc(id), {
        original_title: a.title,
        published_at: Timestamp.fromDate(new Date(a.publishedAt)),
        parent_summary: cf.parentSummary,
        child_body_with_ruby: cf.childBodyWithRuby,
      });

      // 画像があれば generated モードで NetworkImage 表示、無ければ text_overlay。
      const image = a.image ?? "";
      const thumbnailConfig = image
        ? { mode: "generated", base_asset: "", optional_generated_url: image }
        : { mode: "text_overlay", base_asset: "", optional_generated_url: "" };

      batch.set(
        db
          .collection("users")
          .doc(uid)
          .collection("personalized_feed")
          .doc(id),
        {
          news_id: id,
          interest_context: a.source?.name ?? "ニュース",
          display_title: cf.displayTitle,
          display_tagline: cf.displayTagline,
          thumbnail_config: thumbnailConfig,
          is_viewed: false,
          view_duration_seconds: 0,
        },
      );
    });

    await batch.commit();
    logger.info(`fetchNews wrote ${articles.length} articles for ${uid}`);
    return { count: articles.length };
  },
);

/**
 * 毎朝6時(JST)に GNews を取得し、news_pool を自動更新する。
 *
 * personalized_feed はユーザーごとに異なるため更新しない。
 * ユーザーが次回起動したときに fetchNews を手動トリガーするか、
 * 将来的に interest_profile を元に個別配信するパイプラインで対応する。
 */
export const refreshNewsPool = onSchedule(
  {
    schedule: "0 6 * * *",
    timeZone: "Asia/Tokyo",
    secrets: [GNEWS_API_KEY],
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async () => {
    const params = new URLSearchParams({
      lang: "ja",
      country: "jp",
      max: "10",
      apikey: GNEWS_API_KEY.value(),
    });
    const endpoint = `https://gnews.io/api/v4/top-headlines?${params.toString()}`;

    let data: GNewsResponse;
    try {
      const res = await fetch(endpoint);
      if (!res.ok) {
        logger.error("GNews request failed", {
          status: res.status,
          body: await res.text(),
        });
        return;
      }
      data = (await res.json()) as GNewsResponse;
    } catch (err) {
      logger.error("GNews fetch threw", err);
      return;
    }

    const articles = data.articles ?? [];
    if (articles.length === 0) {
      logger.info("refreshNewsPool: no articles returned");
      return;
    }

    const converted = await Promise.all(articles.map(toChildFriendly));

    const db = getFirestore();
    const batch = db.batch();
    articles.forEach((a, i) => {
      const id = newsIdFromUrl(a.url);
      const cf = converted[i];
      batch.set(db.collection("news_pool").doc(id), {
        original_title: a.title,
        published_at: Timestamp.fromDate(new Date(a.publishedAt)),
        parent_summary: cf.parentSummary,
        child_body_with_ruby: cf.childBodyWithRuby,
      });
    });

    await batch.commit();
    logger.info(`refreshNewsPool wrote ${articles.length} articles to news_pool`);
  },
);
