import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase 初期化が成功したかどうか。
///
/// 実値は `main.dart` の `ProviderScope.overrides` で注入する。
/// 既定は `false`（テストや初期化失敗時はサンプルデータで動作させるため）。
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Cloud Firestore インスタンス。
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Firebase Auth インスタンス。
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Firebase/Auth が使えないときに使うローカル開発用のユーザー ID。
const String devUserId = 'dev_local_user';

/// 認証状態（サインイン中のユーザー）を購読する。
///
/// Firebase 未初期化時は常に null を流す（FirebaseAuth に触れない）。
final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) {
    return Stream<User?>.value(null);
  }
  return ref.watch(authProvider).authStateChanges();
});

/// 現在のユーザー ID を解決する。
///
/// サインイン中ならその uid。未サインイン・Firebase 未初期化時は [devUserId]。
/// （サインインは [authStateProvider] / ログイン画面が担う。ここでは自動認証しない）
final currentUserIdProvider = Provider<String>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return devUserId;
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.uid ?? devUserId;
});
