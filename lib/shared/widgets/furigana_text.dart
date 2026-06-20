import 'package:flutter/material.dart';

/// ルビ(Furigana)付きテキストを描画するウィジェット。
///
/// `child_body_with_ruby` の markup 〔漢字｜よみ〕 を解析し、漢字の上に小さく読みを
/// 重ねて表示する。markup 以外のプレーン文字列はそのまま流し込む。
///
/// 例: `〔世界｜せかい〕の〔環境｜かんきょう〕を守るルール`
class FuriganaText extends StatelessWidget {
  const FuriganaText(this.raw, {super.key, this.style});

  final String raw;
  final TextStyle? style;

  static final _rubyPattern = RegExp(r'〔([^｜]+)｜([^〕]+)〕');

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final rubyStyle = base.copyWith(
      fontSize: (base.fontSize ?? 14) * 0.5,
      height: 1.0,
    );

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _rubyPattern.allMatches(raw)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: raw.substring(cursor, m.start)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _Ruby(base: m.group(1)!, reading: m.group(2)!,
              baseStyle: base, rubyStyle: rubyStyle),
        ),
      );
      cursor = m.end;
    }
    if (cursor < raw.length) {
      spans.add(TextSpan(text: raw.substring(cursor)));
    }

    return RichText(text: TextSpan(style: base, children: spans));
  }
}

/// 漢字 + その上の読み（ルビ）を縦に積んだ最小単位。
class _Ruby extends StatelessWidget {
  const _Ruby({
    required this.base,
    required this.reading,
    required this.baseStyle,
    required this.rubyStyle,
  });

  final String base;
  final String reading;
  final TextStyle baseStyle;
  final TextStyle rubyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(reading, style: rubyStyle),
        Text(base, style: baseStyle),
      ],
    );
  }
}
