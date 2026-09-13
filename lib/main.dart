import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: StudyApp(),
    ),
  );
}

class StudyApp extends StatefulWidget {
  const StudyApp({super.key});

  @override
  State<StudyApp> createState() => _StudyAppState();
}

class _StudyAppState extends State<StudyApp>
    with WidgetsBindingObserver {
  final databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    updateUserStatus();
  }

  Future<void> updateUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await databaseService.ensureUser(user);
      await databaseService.setOnline(user.uid);
    } catch (e) {
      debugPrint('ユーザー情報の確認エラー: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      updateUserStatus();
    }

    if (state == AppLifecycleState.paused) {
      databaseService.setOffline(user.uid);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final router = ref.watch(appRouterProvider);

        return MaterialApp.router(
          routerConfig: router,
        );
      },
    );
  }
}