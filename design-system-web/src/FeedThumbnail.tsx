import React, { useState } from 'react';
import { colors } from './tokens';

export type ThumbnailMode = 'asset' | 'generated';

export interface ThumbnailConfig {
  /** Local asset path (used when mode is 'asset'). */
  baseAsset?: string;
  /** Remote URL for AI-generated image (used when mode is 'generated'). */
  optionalGeneratedUrl?: string;
  mode?: ThumbnailMode;
}

export interface FeedThumbnailProps {
  config: ThumbnailConfig;
  useGeneratedImages?: boolean;
  /** Content overlaid on top of the image (e.g. text overlay). */
  overlay?: React.ReactNode;
  /** Material icon name shown in the fallback gradient. Not used in web — pass children instead. */
  fallbackIcon?: string;
  /** Custom fallback content rendered when no image is available. */
  fallbackContent?: React.ReactNode;
  style?: React.CSSProperties;
  className?: string;
}

/**
 * Image abstraction with automatic fallback — mirrors Flutter's FeedThumbnail.
 *
 * On image load error falls back to a solid surface background with
 * centered fallback content (icon or custom node).
 */
export function FeedThumbnail({
  config,
  useGeneratedImages = false,
  overlay,
  fallbackContent,
  style,
  className,
}: FeedThumbnailProps) {
  const [imgError, setImgError] = useState(false);

  const resolveUrl = (): string | null => {
    if (imgError) return null;
    const wantsGenerated =
      useGeneratedImages || config.mode === 'generated';
    if (wantsGenerated && config.optionalGeneratedUrl) {
      return config.optionalGeneratedUrl;
    }
    if (config.baseAsset) return config.baseAsset;
    return null;
  };

  const url = resolveUrl();

  return (
    <div
      className={className}
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        background: url
          ? undefined
          : colors.surface,
        backgroundImage: url
          ? `url(${JSON.stringify(url)})`
          : undefined,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        overflow: 'hidden',
        ...style,
      }}
    >
      {url && (
        <img
          src={url}
          alt=""
          aria-hidden
          onError={() => setImgError(true)}
          style={{ display: 'none' }}
        />
      )}
      {!url && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: `${colors.brandPrimaryInk}80`,
            fontSize: 64,
          }}
        >
          {fallbackContent ?? '📰'}
        </div>
      )}
      {overlay && (
        <div style={{ position: 'absolute', inset: 0 }}>
          {overlay}
        </div>
      )}
    </div>
  );
}
