import { createHash } from "node:crypto";

import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

initializeApp();

// Firestore と同じ東京リージョンで動かす。
setGlobalOptions({ region: "asia-northeast1" });

// GNews.io の API キー。`firebase functions:secrets:set GNEWS_API_KEY` で登録する。
const GNEWS_API_KEY = defineSecret("GNEWS_API_KEY");

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

/**
 * GNews から日本語トップ記事を取得し、Firestore へ「生記事のまま」書き込む。
 *
 * - `/news_pool/{id}`                     … 全ユーザー共通の元記事
 * - `/users/{uid}/personalized_feed/{id}` … 呼び出しユーザー向けフィード
 *
 * 子ども向け変換（ルビ付与等）は後フェーズの Gemini パイプラインで行う。
 */
export const fetchNews = onCall(
  { secrets: [GNEWS_API_KEY] },
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

    const db = getFirestore();
    const batch = db.batch();

    for (const a of articles) {
      const id = newsIdFromUrl(a.url);

      // /news_pool/{id} … firestore_seeder と同じ snake_case スキーマ。
      batch.set(db.collection("news_pool").doc(id), {
        original_title: a.title,
        published_at: Timestamp.fromDate(new Date(a.publishedAt)),
        parent_summary: a.description ?? "",
        // ルビ markup は付けず、本文（無ければ概要）をそのまま入れる。
        child_body_with_ruby: a.content ?? a.description ?? "",
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
          display_title: a.title,
          display_tagline: toTagline(a.description),
          thumbnail_config: thumbnailConfig,
          is_viewed: false,
          view_duration_seconds: 0,
        },
      );
    }

    await batch.commit();
    logger.info(`fetchNews wrote ${articles.length} articles for ${uid}`);
    return { count: articles.length };
  },
);
