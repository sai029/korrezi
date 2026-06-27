import { createHash, randomUUID } from "node:crypto";

import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { setGlobalOptions } from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import { GoogleGenAI } from "@google/genai";

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
  childTitleWithRuby: string; // ルビ付きタイトル（子どもフィードで使用）
  displayTagline: string;
  childBodyWithRuby: string;
  parentSummary: string;
}

/** 記事 URL から安定した doc id を作る（再取得時は冪等に上書き）。 */
function newsIdFromUrl(url: string): string {
  const hash = createHash("sha1").update(url).digest("hex").slice(0, 16);
  return `news_${hash}`;
}

/**
 * ルビマークアップ 〔漢字｜よみ〕 から読み仮名部分を除去して表記文字だけを返す。
 * 文字数カウント前に適用し、ルビによる過剰カウントを防ぐ。
 */
function stripRuby(text: string): string {
  return text.replace(/〔([^｜]+)｜[^〕]+〕/g, "$1");
}

/**
 * 子ども向け本文（ルビ付き）から実際の読み文字数を算出する。
 * 空白・改行を除外した純粋な文字数を返す。
 */
function countCharsForReading(childBodyWithRuby: string): number {
  return stripRuby(childBodyWithRuby).replace(/\s+/g, "").length;
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
    childTitleWithRuby: a.title, // フォールバック時はルビなし
    displayTagline: toTagline(a.description),
    childBodyWithRuby: a.description ?? a.content ?? "",
    parentSummary: a.description ?? "",
  };
}

// Google Gen AI クライアントは関数インスタンス内で使い回す。
let cachedAI: GoogleGenAI | null = null;
function getGenAI(): GoogleGenAI {
  if (cachedAI) return cachedAI;
  cachedAI = new GoogleGenAI({
    vertexai: true,
    project: process.env.GCLOUD_PROJECT,
    location: VERTEX_LOCATION,
  });
  return cachedAI;
}

/**
 * 1記事を子ども向け（やさしい言葉＋ルビ）に変換する。
 *
 * ルビは `〔漢字｜よみ〕` markup（アプリの FuriganaText が解釈する形式）で埋め込む。
 * 失敗時は生記事へフォールバックして処理を止めない。
 */
async function toChildFriendly(a: GNewsArticle): Promise<ChildFriendly> {
  // GNews 無料プランは content が冒頭のみ（途中で切れる）。
  // description は完結した概要なので、こちらを主要な情報源として優先する。
  const source = [
    `タイトル: ${a.title}`,
    `概要（完全）: ${a.description ?? ""}`,
    `本文（途中で切れている可能性あり）: ${a.content ?? ""}`,
  ].join("\n");

  const prompt = [
    "あなたは小学生向けニュースの編集者です。次のニュース記事を、6〜10歳の子どもが",
    "読めるように、やさしい日本語で書き直してください。難しい言葉は避け、",
    "短い文にします。事実は変えないでください。",
    "",
    "出力は必ず次の5キーを持つJSONだけにしてください（前後に説明文を付けない）:",
    '- "display_title": 子ども向けの短いタイトル（20文字以内・ルビなし・記号や煽りは不要）',
    '- "child_title_with_ruby": display_titleと同じ内容で、小学校で習わない漢字に',
    "  〔漢字｜よみ〕 の形式でルビを付けたもの（例: 〔環境｜かんきょう〕）",
    '- "display_tagline": 興味を引く一言（30文字以内）',
    '- "child_body_with_ruby": 本文（2〜4文）。小学校で習わない漢字には',
    "  〔漢字｜よみ〕 の形式でルビを付ける。ひらがなだけにしない。",
    '- "parent_summary": 保護者向けの箇条書き要約。各行を「・」で始め、2〜3項目。',
    "",
    "記事:",
    source,
  ].join("\n");

  try {
    const result = await getGenAI().models.generateContent({
      model: GEMINI_MODEL,
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      config: { temperature: 0.7, responseMimeType: "application/json" },
    });
    const text = result.text ?? "";
    const parsed = JSON.parse(text) as Record<string, unknown>;

    const pick = (k: string, fallback: string): string => {
      const v = parsed[k];
      return typeof v === "string" && v.trim().length > 0 ? v.trim() : fallback;
    };
    const fb = rawFallback(a);
    return {
      displayTitle: pick("display_title", fb.displayTitle),
      childTitleWithRuby: pick("child_title_with_ruby", fb.childTitleWithRuby),
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

      // GNews の画像URL は CORS で弾かれるため使わない。
      // 常に text_overlay で保存し、personalizeArticles で Imagen 3 が生成する。
      const thumbnailConfig = { mode: "text_overlay", base_asset: "", optional_generated_url: "" };

      // /news_pool/{id} … 全ユーザー共通の表示データ。
      // personalized_feed は個人テレメトリ（recordView）のみに使い、
      // Cloud Functions からは書き込まない。
      batch.set(db.collection("news_pool").doc(id), {
        original_title: a.title,
        published_at: Timestamp.fromDate(new Date(a.publishedAt)),
        parent_summary: cf.parentSummary,
        child_body_with_ruby: cf.childBodyWithRuby,
        display_title: cf.displayTitle,
        child_title_with_ruby: cf.childTitleWithRuby,
        display_tagline: cf.displayTagline,
        thumbnail_config: thumbnailConfig,
        interest_context: a.source?.name ?? "ニュース",
        // DISA Step 1 用: ルビ除去後の純粋な読み文字数
        char_count: countCharsForReading(cf.childBodyWithRuby),
      });
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
      // GNews の画像URL は CORS で弾かれるため使わない。
      // 常に text_overlay で保存し、personalizeArticles で Imagen 3 が生成する。
      const thumbnailConfig = { mode: "text_overlay", base_asset: "", optional_generated_url: "" };
      batch.set(db.collection("news_pool").doc(id), {
        original_title: a.title,
        published_at: Timestamp.fromDate(new Date(a.publishedAt)),
        parent_summary: cf.parentSummary,
        child_body_with_ruby: cf.childBodyWithRuby,
        display_title: cf.displayTitle,
        child_title_with_ruby: cf.childTitleWithRuby,
        display_tagline: cf.displayTagline,
        thumbnail_config: thumbnailConfig,
        interest_context: a.source?.name ?? "ニュース",
        // DISA Step 1 用: ルビ除去後の純粋な読み文字数
        char_count: countCharsForReading(cf.childBodyWithRuby),
      });
    });

    await batch.commit();
    logger.info(`refreshNewsPool wrote ${articles.length} articles to news_pool`);
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// DISA (Developmental Interest Scoring Algorithm)
// 論文: Hidi & Renninger (2006), Settles & Meeder / Duolingo (2016),
//       Ardagelou & Arampatzis (2017), Wu et al. (2021)
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * 日本語小学生の黙読速度（字/分）。
 * 実証研究の小学3年生平均値 ~260字/分 を採用（Hashemi et al. 2023 の日本語換算）。
 */
const CHILD_READING_CHARS_PER_MIN = 260;

/**
 * 文字数が不明なときのフォールバック想定読了時間（秒）。
 * 260字/分 × 200字 ≈ 46秒。char_count が取得できた場合はこの値を使わない。
 */
const T_EXP_FALLBACK_SEC = 45;

/**
 * 記事の文字数から想定読了時間（秒）を計算する。
 * charCount が 0 以下のときはフォールバック値を返す。
 */
function calcExpectedReadTimeSec(charCount: number): number {
  if (charCount <= 0) return T_EXP_FALLBACK_SEC;
  return (charCount / CHILD_READING_CHARS_PER_MIN) * 60;
}

/**
 * DISA Step 1: 閲覧秒数から実質エンゲージメント値 E(i) ∈ [0.0, 1.0] を算出する。
 *
 * t_norm = viewSeconds / T_exp（想定読了時間比）
 * - t_norm < 0.2  (< T_exp×0.2): クリックベイト・即離脱 → E = 0
 * - t_norm ∈ [0.2, 1.5]:         対数重み付けでスムーズ増加（外れ値耐性）
 * - t_norm > 1.5  (> T_exp×1.5): 放置・読解困難の可能性 → 上限 0.3 でキャップ
 *
 * charCount を渡すと記事ごとの動的 T_exp を使用する（精度向上）。
 * 省略時は T_EXP_FALLBACK_SEC（45秒）で近似する。
 *
 * 参照: Yi et al. (2014) RecSys / Wu et al. (2021) Dwell time debiasing
 */
function calcEngagementValue(
  viewDurationSeconds: number,
  charCount = 0
): number {
  const tExp = calcExpectedReadTimeSec(charCount);
  const t_norm = viewDurationSeconds / tExp;
  if (t_norm < 0.2) return 0;
  if (t_norm > 1.5) return 0.3; // idle / struggle — 弱い正シグナルとして保持
  // log(1 + 1.2) ≈ 0.788 を分母にして t_norm = 1.2 付近で E ≈ 1.0 に飽和させる
  return Math.min(1.0, Math.log(1 + t_norm) / Math.log(1 + 1.2));
}

/**
 * DISA Step 2: genuine engagement 回数 N_k から Hidi-Renninger 4段階フェーズを推定する。
 *
 * Phase 1 (TSI: Triggered Situational Interest):  N < 3
 * Phase 2 (MSI: Maintained Situational Interest): 3 ≤ N < 7
 * Phase 3 (EII: Emerging Individual Interest):    N ≥ 7
 *
 * 参照: Hidi & Renninger (2006) / Rotgans & Schmidt (2017)
 */
function getInterestPhase(engagementCount: number): 1 | 2 | 3 {
  if (engagementCount < 3) return 1;
  if (engagementCount < 7) return 2;
  return 3;
}

/**
 * DISA Step 3: フェーズに応じた動的半減期（日数）を返す。
 *
 * フェーズが上がるほど興味が定着し、減衰が緩やかになる。
 * Phase 1 → 1日 / Phase 2 → 3日 / Phase 3 → 14日
 *
 * 参照: Ardagelou & Arampatzis (2017) 半減期150日の知見 + テーマ2推奨値を子ども向けに短縮
 */
function getHalfLifeDays(phase: 1 | 2 | 3): number {
  if (phase === 1) return 1;
  if (phase === 2) return 3;
  return 14;
}

/**
 * DISA Step 4: 前回スコアに指数減衰を適用し、新しいエンゲージメントを加算する。
 *
 * S(t_new) = S(t_prev) × e^(−λ × Δdays) + α × E(i)
 * λ = ln(2) / t½  （半減期から減衰率を計算）
 * α = 10  （1回の良質な読解で加算されるベーススコア）
 *
 * 参照: Duolingo HLR (Settles & Meeder, 2016) の動的半減期アプローチを応用
 */
function calcDISAScore(
  prevScore: number,
  daysDelta: number,
  phase: 1 | 2 | 3,
  engagementValue: number,
  alpha = 10
): number {
  const lambda = Math.LN2 / getHalfLifeDays(phase);
  const decayed = prevScore * Math.exp(-lambda * daysDelta);
  return decayed + alpha * engagementValue;
}

/**
 * 保存済みの興味スコアに、最終更新からの経過時間による減衰を適用して返す（読み取り時補正）。
 *
 * personalizeArticles で推薦スコアを計算する際に使用する。
 * 実際の Firestore 書き込みは行わない（read-only 補正）。
 */
function applyDecayForRead(
  score: number,
  lastUpdatedAt: Timestamp | undefined,
  phase: 1 | 2 | 3
): number {
  if (!lastUpdatedAt) return score;
  const daysDelta =
    (Timestamp.now().toDate().getTime() - lastUpdatedAt.toDate().getTime()) /
    86400000;
  const lambda = Math.LN2 / getHalfLifeDays(phase);
  return score * Math.exp(-lambda * daysDelta);
}

// ═══════════════════════════════════════════════════════════════════════════════
// AI エージェント群
// ═══════════════════════════════════════════════════════════════════════════════

// ─── 興味検知 AI + パーソナライズ AI ─────────────────────────────────────────

/** personalized_feed に書き込む1記事分のレコード */
interface ThumbnailConfigData {
  mode: "text_overlay" | "generated";
  base_asset: string;
  optional_generated_url: string;
}

interface PersonalizedRecord {
  news_id: string;
  interest_context: string;
  display_title: string;
  display_tagline: string;
  thumbnail_config: ThumbnailConfigData;
  interest_score: number;
  personalized_at: Timestamp;
}

/**
 * 1記事を子どもの興味プロファイルに合わせてパーソナライズする（興味検知 + 書き換え）。
 *
 * Gemini に interest_score（0-100）・rewritten_title・rewritten_tagline を要求する。
 * スコアが低い記事ほど積極的に書き換え、子どもが興味を持てる表現へ調整する。
 */
async function personalizeOneArticle(
  newsId: string,
  article: FirebaseFirestore.DocumentData,
  topInterestsSummary: string
): Promise<PersonalizedRecord> {
  const originalTitle = article.display_title || article.original_title || "";
  const originalTagline = article.display_tagline || "";
  const category = article.interest_context || "";
  const bodySnippet = (article.child_body_with_ruby || "").slice(0, 200);

  const prompt = [
    "あなたは子ども向けニュースをパーソナライズするAIです。",
    "",
    "【子どもの上位興味（カテゴリ: スコア）】",
    topInterestsSummary || "（まだ興味が記録されていません）",
    "",
    "【記事情報】",
    `カテゴリ: ${category}`,
    `タイトル: ${originalTitle}`,
    `タグライン: ${originalTagline}`,
    `本文抜粋: ${bodySnippet}`,
    "",
    "この記事を子どもの興味に合わせてください。",
    "以下のJSONのみを出力してください（前後に説明文は付けない）:",
    "{",
    '  "interest_score": 0〜100の整数（子どもが興味を持つ確率。上位興味に近いほど高い）,',
    '  "rewritten_title": 子どもの興味に合わせたタイトル（元の意味を保ちつつ20文字以内）,',
    '  "rewritten_tagline": 興味を引くタグライン（30文字以内）',
    "}",
  ].join("\n");

  try {
    const result = await getGenAI().models.generateContent({
      model: GEMINI_MODEL,
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      config: { temperature: 0.7, responseMimeType: "application/json" },
    });
    const raw = result.text ?? "{}";
    const parsed = JSON.parse(raw) as {
      interest_score?: number;
      rewritten_title?: string;
      rewritten_tagline?: string;
    };

    const interestScore =
      typeof parsed.interest_score === "number"
        ? Math.max(0, Math.min(100, Math.round(parsed.interest_score)))
        : 50;

    return {
      news_id: newsId,
      interest_context: category,
      display_title: parsed.rewritten_title?.trim() || originalTitle,
      display_tagline: parsed.rewritten_tagline?.trim() || originalTagline,
      thumbnail_config: article.thumbnail_config ?? {
        mode: "text_overlay",
        base_asset: "",
        optional_generated_url: "",
      },
      interest_score: interestScore,
      personalized_at: Timestamp.now(),
    };
  } catch (err) {
    logger.warn("personalizeOneArticle failed; using original", {
      newsId,
      err: `${err}`,
    });
    return {
      news_id: newsId,
      interest_context: category,
      display_title: originalTitle,
      display_tagline: originalTagline,
      thumbnail_config: article.thumbnail_config ?? {
        mode: "text_overlay",
        base_asset: "",
        optional_generated_url: "",
      },
      interest_score: 50,
      personalized_at: Timestamp.now(),
    };
  }
}

/**
 * パーソナライズ AI + 興味検知 AI パイプライン（Flutter から呼び出す）。
 *
 * 1. ユーザーの interest_profile を取得して上位興味を整理する
 * 2. news_pool から最新記事を取得する
 * 3. Gemini で各記事の興味スコア計算とタイトル/タグラインを書き換える（並列）
 * 4. 結果を personalized_feed に保存（telemetry フィールドは merge: true で保持）
 */
export const personalizeArticles = onCall(
  { timeoutSeconds: 300, memory: "512MiB" },
  async (request): Promise<{ count: number }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "ログインが必要です。");

    const db = getFirestore();

    // 興味プロファイル取得（存在しなければ空のまま進む）
    const profileSnap = await db
      .collection("users")
      .doc(uid)
      .collection("interest_profile")
      .doc("current")
      .get();
    const profileData = profileSnap.data() ?? {};
    const interests = (profileData.current_interests ?? {}) as Record<string, number>;
    const genuineEngagementCounts = (profileData.genuine_engagement_counts ?? {}) as Record<string, number>;
    const lastScoreUpdatedAt = (profileData.last_score_updated_at ?? {}) as Record<string, Timestamp>;

    // 読み取り時に DISA 減衰を適用して現時点の実効スコアを算出する
    const decayedInterests: Record<string, number> = {};
    for (const [cat, score] of Object.entries(interests)) {
      const phase = getInterestPhase(genuineEngagementCounts[cat] ?? 0);
      decayedInterests[cat] = applyDecayForRead(score, lastScoreUpdatedAt[cat], phase);
    }

    const topInterestsSummary = Object.entries(decayedInterests)
      .filter(([, v]) => v > 0.5) // 減衰でほぼゼロになったカテゴリは除外
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([k, v]) => `${k}: ${v.toFixed(1)}点`)
      .join(", ");

    // news_pool から最新20件を取得
    const poolSnap = await db
      .collection("news_pool")
      .orderBy("published_at", "desc")
      .limit(20)
      .get();

    if (poolSnap.empty) return { count: 0 };

    // 全記事を並列でパーソナライズ（失敗分は settled で拾う）
    const settled = await Promise.allSettled(
      poolSnap.docs.map((doc) =>
        personalizeOneArticle(doc.id, doc.data(), topInterestsSummary)
      )
    );

    // telemetry（is_viewed / view_duration_seconds）は上書きしないよう merge: true
    const batch = db.batch();
    let count = 0;
    for (const r of settled) {
      if (r.status !== "fulfilled") continue;
      const item = r.value;
      const ref = db
        .collection("users")
        .doc(uid)
        .collection("personalized_feed")
        .doc(item.news_id);
      batch.set(
        ref,
        {
          news_id: item.news_id,
          interest_context: item.interest_context,
          display_title: item.display_title,
          display_tagline: item.display_tagline,
          thumbnail_config: item.thumbnail_config,
          interest_score: item.interest_score,
          personalized_at: item.personalized_at,
        },
        { merge: true }
      );
      count++;
    }
    await batch.commit();

    // ─── バックグラウンドサムネ生成 ────────────────────────────────────────────
    // Imagen 3 でサムネを生成する対象を選定。
    // Storage URL（storage.googleapis.com）が既にある記事はスキップ（冪等）。
    // GNews 由来のURLが入っている記事は CORS で表示できないため再生成対象にする。
    const needsThumbnail = (config: ThumbnailConfigData): boolean => {
      if (config.mode !== "generated") return true;
      // firebasestorage.googleapis.com/v0/... = Imagen 生成済み（CORS OK）→ スキップ
      // storage.googleapis.com/... = 旧 GCS 直 URL または GNews URL（CORS NG）→ 再生成
      return !config.optional_generated_url.startsWith("https://firebasestorage.googleapis.com");
    };
    const thumbTargets = settled
      .filter(
        (r): r is PromiseFulfilledResult<PersonalizedRecord> =>
          r.status === "fulfilled" && needsThumbnail(r.value.thumbnail_config)
      )
      .map((r) => r.value);

    if (thumbTargets.length > 0) {
      try {
        const project = process.env.GCLOUD_PROJECT ?? "";
        const tokenRes = await fetch(
          "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token",
          { headers: { "Metadata-Flavor": "Google" } }
        );
        const { access_token: accessToken } = (await tokenRes.json()) as {
          access_token: string;
        };

        const thumbSettled = await Promise.allSettled(
          thumbTargets.map(async (item) => {
            const imageUrl = await generateOneThumbnail(
              item.news_id,
              item.display_title,
              item.display_tagline,
              item.interest_context,
              accessToken,
              project
            );
            return { news_id: item.news_id, imageUrl };
          })
        );

        const thumbBatch = db.batch();
        let thumbCount = 0;
        for (const r of thumbSettled) {
          if (r.status !== "fulfilled") {
            logger.warn("thumbnail generation failed", { reason: `${r.reason}` });
            continue;
          }
          const { news_id, imageUrl } = r.value;
          const thumbConfig: ThumbnailConfigData = {
            mode: "generated",
            base_asset: "",
            optional_generated_url: imageUrl,
          };
          // news_pool 更新 → 次回 personalizeArticles で text_overlay と判定されなくなる
          thumbBatch.update(db.collection("news_pool").doc(news_id), {
            thumbnail_config: thumbConfig,
          });
          // personalized_feed 更新
          thumbBatch.set(
            db.collection("users").doc(uid).collection("personalized_feed").doc(news_id),
            { thumbnail_config: thumbConfig },
            { merge: true }
          );
          thumbCount++;
        }
        if (thumbCount > 0) await thumbBatch.commit();
        logger.info(`personalizeArticles: ${thumbCount} thumbnails generated for uid=${uid}`);
      } catch (err) {
        // サムネ失敗はパーソナライズ全体の失敗にしない
        logger.error("thumbnail batch failed", { err: `${err}` });
      }
    }

    logger.info(`personalizeArticles: ${count} articles for uid=${uid}`);
    return { count };
  }
);

// ─── サムネ生成 AI ────────────────────────────────────────────────────────────

/**
 * Imagen 3 で1枚サムネを生成し Storage に保存する内部ヘルパー。
 *
 * @param newsId      Firestore ドキュメント ID（Storage パスに使用）
 * @param title       表示タイトル（プロンプトに使用）
 * @param tagline     タグライン（プロンプトに使用）
 * @param category    カテゴリ/ジャンル（プロンプトに使用）
 * @param accessToken メタデータサーバーから取得した Bearer トークン
 * @param project     GCP プロジェクト ID
 * @returns           Storage 公開 URL
 */
async function generateOneThumbnail(
  newsId: string,
  title: string,
  tagline: string,
  category: string,
  accessToken: string,
  project: string
): Promise<string> {
  // Gemini で記事内容から Imagen 向け英語ビジュアルプロンプトを生成する。
  // Imagen 3 は英語プロンプトの方が品質が高く、日本語ソース名（"NHK ニュース" 等）を
  // そのままテーマに使うと記事と無関係な画像が生成されるため、Gemini が意味を補完する。
  let promptText: string;
  try {
    const pResult = await getGenAI().models.generateContent({
      model: GEMINI_MODEL,
      contents: [{
        role: "user",
        parts: [{ text: [
          "Write a short English prompt for an AI image generator to create a children's news thumbnail.",
          `Article title: ${title}`,
          `Article summary: ${tagline}`,
          "Rules: describe ONE specific scene that represents the article visually.",
          "Style must be: bright colorful cartoon illustration for kids aged 6-10, cheerful, no text, no letters, no words in the image.",
          "Output only the image prompt (max 60 words). No explanation, no quotes.",
        ].join("\n") }],
      }],
      config: { temperature: 0.8 },
    });
    promptText = (pResult.text ?? "").trim();
    if (!promptText) throw new Error("empty");
  } catch {
    promptText = `Children's news illustration about: ${title}. ${tagline}. Bright colorful cartoon art for kids, no text, 16:9.`;
  }

  const endpoint = [
    "https://us-central1-aiplatform.googleapis.com/v1",
    `/projects/${project}/locations/us-central1`,
    "/publishers/google/models/imagen-3.0-fast-generate-001:predict",
  ].join("");

  const imgRes = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      instances: [{ prompt: promptText }],
      parameters: { sampleCount: 1, aspectRatio: "16:9" },
    }),
  });

  if (!imgRes.ok) {
    const body = await imgRes.text();
    throw new Error(`Imagen API ${imgRes.status}: ${body}`);
  }

  const imgData = (await imgRes.json()) as {
    predictions: Array<{ bytesBase64Encoded: string }>;
  };
  const buffer = Buffer.from(
    imgData.predictions[0].bytesBase64Encoded,
    "base64"
  );

  const bucket = getStorage().bucket();
  const file = bucket.file(`thumbnails/${newsId}.jpg`);
  // firebaseStorageDownloadTokens を埋め込むと Storage セキュリティルールに関係なく
  // 認証なしで読み込める安定した Download URL が発行される（有効期限なし）。
  const downloadToken = randomUUID();
  await file.save(buffer, {
    contentType: "image/jpeg",
    metadata: {
      cacheControl: "public, max-age=31536000",
      metadata: { firebaseStorageDownloadTokens: downloadToken },
    },
  });

  const encodedPath = encodeURIComponent(`thumbnails/${newsId}.jpg`);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`;
}

/**
 * Imagen 3 でサムネを生成し Firebase Storage にアップロードする。
 *
 * 生成した URL を news_pool と呼び出しユーザーの personalized_feed に反映する。
 * 生成コストを抑えるため imagen-3.0-fast-generate-001 を使用する。
 */
export const generateThumbnail = onCall(
  { timeoutSeconds: 120, memory: "1GiB" },
  async (request): Promise<{ imageUrl: string }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "ログインが必要です。");

    const { newsId, title, tagline, category } = request.data as {
      newsId: string;
      title: string;
      tagline: string;
      category: string;
    };
    if (!newsId || !title) {
      throw new HttpsError("invalid-argument", "newsId と title は必須です。");
    }

    const project = process.env.GCLOUD_PROJECT ?? "";

    let imageUrl: string;
    try {
      const tokenRes = await fetch(
        "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token",
        { headers: { "Metadata-Flavor": "Google" } }
      );
      const { access_token: accessToken } = (await tokenRes.json()) as {
        access_token: string;
      };
      imageUrl = await generateOneThumbnail(
        newsId, title, tagline, category, accessToken, project
      );
    } catch (err) {
      logger.error("Imagen generation failed", { newsId, err: `${err}` });
      throw new HttpsError("internal", "サムネイル生成に失敗しました。");
    }

    // news_pool と呼び出しユーザーの personalized_feed を更新
    const db = getFirestore();
    const thumbConfig = {
      mode: "generated",
      base_asset: "",
      optional_generated_url: imageUrl,
    };
    const updateBatch = db.batch();
    updateBatch.update(db.collection("news_pool").doc(newsId), {
      thumbnail_config: thumbConfig,
    });
    updateBatch.set(
      db
        .collection("users")
        .doc(uid)
        .collection("personalized_feed")
        .doc(newsId),
      { thumbnail_config: thumbConfig },
      { merge: true }
    );
    await updateBatch.commit();

    logger.info(`generateThumbnail: ${newsId} → ${imageUrl}`);
    return { imageUrl };
  }
);

// ─── 興味検知 AI 自己学習ループ ───────────────────────────────────────────────

/**
 * 興味検知 AI 自己学習ループ — DISA (Developmental Interest Scoring Algorithm) 実装。
 *
 * スコアの数値計算は論文ベースの決定論的な式で行い、
 * Gemini は agent_notes（定性的な興味傾向メモ）の更新のみに使用する。
 *
 * 更新フィールド:
 *   current_interests.{category}           : DISA スコア（指数減衰 + α×E(i) 加算）
 *   genuine_engagement_counts.{category}   : genuine engagement 回数 N_k（フェーズ判定用）
 *   last_score_updated_at.{category}       : 最終スコア更新日時（次回減衰計算用）
 *   ai_agent_metadata.agent_notes          : Gemini が更新する定性メモ
 */
export const updateInterestModel = onCall(
  { timeoutSeconds: 60, memory: "256MiB" },
  async (request): Promise<void> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "ログインが必要です。");

    const { newsId, viewDurationSeconds } = request.data as {
      newsId: string;
      viewDurationSeconds: number;
    };
    if (!newsId || typeof viewDurationSeconds !== "number") {
      throw new HttpsError(
        "invalid-argument",
        "newsId と viewDurationSeconds は必須です。"
      );
    }

    // ── 早期バウンス除外（Firestore 読み取り前の軽量チェック）─────────────────
    // T_EXP_FALLBACK_SEC × 0.2 = 9秒未満は記事の長さに関わらず確実にバウンス。
    if (viewDurationSeconds < T_EXP_FALLBACK_SEC * 0.2) {
      logger.info(`updateInterestModel: early bounce (${viewDurationSeconds}s), skip`, { newsId });
      return;
    }

    const db = getFirestore();
    const profileRef = db
      .collection("users")
      .doc(uid)
      .collection("interest_profile")
      .doc("current");

    const [articleSnap, profileSnap] = await Promise.all([
      db.collection("news_pool").doc(newsId).get(),
      profileRef.get(),
    ]);

    if (!articleSnap.exists) {
      logger.warn("updateInterestModel: article not found", { newsId });
      return;
    }

    const article = articleSnap.data()!;
    const category = article.interest_context as string;
    // ── DISA Step 1: 記事の実文字数で T_exp を動的計算して E(i) を算出 ──────
    const charCount = (article.char_count as number) ?? 0;
    const E = calcEngagementValue(viewDurationSeconds, charCount);
    if (E === 0) {
      // フォールバック T_exp では通過したが実際の記事長では早すぎた場合
      logger.info(`updateInterestModel: bounce after char_count check (${viewDurationSeconds}s, chars=${charCount}), skip`, { newsId });
      return;
    }

    const profileData = profileSnap.data() ?? {};

    // ── DISA Step 2: フェーズ推定 ─────────────────────────────────────────────
    const prevEngagementCount =
      (profileData.genuine_engagement_counts?.[category] as number) ?? 0;
    // genuine engagement（E > 0.5 = 適切な速度での読解）のときだけカウントを増やす
    const newEngagementCount = prevEngagementCount + (E > 0.5 ? 1 : 0);
    const phase = getInterestPhase(newEngagementCount);

    // ── DISA Step 3 & 4: 減衰 → 加算 ────────────────────────────────────────
    const prevScore =
      (profileData.current_interests?.[category] as number) ?? 0;
    const lastUpdatedAt =
      profileData.last_score_updated_at?.[category] as Timestamp | undefined;
    const daysDelta = lastUpdatedAt
      ? (Timestamp.now().toDate().getTime() - lastUpdatedAt.toDate().getTime()) /
        86400000
      : 0;

    const newScore = calcDISAScore(prevScore, daysDelta, phase, E);

    // ── Firestore 更新（スコア・カウント・タイムスタンプ）────────────────────
    const updates: Record<string, unknown> = {
      [`current_interests.${category}`]: newScore,
      [`genuine_engagement_counts.${category}`]: newEngagementCount,
      [`last_score_updated_at.${category}`]: Timestamp.now(),
      "ai_agent_metadata.last_evaluation_cycle": Timestamp.now(),
      "ai_agent_metadata.current_prompt_version": "v2.0_disa",
    };
    await profileRef.set(updates, { merge: true });

    logger.info(`updateInterestModel: DISA updated for uid=${uid}`, {
      category,
      charCount,
      E: E.toFixed(3),
      phase,
      prevScore: prevScore.toFixed(2),
      newScore: newScore.toFixed(2),
      engagementCount: newEngagementCount,
    });

    // ── Gemini: agent_notes のみ非同期更新（スコアには関与しない）────────────
    const existingNotes = profileData.ai_agent_metadata?.agent_notes ?? "";
    const phaseLabel =
      phase === 1 ? "状況的興味（Phase 1）"
      : phase === 2 ? "維持された興味（Phase 2）"
      : "個人的興味（Phase 3）";

    const notesPrompt = [
      "あなたは子どもの学習興味を観察するAIエージェントです。",
      "数値スコアの計算はすでに完了しています。",
      "あなたの役割は子どもの興味傾向を人間が読める形で記録することだけです。",
      "",
      `【最新の閲覧】カテゴリ: ${category} / 閲覧時間: ${viewDurationSeconds}秒 / E値: ${E.toFixed(2)} / フェーズ: ${phaseLabel}`,
      `【現在のメモ】${existingNotes || "（まだなし）"}`,
      "",
      "上記を踏まえ、この子どもの興味傾向メモを100文字以内で更新してください。",
      '出力は {"updated_notes": "..."} のJSONのみ。',
    ].join("\n");

    try {
      const result = await getGenAI().models.generateContent({
        model: GEMINI_MODEL,
        contents: [{ role: "user", parts: [{ text: notesPrompt }] }],
        config: { temperature: 0.7, responseMimeType: "application/json" },
      });
      const raw = result.text ?? "{}";
      const parsed = JSON.parse(raw) as { updated_notes?: string };
      if (parsed.updated_notes) {
        await profileRef.set(
          { "ai_agent_metadata.agent_notes": parsed.updated_notes },
          { merge: true }
        );
      }
    } catch (err) {
      // メモの更新失敗はスコアに影響しないため警告のみ
      logger.warn("updateInterestModel: agent_notes update failed", { err: `${err}` });
    }
  }
);
