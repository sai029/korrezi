import { createHash } from "node:crypto";

import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import {
  VertexAI,
  SchemaType,
  HarmCategory,
  HarmBlockThreshold,
} from "@google-cloud/vertexai";

initializeApp();

// Firestore と同じ東京リージョンで動かす。
setGlobalOptions({ region: "asia-northeast1" });

// GNews.io の API キー。`firebase functions:secrets:set GNEWS_API_KEY` で登録する。
const GNEWS_API_KEY = defineSecret("GNEWS_API_KEY");

// Vertex AI（Gemini）の設定。認証は関数の実行サービスアカウント（ADC）を使うため
// API キーは不要。モデルが広く利用可能な us-central1 を既定にする。
const VERTEX_LOCATION = "us-central1";
const GEMINI_MODEL = "gemini-2.5-flash";

// quality_review マップの構造バージョン。後で項目を変えたら上げる。
const QUALITY_SCHEMA_VERSION = 1;

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

/**
 * 採点ゲートの結果。詳細な方針は docs/CONTENT_QUALITY_GATE.md を参照。
 *
 * - safety.passed=false の記事は除外され news_pool に載らない（④即除外）。
 * - 品質3軸スコアは「記録のみ」。閾値が固まるまで除外には使わない（①②③）。
 * - scores の各値は 1〜5。判定不能のときは null（特に thinkingHook）。
 */
interface QualityReview {
  verdict: "approved";
  safety: { passed: boolean; flagged: string[] };
  scores: {
    educationalValue: number | null;
    thinkingHook: number | null;
    reliability: number | null;
  };
  reason: string;
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

/** GNews 記事を採点・変換用の入力テキストへ整える（両処理で共通）。 */
function articleSource(a: GNewsArticle): string {
  // GNews 無料プランは content が冒頭のみ（途中で切れる）。
  // description は完結した概要なので、こちらを主要な情報源として優先する。
  return [
    `タイトル: ${a.title}`,
    `概要（完全）: ${a.description ?? ""}`,
    `本文（途中で切れている可能性あり）: ${a.content ?? ""}`,
  ].join("\n");
}

/** Gemini 変換に失敗したときの素朴なフォールバック（生記事のまま）。 */
function rawFallback(a: GNewsArticle): ChildFriendly {
  return {
    displayTitle: a.title,
    displayTagline: toTagline(a.description),
    childBodyWithRuby: a.description ?? a.content ?? "",
    parentSummary: a.description ?? "",
  };
}

// Vertex AI クライアントは関数インスタンス内で使い回す（変換用・採点用で別設定）。
let cachedVertex: VertexAI | null = null;
function getVertex(): VertexAI {
  if (!cachedVertex) {
    cachedVertex = new VertexAI({
      project: process.env.GCLOUD_PROJECT,
      location: VERTEX_LOCATION,
    });
  }
  return cachedVertex;
}

// 子ども向け変換は創作要素があるため temperature 0.7。
let cachedTransformModel: ReturnType<VertexAI["getGenerativeModel"]> | null =
  null;
function getTransformModel() {
  if (cachedTransformModel) return cachedTransformModel;
  cachedTransformModel = getVertex().getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: {
      temperature: 0.7,
      responseMimeType: "application/json",
    },
  });
  return cachedTransformModel;
}

// 子ども向けニュースなので暴力・性的・差別・危険表現は厳しめ（低レベル以上をブロック）。
const CHILD_SAFETY_SETTINGS = [
  HarmCategory.HARM_CATEGORY_HARASSMENT,
  HarmCategory.HARM_CATEGORY_HATE_SPEECH,
  HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
  HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
].map((category) => ({
  category,
  threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
}));

// 採点（LLM-as-a-Judge）はブレてはいけないので temperature 0 ＋ 構造化出力で固定。
let cachedJudgeModel: ReturnType<VertexAI["getGenerativeModel"]> | null = null;
function getJudgeModel() {
  if (cachedJudgeModel) return cachedJudgeModel;
  cachedJudgeModel = getVertex().getGenerativeModel({
    model: GEMINI_MODEL,
    safetySettings: CHILD_SAFETY_SETTINGS,
    generationConfig: {
      temperature: 0,
      responseMimeType: "application/json",
      responseSchema: {
        type: SchemaType.OBJECT,
        properties: {
          safe: { type: SchemaType.BOOLEAN },
          safety_flags: {
            type: SchemaType.ARRAY,
            items: { type: SchemaType.STRING },
          },
          educational_value: { type: SchemaType.INTEGER },
          thinking_hook: { type: SchemaType.INTEGER },
          reliability: { type: SchemaType.INTEGER },
          reason: { type: SchemaType.STRING },
        },
        required: [
          "safe",
          "safety_flags",
          "educational_value",
          "thinking_hook",
          "reliability",
          "reason",
        ],
      },
    },
  });
  return cachedJudgeModel;
}

/** 1〜5 の整数へ正規化。範囲外・非数・0（判定不能）は null。 */
function clampScore(v: unknown): number | null {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return null;
  const i = Math.round(n);
  return i >= 1 && i <= 5 ? i : null;
}

/**
 * 1記事を4軸で採点する（docs/CONTENT_QUALITY_GATE.md）。
 *
 * - ④安全性は safe=false なら即除外対象。
 * - ①②③は 1〜5 のスコア（②は短文で判定不能なら 0=null を許容）。
 *
 * 採点に失敗した（＝安全性を確認できない）場合は、子ども向けアプリの安全側に倒して
 * **除外**する（fail-closed）。Gemini 障害時はフィードが空になりうるが、未検証の記事を
 * 子どもに見せるよりは安全と判断する。
 */
async function scoreArticle(a: GNewsArticle): Promise<QualityReview | null> {
  const prompt = [
    "あなたは子ども向けニュースアプリの編集審査AIです。次の記事を4つの軸で評価し、",
    "指定のJSONだけを返してください（説明文は付けない）。",
    "",
    "① educational_value（教育的価値・テーマ適正）: 1〜5。",
    "  高=SDGs/科学/技術/国際情勢/環境/経済の仕組み/文化・歴史/社会課題の解決事例など、",
    "  子どもの視野を広げ学びに繋がるテーマ。",
    "  低=芸能スキャンダル/ゴシップ/凄惨な事件事故/単なる流行紹介/政治的プロパガンダ。",
    "② thinking_hook（思考のフック）: 1〜5。背景(なぜ起きたか)や影響(これからどうなるか)が",
    "  書かれているほど高い。『〇〇が起きました』だけの一行ニュースは低い。",
    "  概要が短すぎて判定できない場合のみ 0 を返す。",
    "③ reliability（信頼性・客観性）: 1〜5。事実と意見が区別され、煽り表現が無く、",
    "  複数視点に触れているほど高い。過激・感情的な煽りは低い。",
    "④ safety（安全面）: 残虐/性的/差別/自殺・自傷、または過度に恐怖を煽る描写が含まれるなら",
    "  safe=false。該当する種類を safety_flags に日本語で列挙（無ければ空配列）。",
    "",
    "reason には判定理由を日本語1文で簡潔に書く。",
    "",
    "記事:",
    articleSource(a),
  ].join("\n");

  try {
    const model = getJudgeModel();
    const result = await model.generateContent({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
    });
    const text =
      result.response.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    // Vertex が安全フィルタで応答自体をブロックした場合は text が空 → catch で除外。
    const parsed = JSON.parse(text) as Record<string, unknown>;

    const flagged = Array.isArray(parsed.safety_flags)
      ? parsed.safety_flags.filter((x): x is string => typeof x === "string")
      : [];
    const passed = parsed.safe === true && flagged.length === 0;

    return {
      verdict: "approved",
      safety: { passed, flagged },
      scores: {
        educationalValue: clampScore(parsed.educational_value),
        thinkingHook: clampScore(parsed.thinking_hook),
        reliability: clampScore(parsed.reliability),
      },
      reason: typeof parsed.reason === "string" ? parsed.reason : "",
    };
  } catch (err) {
    logger.warn("scoreArticle failed; dropping article (fail-closed)", {
      url: a.url,
      err: `${err}`,
    });
    return null;
  }
}

/**
 * 1記事を子ども向け（やさしい言葉＋ルビ）に変換する。
 *
 * ルビは `〔漢字｜よみ〕` markup（アプリの FuriganaText が解釈する形式）で埋め込む。
 * 失敗時は生記事へフォールバックして処理を止めない。
 */
async function toChildFriendly(a: GNewsArticle): Promise<ChildFriendly> {
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
    articleSource(a),
  ].join("\n");

  try {
    const model = getTransformModel();
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

/** GNews top-headlines のエンドポイント URL を組み立てる。 */
function gnewsEndpoint(): string {
  const params = new URLSearchParams({
    lang: "ja",
    country: "jp",
    max: "10",
    apikey: GNEWS_API_KEY.value(),
  });
  return `https://gnews.io/api/v4/top-headlines?${params.toString()}`;
}

/** GNews から日本語トップ記事を取得する。失敗時は例外を投げる。 */
async function fetchGNewsArticles(): Promise<GNewsArticle[]> {
  const res = await fetch(gnewsEndpoint());
  if (!res.ok) {
    const body = await res.text();
    logger.error("GNews request failed", { status: res.status, body });
    throw new Error(`GNews status ${res.status}`);
  }
  const data = (await res.json()) as GNewsResponse;
  return data.articles ?? [];
}

/**
 * 記事群を「採点ゲート → 合格分のみ子ども向け変換 → news_pool 書き込み」まで処理し、
 * 実際に書き込んだ件数を返す。fetchNews / refreshNewsPool の共通処理。
 *
 * ゲートは変換の前に置く（落とす記事に変換コストを払わない）。
 */
async function ingestArticles(articles: GNewsArticle[]): Promise<number> {
  // 1. 採点（並列）。安全性を確認できない記事は null。
  const reviews = await Promise.all(articles.map(scoreArticle));
  const scored = articles.map((a, i) => ({ article: a, review: reviews[i] }));

  // 2. 合格 / 除外に振り分け。④安全NG と採点失敗(null)を除外、品質3軸は記録のみ。
  const survivors = scored.filter(
    (x): x is { article: GNewsArticle; review: QualityReview } =>
      x.review !== null && x.review.safety.passed,
  );
  const rejected = scored.filter(
    (x) => x.review === null || !x.review.safety.passed,
  );

  if (rejected.length > 0) {
    logger.info(
      `quality gate dropped ${rejected.length}/${articles.length} articles`,
    );
  }

  // 3. 合格分のみ子ども向けに変換（並列）。
  const converted = await Promise.all(
    survivors.map((x) => toChildFriendly(x.article)),
  );

  // 4. WriteBatch で news_pool（合格）と rejected_articles（除外）へ書き込み。
  const db = getFirestore();
  const batch = db.batch();

  survivors.forEach(({ article: a, review }, i) => {
    const id = newsIdFromUrl(a.url);
    const cf = converted[i];

    // 画像があれば generated モードで NetworkImage 表示、無ければ text_overlay。
    const image = a.image ?? "";
    const thumbnailConfig = image
      ? { mode: "generated", base_asset: "", optional_generated_url: image }
      : { mode: "text_overlay", base_asset: "", optional_generated_url: "" };

    batch.set(db.collection("news_pool").doc(id), {
      original_title: a.title,
      published_at: Timestamp.fromDate(new Date(a.publishedAt)),
      parent_summary: cf.parentSummary,
      child_body_with_ruby: cf.childBodyWithRuby,
      display_title: cf.displayTitle,
      display_tagline: cf.displayTagline,
      thumbnail_config: thumbnailConfig,
      interest_context: a.source?.name ?? "ニュース",
      // 採点ゲートの結果。品質3軸は記録のみ（除外には未使用）。
      quality_review: {
        verdict: review.verdict,
        safety: review.safety,
        scores: review.scores,
        reason: review.reason,
        model: GEMINI_MODEL,
        schema_version: QUALITY_SCHEMA_VERSION,
        scored_at: Timestamp.now(),
      },
    });
  });

  // 除外記事は監査・閾値調整用に rejected_articles/{id} へ保存（同じ id で冪等）。
  // クライアントには公開しない（Admin SDK 書き込み・Firebase コンソールで確認する想定）。
  rejected.forEach(({ article: a, review }) => {
    const id = newsIdFromUrl(a.url);
    batch.set(db.collection("rejected_articles").doc(id), {
      original_title: a.title,
      url: a.url,
      interest_context: a.source?.name ?? "ニュース",
      published_at: Timestamp.fromDate(new Date(a.publishedAt)),
      // review===null は採点失敗(fail-closed/Vertexブロック)、それ以外は④安全NG。
      rejected_reason: review === null ? "scoring_failed" : "safety",
      safety_flags: review?.safety.flagged ?? [],
      scores: review?.scores ?? null,
      reason: review?.reason ?? "",
      model: GEMINI_MODEL,
      schema_version: QUALITY_SCHEMA_VERSION,
      rejected_at: Timestamp.now(),
    });
  });

  await batch.commit();
  return survivors.length;
}

/**
 * GNews から日本語トップ記事を取得し、採点ゲートを通過した記事を Gemini で
 * 子ども向けに変換して Firestore へ書き込む。
 *
 * - `/news_pool/{id}` … 全ユーザー共通の元記事（子ども向け本文＋親要約＋採点結果）
 */
export const fetchNews = onCall(
  { secrets: [GNEWS_API_KEY], timeoutSeconds: 300, memory: "512MiB" },
  async (request): Promise<{ count: number }> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "ログインが必要です。");
    }

    let articles: GNewsArticle[];
    try {
      articles = await fetchGNewsArticles();
    } catch (err) {
      logger.error("GNews fetch failed", err);
      throw new HttpsError("unavailable", "GNews への接続に失敗しました。");
    }

    if (articles.length === 0) {
      return { count: 0 };
    }

    const count = await ingestArticles(articles);
    logger.info(`fetchNews wrote ${count} articles for ${uid}`);
    return { count };
  },
);

/**
 * 毎朝6時(JST)に GNews を取得し、採点ゲートを通して news_pool を自動更新する。
 *
 * personalized_feed はユーザーごとに異なるため更新しない。
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
    let articles: GNewsArticle[];
    try {
      articles = await fetchGNewsArticles();
    } catch (err) {
      logger.error("GNews fetch failed", err);
      return;
    }

    if (articles.length === 0) {
      logger.info("refreshNewsPool: no articles returned");
      return;
    }

    const count = await ingestArticles(articles);
    logger.info(`refreshNewsPool wrote ${count} articles to news_pool`);
  },
);
