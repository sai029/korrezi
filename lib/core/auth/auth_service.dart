import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  Future<UserCredential> signInWithGoogle() async {
    // Web: ポップアップフロー。
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      return _auth.signInWithPopup(provider);
    }
    // Android/iOS: ネイティブ Google Sign-In フロー。
    // signInWithProvider はリダイレクト方式でセッション状態が失われるため使わない。
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google サインインがキャンセルされました。',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// ゲスト（匿名）として続行する。
  Future<UserCredential> signInAsGuest() => _auth.signInAnonymously();

  /// サインアウトする。
  Future<void> signOut() => _auth.signOut();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(authProvider)),
);
