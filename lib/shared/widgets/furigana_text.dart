import 'package:flutter/material.dart';

/// ルビ(Furigana)付きテキストを描画するウィジェット。
///
/// 〔漢字｜よみ〕 形式を解析し、漢字の上にふりがなを重ねる。
/// 例: `〔世界｜せかい〕の〔環境｜かんきょう〕を守るルール`
class FuriganaText extends StatelessWidget {
  const FuriganaText(this.raw, {super.key, this.style, this.maxLines, this.overflow});

  final String raw;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  static final _rubyPattern = RegExp(r'〔([^｜]+)｜([^〕]+)〕');

  /// 漢字（CJK統合漢字）を含むかどうかを判定する。
  /// ひらがな・カタカナのみの場合は ruby 不要。
  static bool _hasKanji(String text) => text.codeUnits.any(
        (c) =>
            (c >= 0x4E00 && c <= 0x9FFF) || // CJK統合漢字
            (c >= 0x3400 && c <= 0x4DBF) || // CJK拡張A
            (c >= 0xF900 && c <= 0xFAFF),   // CJK互換漢字
      );

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
      final baseText = m.group(1)!;
      if (_hasKanji(baseText)) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _Ruby(
              base: baseText,
              reading: m.group(2)!,
              baseStyle: base,
              rubyStyle: rubyStyle,
            ),
          ),
        );
      } else {
        // カタカナ・ひらがなのみの場合はルビなしで表示する。
        spans.add(TextSpan(text: baseText));
      }
      cursor = m.end;
    }
    if (cursor < raw.length) {
      spans.add(TextSpan(text: raw.substring(cursor)));
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(style: base, children: spans),
    );
  }
}

/// 漢字 + ルビを Stack で重ねる。
///
/// Stack のサイズ = base Text のみ → 行高さが周囲と揃う。
/// ルビは Positioned で base グリフの上端より上に配置し、Clip.none ではみ出す。
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
    final h    = baseStyle.height ?? 1.4;
    final size = baseStyle.fontSize ?? 14;
    // ルビの bottom = グリフ領域上端（half-leading より上）
    // = fontSize + (lineHeight - fontSize) / 2  =  size * (h + 1) / 2
    final rubyBottom = size * (h + 1) / 2;

    // ルビは Stack の外にはみ出すためレイアウト上の高さに計上されない。
    // PlaceholderAlignment.middle は widget 中心を EM box 中心に合わせるため、
    // 上下対称の Padding を加えれば中心位置が変わらず本文が下にずれない。
    // 上下それぞれ (rubyFontSize + gap) / 2 だけ広げる。
    final halfPad = (size * 0.5 + 4) / 2;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: halfPad),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // base text がスタックサイズを決定（周囲テキストと同じ行高さ）。
          Text(base, style: baseStyle),
          // ルビはグリフの上にはみ出す。
          Positioned(
            bottom: rubyBottom,
            child: Text(reading, style: rubyStyle),
          ),
        ],
      ),
    );
  }
}
