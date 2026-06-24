import React from 'react';
import { BouncyTap } from 'flutter-comic-tabloid-ds';

const btnStyle: React.CSSProperties = {
  padding: '14px 28px',
  background: '#D70026',
  color: '#F8F5F2',
  border: 'none',
  borderRadius: 4,
  fontFamily: "'M PLUS 1p', sans-serif",
  fontSize: 14,
  fontWeight: 700,
  cursor: 'pointer',
};

export function PrimaryButton() {
  return (
    <div style={{ padding: 24, display: 'flex', gap: 16, alignItems: 'center', background: '#FDFCFB' }}>
      <BouncyTap>
        <button style={btnStyle}>よんでみる</button>
      </BouncyTap>
    </div>
  );
}

export function IconButton() {
  return (
    <div style={{ padding: 24, display: 'flex', gap: 16, alignItems: 'center', background: '#FDFCFB' }}>
      <BouncyTap>
        <div style={{
          width: 48, height: 48, background: '#F8F5F2', border: '2.5px solid #000B29',
          borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 20, cursor: 'pointer',
        }}>
          🤍
        </div>
      </BouncyTap>
      <BouncyTap>
        <div style={{
          width: 48, height: 48, background: '#F8F5F2', border: '2.5px solid #000B29',
          borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 20, cursor: 'pointer',
        }}>
          📖
        </div>
      </BouncyTap>
    </div>
  );
}

export function Badge() {
  return (
    <div style={{ padding: 24, display: 'flex', gap: 12, flexWrap: 'wrap', background: '#FDFCFB' }}>
      {['#サッカー', '#科学', '#音楽', '#宇宙'].map((label) => (
        <BouncyTap key={label} scaleDown={0.94}>
          <div style={{
            padding: '6px 12px', background: '#EDB83D', borderRadius: 9999,
            fontFamily: "'Noto Sans JP', sans-serif", fontSize: 14, fontWeight: 600,
            color: '#000B29', cursor: 'pointer',
          }}>
            {label}
          </div>
        </BouncyTap>
      ))}
    </div>
  );
}
