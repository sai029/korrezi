import React from 'react';
import { colors, spacing, typography } from './tokens';
import { FeedThumbnail, ThumbnailConfig } from './FeedThumbnail';
import { FuriganaText } from './FuriganaText';
import { CategoryBadge } from './CategoryBadge';
import { BouncyTap } from './BouncyTap';

export interface FeedPageProps {
  /** News article title (may contain 〔漢字｜よみ〕 ruby markers). */
  title: string;
  /** Short tagline / summary (may contain ruby markers). */
  tagline: string;
  /** Genre or interest context for the category badge. */
  genre: string;
  /** Thumbnail image configuration. */
  thumbnailConfig?: ThumbnailConfig;
  onReadTap?: () => void;
  onFavoriteTap?: () => void;
  style?: React.CSSProperties;
  className?: string;
}

const FEED_OVERLAY: React.CSSProperties = {
  position: 'absolute',
  inset: 0,
  background: 'linear-gradient(to bottom, transparent 50%, rgba(0,11,41,0.85) 100%)',
};

/**
 * Immersive full-height news card — mirrors Flutter's `_FeedPage` widget.
 *
 * Shows a full-bleed thumbnail with a gradient overlay, category badge,
 * ruby-annotated title and tagline, and action buttons.
 */
export function FeedPage({
  title,
  tagline,
  genre,
  thumbnailConfig,
  onReadTap,
  onFavoriteTap,
  style,
  className,
}: FeedPageProps) {
  return (
    <div
      className={className}
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        minHeight: 400,
        background: colors.ink900,
        overflow: 'hidden',
        ...style,
      }}
    >
      <FeedThumbnail
        config={thumbnailConfig ?? {}}
        style={{ position: 'absolute', inset: 0 }}
      />

      {/* gradient overlay */}
      <div style={FEED_OVERLAY} />

      {/* bottom content */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'flex-end',
          padding: spacing.space5,
          gap: spacing.space4,
        }}
      >
        <CategoryBadge genre={genre} />

        <FuriganaText
          raw={title}
          style={{
            fontFamily: typography.fontHeading,
            fontSize: typography.sizeDisplay,
            fontWeight: 900,
            lineHeight: typography.lineHeightChild,
            letterSpacing: -0.5,
            color: colors.brandPrimaryInk,
          }}
        />

        <FuriganaText
          raw={tagline}
          style={{
            fontFamily: typography.fontBody,
            fontSize: typography.sizeBodyLarge,
            lineHeight: typography.lineHeightChild,
            color: `${colors.brandPrimaryInk}b2`,
          }}
        />

        <div style={{ display: 'flex', gap: spacing.space3, alignItems: 'center' }}>
          <BouncyTap onClick={onReadTap}>
            <button
              onClick={onReadTap}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: spacing.space2,
                padding: `0 ${spacing.space5}px`,
                height: 52,
                background: colors.brandPrimary,
                color: colors.brandPrimaryInk,
                border: 'none',
                borderRadius: 4,
                fontFamily: typography.fontHeading,
                fontSize: typography.sizeLabel,
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              📖 よんでみる
            </button>
          </BouncyTap>

          <BouncyTap onClick={onFavoriteTap}>
            <button
              onClick={onFavoriteTap}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 48,
                height: 48,
                background: `${colors.brandPrimaryInk}1a`,
                color: colors.brandPrimaryInk,
                border: 'none',
                borderRadius: 4,
                fontSize: 22,
                cursor: 'pointer',
              }}
            >
              🤍
            </button>
          </BouncyTap>
        </div>
      </div>
    </div>
  );
}
