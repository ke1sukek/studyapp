import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final DatabaseService _databaseService;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    DatabaseService? databaseService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _databaseService =
            databaseService ?? DatabaseService();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User user = userCredential.user!;

      final userData =
          await _databaseService.getUser(user.uid);

      if (userData == null) {
        await _databaseService.createUser(
          uid: user.uid,
          name: user.displayName ?? '',
          photoURL: user.photoURL ?? '',
        );

        log('ユーザーデータを作成しました: ${user.uid}');
      }

      // ログインしたのでオンライン
      await _databaseService.setOnline(user.uid);

      log('ログイン成功: ${user.uid}');

      return userCredential;
    } catch (e) {
      log('Googleログインエラー: $e');

      return null;
    }
  }

  Future<void> signOut() async {
  try {
    final user = _auth.currentUser;

    if (user != null) {
      // 3秒以上応答がない場合はタイムアウトしてログアウト処理へ進める
      await _databaseService.setOffline(user.uid).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          log('setOffline がタイムアウトしました');
        },
      );
    }

    await _googleSignIn.signOut();
    await _auth.signOut();

    log('ログアウト成功');
  } catch (e) {
    log('ログアウトエラー: $e');
  }
  }
}