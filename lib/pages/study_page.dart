import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage>
    with WidgetsBindingObserver {
  final databaseService = DatabaseService();

  Timer? timer;

  int sessionSeconds = 0;
  int todaySeconds = 0;
  int totalSeconds = 0;
  int streak = 0;

  String lastStudyDate = '';

  bool isStudying = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    loadData();
  }

  Future<void> loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final data = await databaseService.getUser(uid);

    if (data == null || !mounted) return;

    setState(() {
      todaySeconds = data['todaySeconds'] ?? 0;
      totalSeconds = data['totalSeconds'] ?? 0;
      streak = data['streak'] ?? 0;
      lastStudyDate = data['lastStudyDate'] ?? '';
    });
  }

  void startTimer() {
    if (isStudying) return;

    setState(() {
      isStudying = true;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {
          sessionSeconds++;
          todaySeconds++;
          totalSeconds++;
        });

        if (todaySeconds % 30 == 0) {
          saveData();
        }
      },
    );
  }

  Future<void> saveData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final now = DateTime.now();

    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    lastStudyDate = date;

    await databaseService.updateStudyData(
      uid: uid,
      totalSeconds: totalSeconds,
      todaySeconds: todaySeconds,
      lastStudyDate: lastStudyDate,
    );
  }

  Future<void> stopTimer() async {
    timer?.cancel();
    timer = null;

    setState(() {
      isStudying = false;
    });

    await saveData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (isStudying) {
        stopTimer();
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = sessionSeconds ~/ 60;
    final seconds = sessionSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('勉強'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isStudying ? stopTimer : startTimer,
              child: Text(
                isStudying ? '停止' : '開始',
              ),
            ),
          ],
        ),
      ),
    );
  }
}