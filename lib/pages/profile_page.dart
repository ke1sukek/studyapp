import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: authState.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        error: (error, stackTrace) {
          return Center(
            child: Text('エラー: $error'),
          );
        },

        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインしていません'),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.displayName ?? '名前なし',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  user.email ?? 'メールなし',
                ),

                const SizedBox(height: 10),

                Text(
                  'UID: ${user.uid}',
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(authServiceProvider)
                        .signOut();
                  },
                  child: const Text('ログアウト'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}