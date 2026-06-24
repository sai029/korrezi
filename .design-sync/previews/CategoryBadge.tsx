import React from 'react';
import { CategoryBadge } from 'flutter-comic-tabloid-ds';

export function Genres() {
  return (
    <div style={{ padding: 24, display: 'flex', flexWrap: 'wrap', gap: 10, background: '#FDFCFB' }}>
      {['サッカー', '科学', '音楽', '宇宙', '動物', '食べ物', 'テクノロジー', 'スポーツ'].map((g) => (
        <CategoryBadge key={g} genre={g} />
      ))}
    </div>
  );
}

export function OnDark() {
  return (
    <div style={{ padding: 24, display: 'flex', flexWrap: 'wrap', gap: 10, background: '#000B29' }}>
      {['science', 'nature', 'space', 'sport'].map((g) => (
        <CategoryBadge key={g} genre={g} />
      ))}
    </div>
  );
}

export function Single() {
  return (
    <div style={{ padding: 24, background: '#FDFCFB' }}>
      <CategoryBadge genre="サッカー" />
    </div>
  );
}
