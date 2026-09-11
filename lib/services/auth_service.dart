import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // 現在ログインしているユーザー
  User? get currentUser => _auth.currentUser;

  // Googleログイン
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Googleログイン画面
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      // キャンセル
      if (googleUser == null) {
        return null;
      }

      // Googleの認証情報
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase用Credential
      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseへログイン
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      log('ログイン成功: ${userCredential.user?.uid}');

      return userCredential;
    } catch (e) {
      log('Googleログインエラー: $e');
      return null;
    }
  }

  // ログアウト
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      log('ログアウト成功');
    } catch (e) {
      log('ログアウトエラー: $e');
    }
  }
}