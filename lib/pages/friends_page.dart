import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final databaseService = DatabaseService();

  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> requests = [];

  final Map<String, bool> onlineStatus = {};
  final Map<String, StreamSubscription<bool>> subscriptions = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final resultFriends =
          await databaseService.getFriends(user.uid);

      final resultRequests =
          await databaseService.getFriendRequests(user.uid);

      // 古い監視を解除
      for (final subscription in subscriptions.values) {
        await subscription.cancel();
      }

      subscriptions.clear();
      onlineStatus.clear();

      // 各フレンドのonlineをリアルタイム監視
      for (final friend in resultFriends) {
        final friendUid = friend['uid'] as String;

        subscriptions[friendUid] =
            databaseService.onlineStream(friendUid).listen(
          (online) {
            if (!mounted) return;

            setState(() {
              onlineStatus[friendUid] = online;
            });
          },
        );
      }

      if (!mounted) return;

      setState(() {
        friends = resultFriends;
        requests = resultRequests;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('読み込みエラー: $e'),
        ),
      );
    }
  }

  Future<void> acceptRequest(String senderUid) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await databaseService.acceptFriendRequest(
        myUid: myUid,
        senderUid: senderUid,
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('承認エラー: $e'),
        ),
      );
    }
  }

  Future<void> rejectRequest(String senderUid) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await databaseService.rejectFriendRequest(
        myUid: myUid,
        senderUid: senderUid,
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('拒否エラー: $e'),
        ),
      );
    }
  }

  Future<void> removeFriend(String friendUid) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await databaseService.removeFriend(
        myUid: myUid,
        friendUid: friendUid,
      );

      await loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('削除エラー: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final subscription in subscriptions.values) {
      subscription.cancel();
    }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド'),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '友達申請',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (requests.isEmpty)
              const Text('友達申請はありません'),

            ...requests.map((request) {
              final senderUid = request['uid'] as String;
              final name = request['name'] ?? '';
              final photoURL = request['photoURL'] ?? '';

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
                subtitle: const Text('友達申請'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        acceptRequest(senderUid);
                      },
                      child: const Text('承認'),
                    ),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () {
                        rejectRequest(senderUid);
                      },
                      child: const Text('拒否'),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),

            const Text(
              'フレンド',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (friends.isEmpty)
              const Text('フレンドはいません'),

            ...friends.map((friend) {
              final friendUid = friend['uid'] as String;
              final name = friend['name'] ?? '';
              final photoURL = friend['photoURL'] ?? '';

              final online =
                  onlineStatus[friendUid] ??
                  friend['online'] ??
                  false;

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
                subtitle: Text(
                  online ? 'オンライン' : 'オフライン',
                ),
                trailing: TextButton(
                  onPressed: () {
                    removeFriend(friendUid);
                  },
                  child: const Text('削除'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}