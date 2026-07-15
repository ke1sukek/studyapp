import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

late DatabaseReference ref;

void main()async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(//firebaseへの接続
    options: DefaultFirebaseOptions.currentPlatform,
  );

ref = FirebaseDatabase.instance.ref();

await GoogleSignIn.instance.initialize();

  runApp (const MaterialApp(
    home:StudyApp()
  ));
}

class StudyApp extends StatefulWidget {
  const StudyApp({super.key});

  @override
  State<StudyApp> createState() => _StudyAppState();
}

class _StudyAppState extends State<StudyApp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;//Firebase Authインスタンス
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;//GoogleSignInインスタンス

  Future<UserCredential?> signInWithGoogle()async{
  try {
    final GoogleSignInAccount googleUser =
        await _googleSignIn.authenticate();

    final GoogleSignInClientAuthorization? authorization =
        await googleUser.authorizationClient.authorizationForScopes(
      ['email'],
    );

    if (authorization == null) {
      return null;
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: authorization.accessToken,
    );

    return await _auth.signInWithCredential(credential);
  } catch (e) {
    log("Googleサインインエラー: $e");
    return null;
  }
}

  Future<void> signOutWithGoogle()async{
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      log("Googleサインアウトエラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text('Study App'),
        centerTitle: true,
        backgroundColor: Colors.lightBlue[200],
      ),
      body: Center(
        child: OutlinedButton(
          child: const Text('Send date'),
          onPressed: ()async{
            if(FirebaseAuth.instance.currentUser!=null){
            await ref.child("users/${FirebaseAuth.instance.currentUser!.uid}").set({
            "uid":FirebaseAuth.instance.currentUser!.uid,
            "email":FirebaseAuth.instance.currentUser!.email,
            "online":true,
            });}
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(
          FirebaseAuth.instance.currentUser!=null//三項演算子条件
          ? Icons.logout//真
          : Icons.login,//偽
        ),
        onPressed: ()async{
          if(FirebaseAuth.instance.currentUser!=null){
            await signOutWithGoogle();
            setState((){});
          }else{
            await signInWithGoogle();
            setState((){});
          }
        }),
    );
  }
}