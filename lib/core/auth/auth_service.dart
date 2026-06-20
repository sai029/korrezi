import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_providers.dart';

/// 認証操作（サインイン/サインアウト）をまとめたサービス。
///
/// Google ログインは `firebase_auth` の [FirebaseAuth.signInWithProvider] を使う
/// （`google_sign_in` パッケージ不要。Android は Custom Tab、iOS は SFSafari 経由）。
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  /// Google アカウントでサインインする。
  ///
  /// ユーザーがフローをキャンセルした場合は例外（`web-context-canceled` 等）に
  /// なり得るため、呼び出し側で握りつぶす。
  Future<UserCredential> signInWithGoogle() {
    final provider = GoogleAuthProvider()..addScope('email');
    return _auth.signInWithProvider(provider);
  }

  /// ゲスト（匿名）として続行する。
  Future<UserCredential> signInAsGuest() => _auth.signInAnonymously();

  /// サインアウトする。
  Future<void> signOut() => _auth.signOut();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(authProvider)),
);
