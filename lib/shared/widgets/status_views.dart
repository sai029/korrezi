import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'bouncy_tap.dart';

/// 読み込み失敗時の共通エラービュー（再試行ボタン付き）。
///
/// AsyncValue.when の error ブランチで使う。子ども向けに原因の生文字列は見せず、
/// やさしいメッセージ + 再試行導線に統一する（詳細はコンソールログで確認する）。
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    this.message = 'よみこみに しっぱいしたよ',
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      icon: Icons.cloud_off,
      iconColor: AppColors.brandPrimary,
      message: message,
      action: BouncyTap(
        onTap: onRetry,
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('もういちど'),
        ),
      ),
    );
  }
}

/// データが空のときの共通空状態ビュー。
///
/// 「何もない」で終わらせず、次にとれる行動（ニュース取得など）を案内する。
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    this.message = 'まだ きじが ないよ',
    this.hint,
    this.onRetry,
  });

  final String message;

  /// 次の行動の案内（例: 「メニューの「ニュース取得」をおしてね」）。
  final String? hint;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      icon: Icons.auto_stories_outlined,
      iconColor: AppColors.accent,
      message: message,
      hint: hint,
      action: onRetry == null
          ? null
          : BouncyTap(
              onTap: onRetry,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('もういちど'),
              ),
            ),
    );
  }
}

/// サンプルデータ表示中であることを知らせるバナー。
///
/// 本アプリはエラー時にサンプル記事へ静かにフォールバックするため、
/// 「本番障害がサンプル表示に化けて気づけない」事故を防ぐ目的で必ず可視化する。
class SampleDataBanner extends StatelessWidget {
  const SampleDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warning,
        borderRadius: AppRadii.pill,
        border: Border.fromBorderSide(AppBorder.sideThin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.science_outlined,
              size: AppType.sizeLabel, color: AppColors.accentInk),
          const SizedBox(width: AppSpacing.space1),
          Text(
            'サンプルきじを ひょうじちゅう',
            style: textTheme.labelMedium?.copyWith(color: AppColors.accentInk),
          ),
        ],
      ),
    );
  }
}

/// エラー/空状態カードの共通レイアウト（レトロモダン: 太ボーダー + 影なし）。
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.hint,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String message;
  final String? hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.space5),
        padding: const EdgeInsets.all(AppSpacing.space5),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.lg,
          border: Border.fromBorderSide(AppBorder.sideBase),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.space7, color: iconColor),
            const SizedBox(height: AppSpacing.space3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: AppColors.ink900),
            ),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.ink500),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.space4),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
