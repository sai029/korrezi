import React from 'react';

const RUBY_PATTERN = /〔([^｜]+)｜([^〕]+)〕/g;

const KANJI_RANGES: [number, number][] = [
  [0x4e00, 0x9fff],
  [0x3400, 0x4dbf],
  [0xf900, 0xfaff],
];

function hasKanji(text: string): boolean {
  return [...text].some((ch) => {
    const c = ch.codePointAt(0) ?? 0;
    return KANJI_RANGES.some(([lo, hi]) => c >= lo && c <= hi);
  });
}

export interface FuriganaTextProps {
  /** Raw text containing 〔漢字｜よみ〕 ruby markers. */
  raw: string;
  style?: React.CSSProperties;
  className?: string;
}

/**
 * Renders Japanese text with optional furigana (ruby) annotations.
 *
 * Parses `〔漢字｜よみ〕` markers and wraps each kanji group in an
 * HTML `<ruby>` element, matching Flutter's FuriganaText widget.
 *
 * @example
 * <FuriganaText raw="〔世界｜せかい〕の〔環境｜かんきょう〕を守るルール" />
 */
export function FuriganaText({ raw, style, className }: FuriganaTextProps) {
  const nodes: React.ReactNode[] = [];
  let cursor = 0;
  let key = 0;

  for (const m of raw.matchAll(RUBY_PATTERN)) {
    const [full, base, reading] = m;
    const idx = m.index ?? 0;

    if (idx > cursor) {
      nodes.push(raw.slice(cursor, idx));
    }

    if (hasKanji(base)) {
      nodes.push(
        <ruby key={key++} style={{ rubyAlign: 'center' } as React.CSSProperties}>
          {base}
          <rt style={{ fontSize: '0.5em', lineHeight: 1 }}>{reading}</rt>
        </ruby>,
      );
    } else {
      nodes.push(base);
    }

    cursor = idx + full.length;
  }

  if (cursor < raw.length) {
    nodes.push(raw.slice(cursor));
  }

  return (
    <span className={className} style={style}>
      {nodes}
    </span>
  );
}
