import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/bouncy_tap.dart';

/// 起動時のログイン画面。
///
/// 未ログイン時に GoRouter の redirect で表示される。
/// Google ログインを主導線とし、開発・お試し用にゲスト（匿名）も用意する。
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ブランドアイコン: brandPrimary, 64px
                const Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(height: AppSpacing.space4),
                // ロゴ: M PLUS Rounded 1c
                Text(
                  'AI Discovery\nLearning App',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: AppType.sizeHeadline,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'はじめるにはログインしてください',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space7),
                // Google ログインボタン（Primary 仕様 + BouncyTap）
                BouncyTap(
                  onTap: _busy ? null : () => _run(auth.signInWithGoogle),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _run(auth.signInWithGoogle),
                      icon: const Icon(Icons.login),
                      label: const Text('Google でログイン'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                TextButton(
                  onPressed: _busy ? null : () => _run(auth.signInAsGuest),
                  child: const Text('ゲストで試す'),
                ),
                const SizedBox(height: AppSpacing.space5),
                if (_busy) const CircularProgressIndicator(
                  color: AppColors.brandPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
