import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 56,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'StudyApp',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '勉強をもっと楽しく。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        await authService.signInWithGoogle();
                      },
                      child: const Text('Googleでログイン'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}