import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/device/device_role.dart';
import '../../core/theme/tokens.dart';

/// StatefulShellRoute のブランチ（/child・/common・/parent）を横スワイプで
/// 切り替えられるようにする本文コンテナ。
///
/// 既定の IndexedStack を PageView に置き換え、下部 NavigationBar と双方向に同期する:
/// - スワイプでページが変わったら [StatefulNavigationShell.goBranch] を呼ぶ
/// - 下部バー等でブランチが変わったら PageController を追従アニメーションさせる
///
/// 子ども端末では保護者向け「ようす」(/parent = branch 2) を除外し、
/// タブと同様にスワイプ範囲からも隠す。
class SwipeShellBody extends ConsumerStatefulWidget {
  const SwipeShellBody({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;

  /// 各ブランチの Navigator（branch index 順）。
  final List<Widget> children;

  @override
  ConsumerState<SwipeShellBody> createState() => _SwipeShellBodyState();
}

class _SwipeShellBodyState extends ConsumerState<SwipeShellBody> {
  PageController? _controller;
  int _visibleCount = 0;

  /// スワイプで到達できるブランチ index の並び（子ども端末は /parent を除外）。
  List<int> _visibleBranches(bool isChild) => isChild ? const [0, 1] : const [0, 1, 2];

  int _pageForBranch(List<int> visible, int branch) {
    final i = visible.indexOf(branch);
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChild = ref.watch(deviceRoleProvider) == DeviceRole.child;
    final visible = _visibleBranches(isChild);
    final currentPage = _pageForBranch(visible, widget.navigationShell.currentIndex);

    // 初回、または表示ブランチ数が変わった（役割切替）ときはコントローラを作り直す。
    if (_controller == null || _visibleCount != visible.length) {
      _controller?.dispose();
      _controller = PageController(initialPage: currentPage);
      _visibleCount = visible.length;
    }

    // 下部バー／リダイレクトなど外部要因でブランチが変わったら追従する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controller;
      if (!mounted || controller == null || !controller.hasClients) return;
      final target = _pageForBranch(visible, widget.navigationShell.currentIndex);
      final page = controller.page?.round();
      if (page != null && page != target) {
        controller.animateToPage(
          target,
          duration: AppMotion.durBase,
          curve: AppMotion.curveStandard,
        );
      }
    });

    return PageView(
      controller: _controller,
      physics: const _TabSwipePhysics(),
      onPageChanged: (page) {
        final branch = visible[page];
        if (branch != widget.navigationShell.currentIndex) {
          widget.navigationShell.goBranch(branch);
        }
      },
      children: [
        for (final b in visible) _KeepAlivePage(child: widget.children[b]),
      ],
    );
  }
}

/// タブ切り替え用の横 PageView 物理。
///
/// 横スワイプの発火に必要な移動量を既定より大きめ（[dragStartDistanceMotionThreshold]）
/// にして、縦フィード（PageView 側の閾値が非常に小さく敏感）とジェスチャアリーナで
/// 競合したとき、斜めのドラッグを縦側に譲る。これにより縦スライドの効きを保つ。
class _TabSwipePhysics extends PageScrollPhysics {
  const _TabSwipePhysics({super.parent});

  @override
  _TabSwipePhysics applyTo(ScrollPhysics? ancestor) =>
      _TabSwipePhysics(parent: buildParent(ancestor));

  @override
  double get dragStartDistanceMotionThreshold => 24.0;
}

/// PageView でオフスクリーンに回ってもブランチの状態（Navigator スタック・
/// スクロール位置）を破棄させないための keep-alive ラッパー。
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});
  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
