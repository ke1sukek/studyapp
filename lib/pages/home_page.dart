import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final databaseService = DatabaseService();

  Map? userData;
  bool isLoading = true;
  String? errorMessage;

  StreamSubscription<Map?>? userSubscription;

  @override
  void initState() {
    super.initState();
    listenUser();
  }

  void listenUser() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        errorMessage = 'ログインユーザーがいません';
        isLoading = false;
      });
      return;
    }

    userSubscription =
        databaseService.userStream(user.uid).listen(
      (data) {
        if (!mounted) return;

        if (data == null) {
          setState(() {
            errorMessage = 'ユーザーデータが見つかりません';
            isLoading = false;
          });
          return;
        }

        setState(() {
          userData = data;
          errorMessage = null;
          isLoading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          errorMessage = error.toString();
          isLoading = false;
        });
      },
    );
  }

  String formatStudyTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '$hours時間$minutes分';
      }

      return '$hours時間';
    }

    if (minutes > 0) {
      if (remainingSeconds > 0) {
        return '$minutes分$remainingSeconds秒';
      }

      return '$minutes分';
    }

    return '$remainingSeconds秒';
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(errorMessage!),
        ),
      );
    }

    final todaySeconds = userData!['todaySeconds'] ?? 0;
    final totalSeconds = userData!['totalSeconds'] ?? 0;
    final streak = userData!['streak'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'こんにちは、${userData!['name']}',
              style: const TextStyle(
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              '今日の勉強時間',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            Text(
              formatStudyTime(todaySeconds),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              '総勉強時間',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            Text(
              formatStudyTime(totalSeconds),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              '連続学習',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            Text(
              '$streak日',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}