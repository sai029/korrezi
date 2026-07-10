import { createHash, randomUUID } from "node:crypto";

import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getStorage } from "firebase-admin/storage";
import { setGlobalOptions } from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import { GoogleGenAI, HarmBlockThreshold, HarmCategory } from "@google/genai";

initializeApp();

// Firestore と同じ東京リージョンで動かす。
setGlobalOptions({ region: "asia-northeast1" });

// GNews.io の API キー。`firebase functions:secrets:set GNEWS_API_KEY` で登録する。
const GNEWS_API_KEY = defineSecret("GNEWS_API_KEY");

// Vertex AI（Gemini）の設定。認証は関数の実行サービスアカウント（ADC）を使うため
// API キーは不要。モデルが広く利用可能な us-central1 を既定にする。
const VERTEX_LOCATION = "us-central1";
const GEMINI_MODEL = "gemini-2.5-flash";

// サムネのアートスタイル（全生成で共通）。
// ターゲットは中学受験を意識する中高学年（10〜12歳）。幼児向けの原色ポップ・
// デフォルメ絵は「ダサい＝自分向けではない」と判断されるため避け、音楽 MV／
// スタイリッシュなアニメ OP のようなエディトリアル線画＋限定アクセントカラーで
// 「知的でクール・少し背伸び」した印象にする。Imagen は英語プロンプトの品質が
// 高いため英語で指定する。scene 記述の後ろに常にこの1文を付けてスタイルを固定する。
const THUMBNAIL_STYLE =
  "Modern, stylish flat editorial illustration with a fresh, bright and airy mood. " +
  "A light, clean background with a curated palette of two or three trendy accent colours " +
  "(for example soft coral, teal, warm yellow or lavender) — colourful and upbeat but tasteful, " +
  "never garish. Confident, elegant linework and simple geometric shapes with a light sense of " +
  "motion; think a cool contemporary magazine spread or a sleek app illustration, NOT a dark " +
  "music video. Sophisticated yet friendly and optimistic — aimed at smart pre-teens aged 10 to 12, " +
  "never childish, and never gloomy, eerie or scary. Generous negative space. " +
  "Keep the main subject in the upper two-thirds and leave the lower third calmer and " +
  "less busy so an app can overlay a title there. " +
  "Absolutely no text, no letters, no numbers, no words anywhere in the image. " +
  "Avoid: dark / gloomy / eerie atmosphere, heavy black backgrounds, harsh noir shadows, " +
  "loud saturated primary-color pop, thick uniform outlines, chibi or big-head cartoon mascots, " +
  "googly eyes, wide open-mouthed smiles, rainbow gradients, clip-art, cutesy kawaii style, " +
  "textbook or educational-clipart look. 16:9 aspect ratio.";

// quality_review マップの構造バージョン。後で項目を変えたら上げる。
// v2: topic（トピック分類）を追加し interest_context をソース名からトピックへ変更。
const QUALITY_SCHEMA_VERSION = 2;

/**
 * 品質ゲート: 教育的価値がこの値**未満**（＝1以下）の記事は除外する。
 *
 * 芸能ゴシップ・中身の薄い記事対策（AI 自身が reason で「不適切」と書いていても、
 * 従来は品質軸を除外に使っておらず素通りしていた）。閾値はコスト・精度実績を見て調整する。
 * 詳細は docs/CONTENT_QUALITY_GATE.md。
 */
const MIN_EDUCATIONAL_VALUE = 2;

/**
 * 採点の Vertex AI 安全フィルタ（本物の安全層）。
 *
 * プロンプトの safe 判定はブレが大きいため、実際の有害コンテンツは Vertex 側で
 * 応答ごとブロックし、除外する（fail-closed）。無害な経済・スポーツ記事は
 * どの閾値でも発火しないため、誤除外の再発はしない。過剰ブロックが出たら閾値を緩める。
 */
const SAFETY_SETTINGS = [
  HarmCategory.HARM_CATEGORY_HARASSMENT,
  HarmCategory.HARM_CATEGORY_HATE_SPEECH,
  HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
  HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
].map((category) => ({
  category,
  threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
}));

/**
 * 記事トピックの固定タクソノミー。
 *
 * interest_context に入り、DISA の興味カテゴリ・パーソナライズ・サムネ生成の
 * 全てで使われる。アプリ側 `categoryIcon()`（feed_thumbnail.dart）の
 * 日本語キーワード（科学/宇宙/テクノロジー/自然/動物/スポーツ/食べ物/音楽）と
 * 部分一致するよう命名している。変更時はアプリ側のアイコン対応も確認すること。
 */
const TOPIC_CATEGORIES = [
  "科学",
  "宇宙",
  "テクノロジー",
  "自然・環境",
  "動物",
  "スポーツ",
  "食べ物",
  "音楽・アート",
  "経済・お金",
  "国際・世界",
  "文化・歴史",
  "社会・くらし",
] as const;

/** 分類できなかったときの受け皿トピック。 */
const TOPIC_FALLBACK = "社会・くらし";

/**
 * トピック別テンプレ画像（アプリにバンドルする asset パス）。
 *
 * Imagen 生成画像が無い/失敗した記事でも「何の記事か分かる画像」を必ず表示するための
 * 基本レイヤー。thumbnail_config.base_asset に入れ、FeedThumbnail が AssetImage で描画する。
 * ファイルは Flutter 側 assets/thumbnails/templates/*.jpg と pubspec への登録が必要。
 */
const TOPIC_TEMPLATE_ASSET: Record<string, string> = {
  "科学": "assets/thumbnails/templates/science.jpg",
  "宇宙": "assets/thumbnails/templates/space.jpg",
  "テクノロジー": "assets/thumbnails/templates/technology.jpg",
  "自然・環境": "assets/thumbnails/templates/nature.jpg",
  "動物": "assets/thumbnails/templates/animal.jpg",
  "スポーツ": "assets/thumbnails/templates/sports.jpg",
  "食べ物": "assets/thumbnails/templates/food.jpg",
  "音楽・アート": "assets/thumbnails/templates/art.jpg",
  "経済・お金": "assets/thumbnails/templates/economy.jpg",
  "国際・世界": "assets/thumbnails/templates/world.jpg",
  "文化・歴史": "assets/thumbnails/templates/culture.jpg",
  "社会・くらし": "assets/thumbnails/templates/society.jpg",
};

/** トピックに対応するテンプレ画像 asset パスを返す（未知トピックは受け皿へ）。 */
function templateAssetForTopic(topic: string): string {
  return TOPIC_TEMPLATE_ASSET[topic] ?? TOPIC_TEMPLATE_ASSET[TOPIC_FALLBACK];
}

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
  /** TOPIC_CATEGORIES のいずれか。interest_context として保存される。 */
  topic: string;
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
    "④ safety（安全面）: すべての記事で必ず真偽値の safe を返すこと。残虐/性的/差別/",
    "  自殺・自傷、または過度に恐怖を煽る描写が含まれるなら safe=false、含まれなければ",
    "  safe=true。該当する種類を safety_flags に日本語で列挙（無ければ空配列）。",
    "⑤ topic（トピック分類）: 記事の主題に最も近いものを次のリストから必ず1つ選ぶ:",
    `  ${TOPIC_CATEGORIES.join(" / ")}`,
    `  どれにも当てはまらない場合は「${TOPIC_FALLBACK}」を選ぶ。リストにない語を作らない。`,
    "",
    "出力は必ず次の7キーを持つJSONだけにする（前後に説明文を付けない）:",
    '- "educational_value": 1〜5 の整数',
    '- "thinking_hook": 1〜5 の整数（概要が短すぎて判定できないときのみ 0）',
    '- "reliability": 1〜5 の整数',
    '- "safe": 真偽値。安全なら true、危険なら false（安全でも必ず含める）',
    '- "safety_flags": 文字列配列。危険な種類を日本語で。無ければ []',
    '- "topic": 上記トピックのいずれか1つ',
    '- "reason": 判定理由の日本語1文',
    "",
    "記事:",
    articleSource(a),
  ].join("\n");

  try {
    const result = await getGenAI().models.generateContent({
      model: GEMINI_MODEL,
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      config: {
        temperature: 0,
        responseMimeType: "application/json",
        safetySettings: SAFETY_SETTINGS,
      },
    });
    const text = result.text ?? "";
    const parsed = JSON.parse(text) as Record<string, unknown>;

    const flagged = Array.isArray(parsed.safety_flags)
      ? parsed.safety_flags.filter((x): x is string => typeof x === "string")
      : [];
    // 安全除外は「モデルが具体的な危険カテゴリを safety_flags に挙げた時」だけに限定する。
    // 単独の safe 真偽値はブレが大きく、無害な記事（経済・スポーツ等）でも safe=true を
    // きれいに返さず誤除外していた。実際の有害コンテンツは Vertex safetySettings が応答ごと
    // ブロックして除外する（二重防御）ため、判定を flagged の有無へ一本化する。
    const passed = flagged.length === 0;

    // 除外時は理由を残す（safe_raw はモデルの safe 判断。flags 非空が実際の安全 NG）。
    // フィードが空になる原因の切り分け用。
    if (!passed) {
      logger.info("scoreArticle dropped on safety", {
        url: a.url,
        safe_raw: parsed.safe ?? null,
        flags: flagged,
        reason: typeof parsed.reason === "string" ? parsed.reason : "",
      });
    }

    // タクソノミー外の値（Gemini の造語）はフォールバックに寄せる
    const topic =
      typeof parsed.topic === "string" &&
      (TOPIC_CATEGORIES as readonly string[]).includes(parsed.topic)
        ? parsed.topic
        : TOPIC_FALLBACK;

    return {
      verdict: "approved",
      safety: { passed, flagged },
      scores: {
        educationalValue: clampScore(parsed.educational_value),
        thinkingHook: clampScore(parsed.thinking_hook),
        reliability: clampScore(parsed.reliability),
      },
      reason: typeof parsed.reason === "string" ? parsed.reason : "",
      topic,
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
    articleSource(a),
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

/** 採点ゲートの除外理由。null は合格。 */
type RejectReason = "scoring_failed" | "safety" | "low_quality";

/**
 * 採点結果から除外理由を決める。null なら合格して news_pool に載せる。
 *
 * 優先順: 採点失敗(fail-closed) → 安全NG → 品質NG(教育的価値が低い)。
 */
function rejectReason(review: QualityReview | null): RejectReason | null {
  if (review === null) return "scoring_failed";
  if (!review.safety.passed) return "safety";
  const edu = review.scores.educationalValue;
  if (edu !== null && edu < MIN_EDUCATIONAL_VALUE) return "low_quality";
  return null;
}

/**
 * メタデータサーバから Vertex/Storage 用のアクセストークンを取得する。
 * Cloud Functions 実行環境でのみ有効。失敗時は空文字を返す（呼び出し側でフォールバック）。
 */
async function fetchAccessToken(): Promise<string> {
  try {
    const res = await fetch(
      "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token",
      { headers: { "Metadata-Flavor": "Google" } },
    );
    const { access_token: token } = (await res.json()) as { access_token: string };
    return token ?? "";
  } catch (err) {
    logger.warn("access token fetch failed", { err: `${err}` });
    return "";
  }
}

// ─── Push 通知（FCM） ─────────────────────────────────────────────────────────
// 送信先はファミリー単位の単一アカウント（uid）配下の端末トークン。現状 parent/child の
// 端末ロール区別は持たないため、両通知とも同じ uid の全トークンに届く（docs/PENDING_ACTIONS.md）。
// 通知 data の型はクライアント fcm_service.dart のディープリンク契約と一致させること。

type TokenRefMap = Map<string, FirebaseFirestore.DocumentReference>;

/**
 * 指定トークン群へ同一メッセージを送る。失効トークンは fcm_tokens から削除する。
 *
 * @param tokenRefs token 文字列 → その Firestore ドキュメント参照（失効時の掃除用）
 * @returns 送信に成功した端末数
 */
async function sendToTokens(
  tokenRefs: TokenRefMap,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<number> {
  const tokens = [...tokenRefs.keys()];
  if (tokens.length === 0) return 0;

  const messaging = getMessaging();
  const stale: FirebaseFirestore.DocumentReference[] = [];
  let sent = 0;

  // multicast は 1 回あたり最大 500 トークン。
  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    const res = await messaging.sendEachForMulticast({
      tokens: chunk,
      notification: { title, body },
      data,
      android: { priority: "high" },
    });
    res.responses.forEach((r, j) => {
      if (r.success) {
        sent++;
        return;
      }
      const code = r.error?.code ?? "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        code === "messaging/invalid-argument"
      ) {
        const ref = tokenRefs.get(chunk[j]);
        if (ref) stale.push(ref);
      }
    });
  }

  // 失効トークンを掃除（送信の成否には影響させない）。
  if (stale.length > 0) {
    const batch = getFirestore().batch();
    stale.forEach((ref) => batch.delete(ref));
    await batch.commit();
    logger.info(`FCM: removed ${stale.length} stale tokens`);
  }
  return sent;
}

/**
 * 1ユーザーの端末トークンを取得する（token → docRef）。
 *
 * @param roleFilter 指定すると、その役割（parent/child）のトークンだけに絞る。
 *   端末は fcm_tokens ドキュメントに `role` を持つ（クライアントがオンボーディングで設定）。
 */
async function tokenRefsForUser(
  uid: string,
  roleFilter?: (role: string | undefined) => boolean,
): Promise<TokenRefMap> {
  const snap = await getFirestore()
    .collection("users").doc(uid).collection("fcm_tokens").get();
  const map: TokenRefMap = new Map();
  snap.docs.forEach((d) => {
    if (roleFilter && !roleFilter((d.data() as {role?: string}).role)) return;
    map.set(d.id, d.ref);
  });
  return map;
}

/**
 * 通知①（子ども向け）: 新着記事が入ったら「新しいニュースが届いた」通知を送る。
 *
 * news_pool は全ユーザー共通のため、トークンを持つ全ユーザーの端末へ一斉送信する。
 * ただし**保護者用端末（role==="parent"）は除外**し、お子さん用と役割未設定
 * （旧クライアント）の端末にのみ送る。ディープリンクはフィード（/child）へ。
 */
async function notifyNewArticles(newCount: number): Promise<void> {
  if (newCount <= 0) return;
  try {
    const snap = await getFirestore().collectionGroup("fcm_tokens").get();
    const map: TokenRefMap = new Map();
    snap.docs.forEach((d) => {
      const role = (d.data() as {role?: string}).role;
      if (role === "parent") return; // 保護者端末には子ども向け新着を送らない
      map.set(d.id, d.ref);
    });
    const body = newCount === 1
      ? "あたらしい記事を1本ついかしたよ。よんでみよう！"
      : `あたらしい記事を${newCount}本ついかしたよ。よんでみよう！`;
    const sent = await sendToTokens(map, "新しいニュースがとどいたよ📰", body, {
      type: "feed",
    });
    logger.info(`notifyNewArticles: sent to ${sent} devices (newCount=${newCount})`);
  } catch (err) {
    logger.error("notifyNewArticles failed", { err: `${err}` });
  }
}

/**
 * 記事群を「採点ゲート → 合格分のみ子ども向け変換 → サムネ生成 → news_pool 書き込み」まで
 * 処理し、実際に書き込んだ件数を返す。fetchNews / refreshNewsPool の共通処理。
 *
 * ゲートは変換の前に置く（落とす記事に変換コストを払わない）。
 * サムネは記事単位（全ユーザー共通）で1回だけ生成し news_pool に保存するため、
 * Common / Child / 詳細すべての画面でそのまま表示される（personalizeArticles は
 * 生成済み URL を検知して再生成をスキップする）。
 */
async function ingestArticles(
  articles: GNewsArticle[],
): Promise<{ written: number; newCount: number }> {
  // 1. 採点（並列）。安全性を確認できない記事は null。
  const reviews = await Promise.all(articles.map(scoreArticle));

  // 2. 合格 / 除外に振り分け。安全NG・採点失敗・品質NG(教育的価値<2)を除外。
  const survivors: { article: GNewsArticle; review: QualityReview }[] = [];
  const rejected: {
    article: GNewsArticle;
    review: QualityReview | null;
    reason: RejectReason;
  }[] = [];
  articles.forEach((article, i) => {
    const review = reviews[i];
    const reason = rejectReason(review);
    if (reason === null) {
      // reason===null は review が非 null を保証する（rejectReason の定義より）。
      survivors.push({ article, review: review as QualityReview });
    } else {
      rejected.push({ article, review, reason });
    }
  });

  if (rejected.length > 0) {
    logger.info(
      `quality gate dropped ${rejected.length}/${articles.length} articles`,
      { reasons: rejected.map((x) => x.reason) },
    );
  }

  // 3. 合格分のみ子ども向けに変換（並列）。
  const converted = await Promise.all(
    survivors.map((x) => toChildFriendly(x.article)),
  );

  // 3.5 サムネ生成（並列・全記事対象）。記事本文に合った画像を Imagen 3 で1記事1枚生成する。
  // GNews の元画像は CORS でブロックされるため使わない。生成に失敗した記事は
  // カテゴリ別テンプレ画像（base_asset）にフォールバックし「画像なし」状態を作らない。
  const project = process.env.GCLOUD_PROJECT ?? "";
  const accessToken = await fetchAccessToken();
  const thumbUrls = await Promise.all(
    survivors.map(async ({ article: a, review }, i) => {
      if (!accessToken) return "";
      try {
        return await generateOneThumbnail(
          newsIdFromUrl(a.url),
          converted[i].displayTitle,
          converted[i].displayTagline,
          review.topic,
          accessToken,
          project,
        );
      } catch (err) {
        logger.warn("ingest thumbnail generation failed; using template", {
          url: a.url,
          err: `${err}`,
        });
        return "";
      }
    }),
  );

  // 4. WriteBatch で news_pool（合格）と rejected_articles（除外）へ書き込み。
  const db = getFirestore();

  // 通知①のため「今回初めて追加される記事」の数を数える（既存 id は上書き=重複）。
  const survivorIds = survivors.map(({ article }) => newsIdFromUrl(article.url));
  let newCount = 0;
  if (survivorIds.length > 0) {
    const existing = await db.getAll(
      ...survivorIds.map((id) => db.collection("news_pool").doc(id)),
    );
    newCount = existing.filter((s) => !s.exists).length;
  }

  const batch = db.batch();

  survivors.forEach(({ article: a, review }, i) => {
    const id = newsIdFromUrl(a.url);
    const cf = converted[i];

    // 生成できた記事は generated（Imagen URL）、失敗時はトピック別テンプレ画像で表示する。
    // base_asset は generated 時も保持し、ネットワーク画像が失敗したときの受け皿にする。
    const generatedUrl = thumbUrls[i];
    const template = templateAssetForTopic(review.topic);
    const thumbnailConfig = generatedUrl
      ? { mode: "generated", base_asset: template, optional_generated_url: generatedUrl }
      : { mode: "text_overlay", base_asset: template, optional_generated_url: "" };

    batch.set(db.collection("news_pool").doc(id), {
      original_title: a.title,
      published_at: Timestamp.fromDate(new Date(a.publishedAt)),
      parent_summary: cf.parentSummary,
      child_body_with_ruby: cf.childBodyWithRuby,
      display_title: cf.displayTitle,
      display_tagline: cf.displayTagline,
      child_title_with_ruby: cf.childTitleWithRuby,
      thumbnail_config: thumbnailConfig,
      char_count: countCharsForReading(cf.childBodyWithRuby),
      // 興味カテゴリ = 採点ゲートで分類したトピック（TOPIC_CATEGORIES）。
      // 旧実装ではソース名（"NHK ニュース" 等）が入っており、DISA が
      // 「よく見る放送局」を学習してしまっていた。出典は source_name に分離。
      interest_context: review.topic,
      source_name: a.source?.name ?? "ニュース",
      // 採点ゲートの結果。教育的価値は除外に使用（MIN_EDUCATIONAL_VALUE 未満は落とす）。
      // 思考フック・信頼性は当面記録のみ。
      quality_review: {
        verdict: review.verdict,
        safety: review.safety,
        scores: review.scores,
        topic: review.topic,
        reason: review.reason,
        model: GEMINI_MODEL,
        schema_version: QUALITY_SCHEMA_VERSION,
        scored_at: Timestamp.now(),
      },
    });
  });

  // 除外記事は監査・閾値調整用に rejected_articles/{id} へ保存（同じ id で冪等）。
  // クライアントには公開しない（Admin SDK 書き込み・Firebase コンソールで確認する想定）。
  rejected.forEach(({ article: a, review, reason }) => {
    const id = newsIdFromUrl(a.url);
    batch.set(db.collection("rejected_articles").doc(id), {
      original_title: a.title,
      url: a.url,
      interest_context: review?.topic ?? TOPIC_FALLBACK,
      source_name: a.source?.name ?? "ニュース",
      published_at: Timestamp.fromDate(new Date(a.publishedAt)),
      // scoring_failed=採点失敗(fail-closed/Vertexブロック) / safety=安全NG /
      // low_quality=教育的価値が低い（品質ゲート）。
      rejected_reason: reason,
      safety_flags: review?.safety.flagged ?? [],
      scores: review?.scores ?? null,
      reason: review?.reason ?? "",
      model: GEMINI_MODEL,
      schema_version: QUALITY_SCHEMA_VERSION,
      rejected_at: Timestamp.now(),
    });
  });

  await batch.commit();
  return { written: survivors.length, newCount };
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

    // 手動取得は「今アプリを使っている人」の操作なので新着通知は出さない
    //（通知①はスケジュールの refreshNewsPool 側でのみ送る）。
    const { written } = await ingestArticles(articles);
    logger.info(`fetchNews wrote ${written} articles for ${uid}`);
    return { count: written };
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

    const { written, newCount } = await ingestArticles(articles);
    logger.info(
      `refreshNewsPool wrote ${written} articles (${newCount} new) to news_pool`,
    );
    // 通知①（子ども向け）: 新着があれば全端末へ「新しいニュースが届いた」通知。
    await notifyNewArticles(newCount);
  },
);

/**
 * 通知②（保護者向け）: 毎日 18:00(JST)、その日にお子さんがアプリを使った家庭へ
 * 「今日読んだ記事を見てみましょう」というダイジェスト通知を送る（帰宅途中の閲覧想定）。
 *
 * 「本日利用」の判定は users/{uid}.last_active_at（閲覧のたびに updateInterestModel が刻む）。
 * ディープリンクは保護者ダッシュボード（/parent）へ。
 */
export const sendParentDigest = onSchedule(
  {
    schedule: "0 18 * * *",
    timeZone: "Asia/Tokyo",
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async () => {
    const db = getFirestore();

    // JST 今日の 0:00 を UTC の Timestamp として求める（関数は UTC で動くため補正）。
    const jstNow = new Date(Date.now() + 9 * 3600 * 1000);
    const startUtcMs =
      Date.UTC(jstNow.getUTCFullYear(), jstNow.getUTCMonth(), jstNow.getUTCDate()) -
      9 * 3600 * 1000;
    const startOfTodayJST = Timestamp.fromMillis(startUtcMs);

    const activeSnap = await db
      .collection("users")
      .where("last_active_at", ">=", startOfTodayJST)
      .get();

    let families = 0;
    let totalSent = 0;
    for (const userDoc of activeSnap.docs) {
      // 保護者用端末のみへ送る（お子さん用端末には日次ダイジェストを送らない）。
      const map = await tokenRefsForUser(
        userDoc.id,
        (role) => role === "parent",
      );
      if (map.size === 0) continue;
      const sent = await sendToTokens(
        map,
        "今日のまなびレポート📚",
        "お子さんが今日読んだ記事と、興味の広がりをのぞいてみましょう。",
        { type: "parent_digest" },
      );
      families++;
      totalSent += sent;
    }
    logger.info(
      `sendParentDigest: sent to ${totalSent} devices across ${families} families`,
    );
  },
);

// ═══════════════════════════════════════════════════════════════════════════════
// クイズ生成（Common View「いっしょに」の記事詳細で出題する4択クイズ）
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * 記事本文から生成する子ども向け4択クイズ（1問）。
 *
 * question / choices / explanation はアプリの FuriganaText が解釈する
 * `〔漢字｜よみ〕` ルビ markup を含みうる（plain でも表示できる）。
 */
interface QuizData {
  question: string;
  choices: string[]; // 必ず4つ
  answerIndex: number; // 0〜3
  explanation: string;
}

/**
 * 子ども向け本文から4択クイズを1問生成する（内部ヘルパー）。
 *
 * 本文に書かれた事実だけを問う「内容理解クイズ」。失敗・不正な出力のときは null を返し、
 * 呼び出し側で fail する（未検証のクイズを保存・キャッシュしない）。
 */
async function generateOneQuiz(childBodyWithRuby: string): Promise<QuizData | null> {
  const prompt = [
    "あなたは小学生向けニュースアプリのクイズ作成AIです。",
    "次の記事本文を読んだ子ども（6〜10歳）が、内容を理解できたか確かめる4択クイズを1問作ります。",
    "",
    "ルール:",
    "- 質問は本文に書かれている事実だけから作る。本文に無い知識・推測を問わない。",
    "- 選択肢はちょうど4つ。正解は1つだけ。不正解は本文と矛盾するが、ありそうに見えるものにする。",
    "- 小学校で習わない漢字には 〔漢字｜よみ〕 の形式でルビを付ける（質問・選択肢・解説すべて）。",
    "- explanation は「なぜその答えなのか」を本文に沿って1文でやさしく説明する。",
    "",
    "出力は必ず次の4キーを持つJSONだけにする（前後に説明文を付けない）:",
    '- "question": 質問文（子ども向け・ルビ付き）',
    '- "choices": 選択肢4つの文字列配列（ルビ付き）',
    '- "answer_index": 正解の番号（0〜3の整数）',
    '- "explanation": 正解の理由（1文・ルビ付き）',
    "",
    "記事本文:",
    childBodyWithRuby,
  ].join("\n");

  try {
    const result = await getGenAI().models.generateContent({
      model: GEMINI_MODEL,
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      config: { temperature: 0.4, responseMimeType: "application/json" },
    });
    const parsed = JSON.parse(result.text ?? "") as Record<string, unknown>;
    return normalizeQuiz(parsed);
  } catch (err) {
    logger.warn("generateOneQuiz failed", { err: `${err}` });
    return null;
  }
}

/** Gemini / Firestore 由来の緩い型のクイズを検証し、正しければ QuizData を返す。 */
function normalizeQuiz(raw: unknown): QuizData | null {
  if (typeof raw !== "object" || raw === null) return null;
  const r = raw as Record<string, unknown>;

  const question = typeof r.question === "string" ? r.question.trim() : "";
  const explanation =
    typeof r.explanation === "string" ? r.explanation.trim() : "";
  const choices = Array.isArray(r.choices)
    ? r.choices.filter((c): c is string => typeof c === "string" && c.trim().length > 0)
    : [];
  // Firestore 保存時は answerIndex、Gemini 出力は answer_index の両方を許容。
  const idxRaw = r.answerIndex ?? r.answer_index;
  const answerIndex =
    typeof idxRaw === "number" ? Math.round(idxRaw) : Number(idxRaw);

  if (
    question.length === 0 ||
    choices.length !== 4 ||
    !Number.isInteger(answerIndex) ||
    answerIndex < 0 ||
    answerIndex > 3
  ) {
    return null;
  }
  return { question, choices, answerIndex, explanation };
}

/**
 * 記事の内容理解クイズを取得する。
 *
 * 既に news_pool/{newsId}.quiz があればそれを返し（キャッシュ）、無ければ本文から生成して
 * news_pool に保存してから返す。→ 開かれた記事だけ1回だけ Gemini を呼ぶ（コスト最小）。
 */
export const generateQuiz = onCall(
  { timeoutSeconds: 60, memory: "256MiB" },
  async (request): Promise<{ quiz: QuizData }> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "ログインが必要です。");
    }
    const newsId = request.data?.newsId;
    if (typeof newsId !== "string" || newsId.length === 0) {
      throw new HttpsError("invalid-argument", "newsId が必要です。");
    }

    const db = getFirestore();
    const ref = db.collection("news_pool").doc(newsId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "記事が見つかりません。");
    }
    const data = snap.data() ?? {};

    // キャッシュヒット: 保存済みの正しいクイズがあればそのまま返す。
    const cached = normalizeQuiz(data.quiz);
    if (cached) {
      return { quiz: cached };
    }

    const body =
      typeof data.child_body_with_ruby === "string"
        ? data.child_body_with_ruby
        : "";
    if (body.trim().length === 0) {
      throw new HttpsError("failed-precondition", "記事本文がありません。");
    }

    const quiz = await generateOneQuiz(body);
    if (!quiz) {
      throw new HttpsError("internal", "クイズの生成に失敗しました。");
    }

    // 生成できたクイズだけ news_pool にキャッシュ（merge で他フィールドを保持）。
    await ref.set(
      {
        quiz: {
          question: quiz.question,
          choices: quiz.choices,
          answerIndex: quiz.answerIndex,
          explanation: quiz.explanation,
          model: GEMINI_MODEL,
          generated_at: Timestamp.now(),
        },
      },
      { merge: true },
    );

    logger.info(`generateQuiz created quiz for ${newsId}`);
    return { quiz };
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

    // 読み取り時に DISA 減衰を適用して現時点の実効スコアを算出する。
    // TOPIC_CATEGORIES 以外のキー（ニュースソース名等の旧スキーマ残骸）は
    // ここで除外する。source_name 分離前に書き込まれたレガシーデータや、
    // 将来の書き込みバグが混入しても Gemini プロンプトに渡さないための防御。
    const decayedInterests: Record<string, number> = {};
    const topicSet = new Set<string>(TOPIC_CATEGORIES);
    for (const [cat, score] of Object.entries(interests)) {
      if (!topicSet.has(cat)) continue;
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

    const fulfilled = settled
      .filter(
        (r): r is PromiseFulfilledResult<PersonalizedRecord> => r.status === "fulfilled"
      )
      .map((r) => r.value);

    // 既存 personalized_feed の is_viewed / thumb_variant を対象記事分だけ読む
    // （未読判定・冪等化に使用。全コレクション走査を避けるため getAll で対象 id のみ取得）。
    const feedState = new Map<string, { viewed: boolean; variant: string }>();
    if (fulfilled.length > 0) {
      const feedRefs = fulfilled.map((item) =>
        db.collection("users").doc(uid).collection("personalized_feed").doc(item.news_id)
      );
      const snaps = await db.getAll(...feedRefs);
      for (const d of snaps) {
        const data = d.data();
        if (!data) continue;
        feedState.set(d.id, {
          viewed: data.is_viewed === true,
          variant: (data.thumb_variant as string) ?? "",
        });
      }
    }

    // telemetry（is_viewed / view_duration_seconds）は上書きしないよう merge: true
    const batch = db.batch();
    let count = 0;
    for (const item of fulfilled) {
      const ref = db
        .collection("users")
        .doc(uid)
        .collection("personalized_feed")
        .doc(item.news_id);
      // 既に興味別サムネ（variant:"interest"）を持つ未読記事は、その専用画像を保持する。
      // item.thumbnail_config は共有 news_pool の画像なので、上書きすると B で再生成した
      // 専用サムネが毎回リセットされ、以降 variant 冪等化で復活しなくなるため除外する。
      const st = feedState.get(item.news_id);
      const preserveThumb = st?.variant === "interest" && !st.viewed;
      const payload: Record<string, unknown> = {
        news_id: item.news_id,
        interest_context: item.interest_context,
        display_title: item.display_title,
        display_tagline: item.display_tagline,
        interest_score: item.interest_score,
        personalized_at: item.personalized_at,
      };
      if (!preserveThumb) payload.thumbnail_config = item.thumbnail_config;
      batch.set(ref, payload, { merge: true });
      count++;
    }
    await batch.commit();

    // ─── バックグラウンドサムネ生成 ────────────────────────────────────────────
    // 2 種類の生成を行う。
    //  A. サムネ補完（興味非依存）: firebasestorage URL を持たない記事に共有サムネを
    //     生成し news_pool と personalized_feed の両方に書く。CORS 表示の担保。
    //     通常は ingestArticles で全記事生成済みのため、ここは生成失敗の取りこぼしのみ。
    //  B. 興味別再生成（Phase③）: 既に共有サムネがあり・未読で・トピックが子どもの
    //     上位興味に一致する記事に、その子専用サムネを生成。personalized_feed だけに
    //     書き（共有 news_pool は汚さない）、thumb_variant:"interest" で冪等化する。
    const hasValidThumb = (config: ThumbnailConfigData): boolean =>
      config.mode === "generated" &&
      config.optional_generated_url.startsWith("https://firebasestorage.googleapis.com");

    // 子どもの上位興味カテゴリ（減衰後 > 0.5・上位5件）。B の対象トピック判定に使う。
    const topInterestCategories = new Set(
      Object.entries(decayedInterests)
        .filter(([, v]) => v > 0.5)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 5)
        .map(([k]) => k)
    );

    // A: 共有サムネが未整備の記事。
    const completionTargets = fulfilled.filter(
      (item) => !hasValidThumb(item.thumbnail_config)
    );
    // B: 共有サムネはあるが、未読 × 上位興味トピック × 未生成 の記事。
    const interestTargets = fulfilled.filter((item) => {
      if (!hasValidThumb(item.thumbnail_config)) return false; // A に任せ二重生成を避ける
      if (!topInterestCategories.has(item.interest_context)) return false;
      const st = feedState.get(item.news_id);
      if (st?.viewed) return false;                 // 既読は再生成しない
      if (st?.variant === "interest") return false; // 生成済みはスキップ（冪等）
      return true;
    });

    if (completionTargets.length > 0 || interestTargets.length > 0) {
      const project = process.env.GCLOUD_PROJECT ?? "";
      const accessToken = await fetchAccessToken();
      if (!accessToken) {
        logger.warn("personalizeArticles: access token unavailable, skip thumbnails");
      } else {
        const interestHint = [...topInterestCategories].join(", ");
        const thumbBatch = db.batch();
        let thumbCount = 0;

        // A: 共有サムネ → news_pool + personalized_feed の両方を更新。
        const compSettled = await Promise.allSettled(
          completionTargets.map(async (item) => ({
            news_id: item.news_id,
            imageUrl: await generateOneThumbnail(
              item.news_id, item.display_title, item.display_tagline,
              item.interest_context, accessToken, project
            ),
          }))
        );
        for (const r of compSettled) {
          if (r.status !== "fulfilled") {
            logger.warn("thumbnail(completion) failed", { reason: `${r.reason}` });
            continue;
          }
          const { news_id, imageUrl } = r.value;
          const cfg: ThumbnailConfigData = {
            mode: "generated", base_asset: "", optional_generated_url: imageUrl,
          };
          thumbBatch.update(db.collection("news_pool").doc(news_id), {
            thumbnail_config: cfg,
          });
          thumbBatch.set(
            db.collection("users").doc(uid).collection("personalized_feed").doc(news_id),
            { thumbnail_config: cfg },
            { merge: true }
          );
          thumbCount++;
        }

        // B: 興味別サムネ → 共有パスを上書きせず専用パスへ保存、personalized_feed のみ更新。
        const intSettled = await Promise.allSettled(
          interestTargets.map(async (item) => ({
            news_id: item.news_id,
            imageUrl: await generateOneThumbnail(
              item.news_id, item.display_title, item.display_tagline,
              item.interest_context, accessToken, project,
              {
                storageObjectPath: `thumbnails/personalized/${uid}/${item.news_id}.jpg`,
                interestHint,
              }
            ),
          }))
        );
        for (const r of intSettled) {
          if (r.status !== "fulfilled") {
            logger.warn("thumbnail(interest) failed", { reason: `${r.reason}` });
            continue;
          }
          const { news_id, imageUrl } = r.value;
          const cfg: ThumbnailConfigData = {
            mode: "generated", base_asset: "", optional_generated_url: imageUrl,
          };
          thumbBatch.set(
            db.collection("users").doc(uid).collection("personalized_feed").doc(news_id),
            { thumbnail_config: cfg, thumb_variant: "interest" },
            { merge: true }
          );
          thumbCount++;
        }

        if (thumbCount > 0) await thumbBatch.commit();
        logger.info(
          `personalizeArticles: thumbnails for uid=${uid} ` +
          `(completion=${completionTargets.length}, interest=${interestTargets.length})`
        );
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
 * @param opts        任意設定。
 *   - storageObjectPath: 保存先 Storage オブジェクトパス（省略時 `thumbnails/{newsId}.jpg`）。
 *     共有 news_pool サムネを上書きしたくない興味別再生成では専用パスを渡す。
 *   - interestHint:      その子が特に関心を持つテーマ（英語）。Gemini のシーン選定を
 *     この関心方向に寄せるためのヒント。
 * @returns           Storage 公開 URL
 */
async function generateOneThumbnail(
  newsId: string,
  title: string,
  tagline: string,
  category: string,
  accessToken: string,
  project: string,
  opts?: { storageObjectPath?: string; interestHint?: string }
): Promise<string> {
  const storageObjectPath = opts?.storageObjectPath ?? `thumbnails/${newsId}.jpg`;
  const interestHint = opts?.interestHint?.trim();
  // Gemini で記事内容から Imagen 向け英語ビジュアルプロンプトを生成する。
  // Imagen 3 は英語プロンプトの方が品質が高く、日本語ソース名（"NHK ニュース" 等）を
  // そのままテーマに使うと記事と無関係な画像が生成されるため、Gemini が意味を補完する。
  // Gemini には「何を描くか（被写体・シーン）」だけを英語で出させ、アートスタイルは
  // THUMBNAIL_STYLE で決め打ちして付与する。こうするとモデルのブレに関係なく
  // 全記事で一貫した「知的でクール」なトーンになる。
  let sceneText: string;
  try {
    const pResult = await getGenAI().models.generateContent({
      model: GEMINI_MODEL,
      contents: [{
        role: "user",
        parts: [{ text: [
          "You are an art director for a stylish news app aimed at smart Japanese pre-teens",
          "(ages 10-12) who are preparing for junior-high entrance exams.",
          "Describe ONE specific, visually striking scene or a single symbolic object that",
          "best represents the news article below.",
          `Article category: ${category}`,
          `Article title: ${title}`,
          `Article summary: ${tagline}`,
          ...(interestHint
            ? [`This reader is especially fascinated by: ${interestHint}. ` +
               "If the article naturally connects to that interest, choose a scene that " +
               "highlights the connection; otherwise ignore this hint."]
            : []),
          "Rules: describe only the concrete visual subject (people, objects, setting, action).",
          "Do NOT mention any art style, colour, medium, or the words 'child'/'kids'.",
          "Output only the scene description in English (max 40 words). No explanation, no quotes.",
        ].join("\n") }],
      }],
      config: { temperature: 0.8 },
    });
    sceneText = (pResult.text ?? "").trim();
    if (!sceneText) throw new Error("empty");
  } catch {
    sceneText = `A single symbolic scene that represents this news: ${title}. ${tagline}.`;
  }
  const promptText = `${sceneText} ${THUMBNAIL_STYLE}`;

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
  const file = bucket.file(storageObjectPath);
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

  const encodedPath = encodeURIComponent(storageObjectPath);
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

    const db = getFirestore();
    // 保護者ダイジェスト（sendParentDigest）用に「本日利用」を記録する。
    // 短時間のバウンスでも「アプリを使った」ことに変わりはないため、除外判定より前に刻む。
    await db.collection("users").doc(uid).set(
      { last_active_at: Timestamp.now() },
      { merge: true },
    );

    // ── 早期バウンス除外（Firestore 読み取り前の軽量チェック）─────────────────
    // T_EXP_FALLBACK_SEC × 0.2 = 9秒未満は記事の長さに関わらず確実にバウンス。
    if (viewDurationSeconds < T_EXP_FALLBACK_SEC * 0.2) {
      logger.info(`updateInterestModel: early bounce (${viewDurationSeconds}s), skip`, { newsId });
      return;
    }

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
    // 旧スキーマ記事（interest_context にニュースソース名が入っていたもの）が
    // まだ news_pool に残っていた場合の保険。TOPIC_CATEGORIES に無い値は
    // 興味スコアとして書き込まない（ソース名の学習を防ぐ）。
    if (!(TOPIC_CATEGORIES as readonly string[]).includes(category)) {
      logger.warn("updateInterestModel: non-topic interest_context, skip", {
        newsId, category,
      });
      return;
    }
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
