import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';

/// 起動時のログイン画面。
///
/// 未ログイン時に GoRouter の redirect で表示される。
/// Google ログインを主導線とし、開発・お試し用にゲスト（匿名）も用意する。
/// ログインに成功すると authStateChanges 経由でルーターが本編へ遷移させる。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      // 成功時の画面遷移はルーターの redirect が担うため、ここでは何もしない。
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('ログインに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 64, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'AI Discovery\nLearning App',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'はじめるにはログインしてください',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed:
                      _busy ? null : () => _run(auth.signInWithGoogle),
                  icon: const Icon(Icons.login),
                  label: const Text('Google でログイン'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : () => _run(auth.signInAsGuest),
                  child: const Text('ゲストで試す'),
                ),
                const SizedBox(height: 24),
                if (_busy) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
