import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/device/device_role.dart';
import '../../core/theme/tokens.dart';

/// 3画面を束ねる下部ナビゲーションバーのシェル。
/// GoRouter の StatefulShellRoute.indexedStack と組み合わせて使用する。
///
/// 子ども端末（[DeviceRole.child]）では保護者向けの「ようす」タブを隠す。
/// タブの並びは可変になるため、表示タブの visual index と GoRouter のブランチ
/// index（0:/child, 1:/common, 2:/parent）を相互変換して扱う。
class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChild = ref.watch(deviceRoleProvider) == DeviceRole.child;

    // (branch index, 表示先). branch は StatefulShellRoute のブランチ順に対応。
    final tabs = <({int branch, NavigationDestination destination})>[
      (
        branch: 0,
        destination: const NavigationDestination(
          icon: Icon(Icons.dynamic_feed_outlined),
          selectedIcon: Icon(Icons.dynamic_feed),
          label: 'フィード',
        ),
      ),
      (
        branch: 1,
        destination: const NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'いっしょに',
        ),
      ),
      // 「ようす」は保護者向け。子ども端末では出さない。
      if (!isChild)
        (
          branch: 2,
          destination: const NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'ようす',
          ),
        ),
    ];

    // 現在のブランチを表示タブ内の index へ変換（該当なしは先頭にフォールバック）。
    var selected = tabs.indexWhere((t) => t.branch == navigationShell.currentIndex);
    if (selected < 0) selected = 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.ink900,
          // インジケーター（ピル）を透明にして非表示
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? AppColors.accent
                  : AppColors.brandPrimaryInk.withValues(alpha: 0.5),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected
                  ? AppColors.accent
                  : AppColors.brandPrimaryInk.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (visual) {
            final branch = tabs[visual].branch;
            navigationShell.goBranch(
              branch,
              initialLocation: branch == navigationShell.currentIndex,
            );
          },
          destinations: [for (final t in tabs) t.destination],
        ),
      ),
    );
  }
}
