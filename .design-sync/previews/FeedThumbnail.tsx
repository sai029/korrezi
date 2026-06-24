import React from 'react';
import { FeedThumbnail } from 'flutter-comic-tabloid-ds';

export function WithImage() {
  return (
    <div style={{ width: 320, height: 240, border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden' }}>
      <FeedThumbnail
        config={{ optionalGeneratedUrl: 'https://images.unsplash.com/photo-1547036967-23d11aacaee0?w=640', mode: 'generated' }}
        useGeneratedImages
      />
    </div>
  );
}

export function Fallback() {
  return (
    <div style={{ width: 320, height: 240, border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden' }}>
      <FeedThumbnail
        config={{}}
        fallbackContent="🚀"
      />
    </div>
  );
}

export function WithOverlay() {
  return (
    <div style={{ width: 320, height: 240, border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden', position: 'relative' }}>
      <FeedThumbnail
        config={{}}
        fallbackContent="🌍"
        overlay={
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(to bottom, transparent 40%, rgba(0,11,41,0.85) 100%)',
            display: 'flex', alignItems: 'flex-end', padding: '16px',
          }}>
            <span style={{
              fontFamily: "'M PLUS 1p', sans-serif", fontSize: 18, fontWeight: 900,
              color: '#F8F5F2', lineHeight: 1.3,
            }}>
              地球の〔環境〕を守るルール
            </span>
          </div>
        }
      />
    </div>
  );
}
