import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

late DatabaseReference ref;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  ref = FirebaseDatabase.instance.ref();

  runApp(const MaterialApp(
    home: StudyApp(),
  ));
}

class StudyApp extends StatefulWidget {
  const StudyApp({super.key});

  @override
  State<StudyApp> createState() => _StudyAppState();
}

class _StudyAppState extends State<StudyApp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // インスタンス化して利用します
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Google認証フローを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // ユーザーがサインインをキャンセルした場合
        return null;
      }

      // 2. リクエストから認証詳細を取得
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Firebase用の新しいクレデンシャルを作成
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebaseにサインイン
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      log("Googleサインインエラー: $e");
      return null;
    }
  }

  Future<void> signOutWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      log("Googleサインアウトエラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study App'),
        centerTitle: true,
        backgroundColor: Colors.lightBlue[200],
      ),
      body: Center(
        child: OutlinedButton(
          child: const Text('Send date'),
          onPressed: () async {
            final user = _auth.currentUser;
            if (user != null) {
              await ref.child("users/${user.uid}").set({
                "uid": user.uid,
                "email": user.email,
                "online": true,
              });
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(
          currentUser != null ? Icons.logout : Icons.login,
        ),
        onPressed: () async {
          if (_auth.currentUser != null) {
            await signOutWithGoogle();
          } else {
            await signInWithGoogle();
          }
          setState(() {});
        },
      ),
    );
  }
}