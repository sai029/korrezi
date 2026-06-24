import React from 'react';
import { accentForGenre, colors, radii, spacing, typography } from './tokens';
import { BouncyTap } from './BouncyTap';

export interface CategoryBadgeProps {
  /** Genre / interest context string (e.g. "サッカー", "science"). */
  genre: string;
  onClick?: () => void;
  className?: string;
  style?: React.CSSProperties;
}

/**
 * Pill-shaped badge showing a `#genre` label with a genre-derived accent color.
 *
 * Uses the same hash-based color assignment as Flutter's `AppColors.accentForGenre()`.
 * Wraps in BouncyTap when `onClick` is provided.
 */
export function CategoryBadge({ genre, onClick, className, style }: CategoryBadgeProps) {
  const bg = accentForGenre(genre);

  const badge = (
    <div
      className={className}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        padding: `${spacing.space1 + 2}px ${spacing.space3}px`,
        background: bg,
        borderRadius: radii.pill,
        fontFamily: typography.fontBody,
        fontSize: typography.sizeLabel,
        fontWeight: 600,
        color: colors.brandPrimaryInk,
        letterSpacing: '0.02em',
        ...style,
      }}
    >
      #{genre}
    </div>
  );

  if (onClick) {
    return <BouncyTap onClick={onClick}>{badge}</BouncyTap>;
  }
  return badge;
}
