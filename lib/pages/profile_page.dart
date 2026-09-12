import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final databaseService = DatabaseService();
  final authService = AuthService();

  final nameController = TextEditingController();

  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    loadUser();
  }

  Future<void> loadUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final userData = await databaseService.getUser(user.uid);

      if (!mounted) return;

      if (userData != null) {
        nameController.text = userData['name'] ?? '';
      } else {
        nameController.text = user.displayName ?? '';
      }
    } catch (e) {
      if (!mounted) return;

      nameController.text = user.displayName ?? '';
    }
  }

  Future<void> updateName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ニックネームを入力してください'),
        ),
      );
      return;
    }

    try {
      await databaseService.updateName(
        uid: user.uid,
        name: name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ニックネームを変更しました'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('変更エラー: $e'),
        ),
      );
    }
  }

  Future<void> logout() async {
    if (isLoggingOut) {
      return;
    }

    setState(() {
      isLoggingOut = true;
    });

    try {
      await authService.signOut();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ログアウトエラー: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ニックネーム',
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: isLoggingOut ? null : updateName,
              child: const Text('変更'),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoggingOut ? null : logout,
              child: isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('ログアウト'),
            ),
          ],
        ),
      ),
    );
  }
}