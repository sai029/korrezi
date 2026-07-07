import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../device/device_role.dart';
import '../firebase/firebase_providers.dart';
import '../router/app_router.dart';

/// バックグラウンド/終了状態でメッセージを受けるためのトップレベルハンドラ。
///
/// アプリが前面に無い状態で別 isolate から呼ばれるため、ここでは**ナビゲーションしない**
/// （通知タップ時の遷移は onMessageOpenedApp / getInitialMessage 側が担う）。
/// 通知メッセージの表示は OS の通知トレイが行う。
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// FCM（Push 通知）の初期化・トークン管理・通知タップのディープリンク遷移を担うサービス。
///
/// 「通知を送る側」（どの契機で何を通知するか）はバックエンド（Cloud Functions）の責務で、
/// ここは**受信とルーティング**に専念する。通知の data ペイロード契約は以下:
///
/// ```json
/// { "type": "article", "news_id": "<newsId>" }
/// ```
///
/// これを受け取ると `/common/article/<newsId>` へ遷移する。
class FcmService {
  FcmService(this._ref);

  final Ref _ref;

  bool _initialized = false;
  String? _lastToken;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  /// FCM を初期化する。多重呼び出し・非対応環境では安全に no-op となる。
  Future<void> init() async {
    if (_initialized) return;
    // Web は Service Worker + VAPID 鍵が別途必要なため当面スキップ（docs/PENDING_ACTIONS.md）。
    if (kIsWeb) return;
    // Firebase 未初期化（テスト/未設定環境）では触れない。
    if (!_ref.read(firebaseReadyProvider)) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    // 通知許可（Android 13+ / iOS はダイアログ表示）。拒否されても以降は無害。
    await messaging.requestPermission();

    // バックグラウンド/終了状態のメッセージ処理を登録。
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

    // トークン取得・保存と、ローテーション購読。
    _lastToken = await messaging.getToken();
    final token = _lastToken;
    if (token != null) await _saveToken(token);
    _tokenSub = messaging.onTokenRefresh.listen((t) {
      _lastToken = t;
      _saveToken(t);
    });

    // フォアグラウンド受信（当面はログのみ。将来アプリ内バナー等に拡張可能）。
    FirebaseMessaging.onMessage.listen((m) {
      debugPrint('FCM foreground: ${m.notification?.title ?? m.messageId}');
    });

    // バックグラウンドから通知タップで復帰したとき。
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleDeepLink);

    // 終了状態から通知タップで起動したとき（初回メッセージ）。
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleDeepLink(initial);
  }

  /// サインイン確定時に呼ぶ。未ログイン中に取得したトークンをユーザーへ紐付け直す。
  void onSignedIn() {
    final token = _lastToken;
    if (token != null) _saveToken(token);
  }

  /// 端末の役割（保護者/お子さん）が変わったときに呼ぶ。
  /// 保存済みトークンの `role` を新しい役割で書き直し、通知の出し分けに反映する。
  void onRoleChanged() {
    final token = _lastToken;
    if (token != null) _saveToken(token);
  }

  /// トークンを `users/{uid}/fcm_tokens/{token}` に保存する。
  ///
  /// トークン単位のドキュメントにすることで、複数端末・失効トークンの管理を
  /// バックエンド（送信側）が扱いやすくする。`role`（parent/child）は通知の
  /// 出し分けに使う（未設定の間は書き込まない）。
  Future<void> _saveToken(String token) async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid == devUserId) return; // 未サインインでは保存しない
    try {
      final data = <String, Object>{
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updated_at': FieldValue.serverTimestamp(),
      };
      final role = _ref.read(deviceRoleProvider)?.name;
      if (role != null) data['role'] = role;
      await _ref
          .read(firestoreProvider)
          .collection('users')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  /// data ペイロードからディープリンクを解決して遷移する。
  ///
  /// 契約（バックエンド index.ts と一致させること）:
  /// - `{ type: "article", news_id: "<id>" }` → 記事詳細 `/common/article/<id>`
  /// - `{ type: "feed" }`                     → 子どもフィード `/child`（通知①・新着記事）
  /// - `{ type: "parent_digest" }`            → 保護者ダッシュボード `/parent`（通知②・日次）
  void _handleDeepLink(RemoteMessage message) {
    final data = message.data;
    final router = _ref.read(appRouterProvider);
    switch (data['type']) {
      case 'article':
        final newsId = (data['news_id'] ?? data['newsId'] ?? '').toString();
        if (newsId.isNotEmpty) router.go('/common/article/$newsId');
        break;
      case 'feed':
        router.go('/child');
        break;
      case 'parent_digest':
        router.go('/parent');
        break;
    }
  }

  void dispose() {
    _tokenSub?.cancel();
    _openedSub?.cancel();
  }
}

/// [FcmService] のプロバイダ。
///
/// サインイン状態の変化を購読し、確定時にトークンを保存し直す
/// （未ログイン中に取得したトークンを、ログイン後のユーザーへ紐付けるため）。
final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService(ref);
  ref.listen(authStateProvider, (_, next) {
    if (next.valueOrNull != null) service.onSignedIn();
  });
  ref.onDispose(service.dispose);
  return service;
});
