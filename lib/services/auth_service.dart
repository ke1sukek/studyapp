import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final DatabaseService _databaseService;

  AuthService({
    FirebaseAuth? auth,
    DatabaseService? databaseService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _databaseService = databaseService ?? DatabaseService();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    log('Googleログイン開始');

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      log('Googleアカウント選択を開始');

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      log('Googleアカウント選択終了');

      if (googleUser == null) {
        log('Googleログインがキャンセルされました');
        return null;
      }

      log('Googleアカウント取得: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      log('Google認証情報取得完了');

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      log('Firebaseログイン開始');

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User user = userCredential.user!;

      log('Firebaseログイン完了: ${user.uid}');

      await _databaseService.ensureUser(user);

      await _databaseService.setOnline(user.uid);

      log('オンライン状態を設定しました');
      log('ログイン成功: ${user.uid}');

      return userCredential;
    } catch (e, stackTrace) {
      log(
        'Googleログインエラー: $e',
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        await _databaseService.setOffline(user.uid);
      }

      // Firebaseからログアウト
      await _auth.signOut();

      // Googleからもログアウト
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      log('ログアウト成功');
    } catch (e, stackTrace) {
      log(
        'ログアウトエラー: $e',
        stackTrace: stackTrace,
      );
    }
  }
}