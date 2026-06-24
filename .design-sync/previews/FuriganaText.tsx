import React from 'react';
import { FuriganaText } from 'flutter-comic-tabloid-ds';

const headingStyle: React.CSSProperties = {
  fontFamily: "'M PLUS 1p', sans-serif",
  fontSize: 28,
  fontWeight: 900,
  color: '#000B29',
  lineHeight: 1.35,
  letterSpacing: -0.5,
};

const bodyStyle: React.CSSProperties = {
  fontFamily: "'Noto Sans JP', sans-serif",
  fontSize: 16,
  color: '#000B29',
  lineHeight: 1.5,
};

export function HeadlineWithRuby() {
  return (
    <div style={{ padding: 24, background: '#FDFCFB', maxWidth: 480 }}>
      <FuriganaText
        raw="〔世界｜せかい〕の〔環境｜かんきょう〕を守るルール"
        style={headingStyle}
      />
    </div>
  );
}

export function BodyText() {
  return (
    <div style={{ padding: 24, background: '#FDFCFB', maxWidth: 480 }}>
      <FuriganaText
        raw="〔科学者｜かがくしゃ〕たちは〔地球｜ちきゅう〕を〔救｜すく〕うために、〔新｜あたら〕しい〔技術｜ぎじゅつ〕を〔開発｜かいはつ〕しています。"
        style={bodyStyle}
      />
    </div>
  );
}

export function PlainText() {
  return (
    <div style={{ padding: 24, background: '#FDFCFB', maxWidth: 480 }}>
      <FuriganaText
        raw="ひらがなとカタカナだけのテキスト（ルビなし）"
        style={bodyStyle}
      />
    </div>
  );
}

export function DisplayTitle() {
  return (
    <div style={{ padding: 24, background: '#000B29', maxWidth: 480 }}>
      <FuriganaText
        raw="〔宇宙｜うちゅう〕の〔謎｜なぞ〕を〔解｜と〕く〔冒険｜ぼうけん〕"
        style={{ ...headingStyle, fontSize: 40, color: '#F8F5F2' }}
      />
    </div>
  );
}
