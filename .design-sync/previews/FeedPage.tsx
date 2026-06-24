import React from 'react';
import { FeedPage } from 'flutter-comic-tabloid-ds';

export function ScienceArticle() {
  return (
    <div style={{ width: 390, height: 680, border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden' }}>
      <FeedPage
        title="〔宇宙〕の〔謎〕を〔解〕く〔新〕しい〔望遠鏡〕"
        tagline="〔科学者〕たちが〔観測〕した〔驚〕きの〔映像〕"
        genre="宇宙"
        thumbnailConfig={{}}
      />
    </div>
  );
}

export function SportsArticle() {
  return (
    <div style={{ width: 390, height: 680, border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden' }}>
      <FeedPage
        title="〔日本〕チームが〔世界〕〔大会〕で〔優勝〕！"
        tagline="〔選手〕たちの〔努力〕と〔友情〕の〔物語〕"
        genre="サッカー"
        thumbnailConfig={{}}
      />
    </div>
  );
}

export function NatureArticle() {
  return (
    <div style={{ width: 390, height: 680, border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden' }}>
      <FeedPage
        title="〔絶滅危惧種〕の〔動物〕を〔守〕る〔作戦〕"
        tagline="〔世界中〕の〔子供〕たちが〔自然〕を〔守〕るために〔立〕ち〔上〕がった"
        genre="自然"
        thumbnailConfig={{}}
      />
    </div>
  );
}
