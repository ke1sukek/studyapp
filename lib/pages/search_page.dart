import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final databaseService = DatabaseService();
  final controller = TextEditingController();

  List<Map<String, dynamic>> users = [];
  bool isLoading = false;

  Future<void> search() async {
    final keyword = controller.text.trim();

    if (keyword.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await databaseService.searchUsers(keyword);

      if (!mounted) return;

      setState(() {
        users = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('検索エラー: $e'),
        ),
      );
    }
  }

  Future<void> sendRequest(String receiverUid) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインしてください'),
        ),
      );
      return;
    }

    final myUid = user.uid;

    if (myUid == receiverUid) {
      return;
    }

    try {
      // 自分のユーザーデータが存在することを確認
      await databaseService.ensureUser(user);

      // 友達申請を送信
      await databaseService.sendFriendRequest(
        senderUid: myUid,
        receiverUid: receiverUid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('友達申請を送りました'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('申請エラー: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー検索'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: '名前を入力',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: search,
                  child: const Text('検索'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(),

            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];

                  final uid = user['uid'] as String;
                  final name = user['name'] ?? '';
                  final photoURL = user['photoURL'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: photoURL.isNotEmpty
                          ? NetworkImage(photoURL)
                          : null,
                      child: photoURL.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(name),
                    trailing: ElevatedButton(
                      onPressed: () => sendRequest(uid),
                      child: const Text('申請'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}