import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/device/device_role.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/bouncy_tap.dart';

/// オンボーディング（初回起動）: この端末を「保護者用」「お子さん用」のどちらで
/// 使うかを選ぶ画面。
///
/// 家族は 1 つの Google アカウントを共有し、端末ごとに役割を決める。選んだ役割は
/// ローカルに保存され、以降その端末は対応する画面（保護者=/parent, お子さん=/child）
/// を起点に表示し、通知もその役割に合わせて届く。役割は設定（ドロワー）から変更できる。
class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  bool _busy = false;

  Future<void> _choose(DeviceRole role) async {
    if (_busy) return;
    setState(() => _busy = true);
    // 役割を保存すると deviceRoleProvider が更新され、GoRouter の
    // refreshListenable 経由で redirect が対応する画面へ誘導する。
    await ref.read(deviceRoleProvider.notifier).setRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.waving_hand,
                      size: 56,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'この端末はどなたが\nつかいますか？',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mPlusRounded1c(
                        fontSize: AppType.sizeHeadline,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '保護者の方とお子さんで端末を分けて使えます。\nあとから設定で変更できます。',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space7),
                    _RoleCard(
                      icon: Icons.family_restroom,
                      title: 'お子さん用',
                      subtitle: 'ニュースフィードを見る端末',
                      onTap: _busy ? null : () => _choose(DeviceRole.child),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    _RoleCard(
                      icon: Icons.shield_moon_outlined,
                      title: '保護者用',
                      subtitle: 'お子さんの学びを見守る端末',
                      onTap: _busy ? null : () => _choose(DeviceRole.parent),
                    ),
                    const SizedBox(height: AppSpacing.space5),
                    if (_busy)
                      const CircularProgressIndicator(
                        color: AppColors.brandPrimary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 役割を選ぶ大きめのカード（BouncyTap 付き）。
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.lg,
          border: Border.all(color: AppColors.ink300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: AppColors.brandPrimary),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.mPlusRounded1c(
                      fontSize: AppType.sizeTitle,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.ink500),
          ],
        ),
      ),
    );
  }
}
