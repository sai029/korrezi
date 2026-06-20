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

/// 現在のユーザー ID を解決する。
///
/// Firebase が利用可能なら匿名サインインして uid を返す。
/// 初期化失敗・匿名認証無効などの場合は [devUserId] にフォールバックする。
final currentUserIdProvider = FutureProvider<String>((ref) async {
  if (!ref.watch(firebaseReadyProvider)) return devUserId;
  try {
    final auth = ref.watch(authProvider);
    final user =
        auth.currentUser ?? (await auth.signInAnonymously()).user;
    return user?.uid ?? devUserId;
  } catch (_) {
    // 匿名認証が無効、ネットワーク不通などは開発用 ID で続行。
    return devUserId;
  }
});
