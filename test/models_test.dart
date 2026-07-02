// Firestore ドキュメント → Freezed モデルの変換テスト。
//
// Cloud Functions 側のスキーマ変更（フィールド追加・欠落）でアプリが落ちないこと、
// TimestampConverter が複数の入力型を受けることを保証する。

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/shared/models/converters.dart';
import 'package:flutter_application_1/shared/models/news_pool.dart';
import 'package:flutter_application_1/shared/models/personalized_feed_item.dart';

void main() {
  group('NewsPool.fromJson', () {
    test('必須フィールドのみで生成でき、オプションは既定値になる', () {
      final pool = NewsPool.fromJson({
        'original_title': 'タイトル',
        'published_at': '2026-06-16T00:00:00Z',
        'parent_summary': '・要約',
        'child_body_with_ruby': '〔環境｜かんきょう〕の話',
      });

      expect(pool.originalTitle, 'タイトル');
      expect(pool.newsId, '');
      expect(pool.displayTitle, '');
      expect(pool.interestContext, 'ニュース');
      expect(pool.thumbnailConfig.mode, ThumbnailMode.textOverlay);
    });

    test('未知のフィールド（quality_review 等）は無視される', () {
      final pool = NewsPool.fromJson({
        'original_title': 'タイトル',
        'published_at': '2026-06-16T00:00:00Z',
        'parent_summary': '',
        'child_body_with_ruby': '',
        'quality_review': {'verdict': 'approved'},
        'source_name': 'NHK ニュース',
      });

      expect(pool.originalTitle, 'タイトル');
    });
  });

  group('ThumbnailConfig.fromJson', () {
    test('generated モードと URL を読み取る', () {
      final config = ThumbnailConfig.fromJson({
        'mode': 'generated',
        'base_asset': '',
        'optional_generated_url': 'https://firebasestorage.googleapis.com/x',
      });

      expect(config.mode, ThumbnailMode.generated);
      expect(config.optionalGeneratedUrl, startsWith('https://'));
    });

    test('空マップは text_overlay 既定値になる', () {
      final config = ThumbnailConfig.fromJson({});

      expect(config.mode, ThumbnailMode.textOverlay);
      expect(config.baseAsset, '');
      expect(config.optionalGeneratedUrl, '');
    });
  });

  group('PersonalizedFeedItem.fromJson', () {
    test('テレメトリの既定値（未閲覧・0秒）が入る', () {
      final item = PersonalizedFeedItem.fromJson({
        'news_id': 'news_abc',
        'interest_context': 'Science',
        'display_title': 'タイトル',
        'display_tagline': 'タグライン',
        'thumbnail_config': {'mode': 'text_overlay'},
      });

      expect(item.isViewed, false);
      expect(item.viewDurationSeconds, 0);
    });
  });

  group('TimestampConverter', () {
    const converter = TimestampConverter();

    test('Timestamp / ISO文字列 / エポックms を DateTime に変換する', () {
      final date = DateTime.utc(2026, 6, 16);

      // Timestamp.toDate() はローカルタイムで返るため UTC に揃えて比較する
      expect(converter.fromJson(Timestamp.fromDate(date)).toUtc(), date);
      expect(converter.fromJson('2026-06-16T00:00:00Z'), date);
      expect(
        converter.fromJson(date.millisecondsSinceEpoch),
        DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch),
      );
    });

    test('未対応の型は ArgumentError', () {
      expect(() => converter.fromJson(1.5), throwsArgumentError);
    });

    test('toJson は Firestore Timestamp に戻す', () {
      final date = DateTime.utc(2026, 6, 16);
      final json = converter.toJson(date);

      expect(json, isA<Timestamp>());
      expect((json as Timestamp).toDate().toUtc(), date);
    });
  });
}
