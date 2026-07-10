import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// アプリのブランドロゴ「コレッジ」。
///
/// 「子ども × knowledge」を由来とする造語。ディープレッドと
/// スレートグレーで組まれたロゴタイプで、発見のワクワクを表す。
///
/// デザイナー支給の SVG（`assets/images/logo/`）をそのまま描画する。
/// [showWordmark] を true にすると文字入りのワードマーク（正方形ロックアップ）、
/// false にすると文字なしのマークのみを表示する。
///
/// [size] はロゴの描画高さ（px）。ワードマークは正方形、
/// マークは横長（約 2.23:1）で、いずれも高さ基準で拡縮する。
class KoledgeLogo extends StatelessWidget {
  const KoledgeLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
  });

  final double size;
  final bool showWordmark;

  static const _wordmark = 'assets/images/logo/koledge_logo_wordmark.svg';
  static const _mark = 'assets/images/logo/koledge_logo_mark.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      showWordmark ? _wordmark : _mark,
      height: size,
      semanticsLabel: 'コレッジ',
    );
  }
}
