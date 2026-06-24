import React from 'react';
import { colors, spacing, typography } from './tokens';

export interface NavItem {
  path: string;
  label: string;
  sublabel?: string;
  icon?: string;
}

export interface NavigationDrawerProps {
  /** Currently active route path. */
  currentPath?: string;
  items?: NavItem[];
  appName?: string;
  onNavigate?: (path: string) => void;
  style?: React.CSSProperties;
  className?: string;
}

const DEFAULT_ITEMS: NavItem[] = [
  { path: '/child',  label: 'Child Feed',          sublabel: 'TikTok風フィード',      icon: '📰' },
  { path: '/common', label: 'Common View',          sublabel: '親子で記事を読む',      icon: '📖' },
  { path: '/parent', label: 'Parent Dashboard',     sublabel: '会話のきっかけ',        icon: '❤️' },
];

/**
 * Side-navigation drawer — mirrors Flutter's AppDrawer.
 *
 * Flat design with a deep-red header and M PLUS 1p brand font.
 * Active item is highlighted with the brand-primary color.
 */
export function NavigationDrawer({
  currentPath = '/child',
  items = DEFAULT_ITEMS,
  appName = 'AI Discovery\nLearning App',
  onNavigate,
  style,
  className,
}: NavigationDrawerProps) {
  return (
    <div
      className={className}
      style={{
        width: 280,
        height: '100%',
        background: colors.background,
        borderRight: `2.5px solid ${colors.ink900}`,
        display: 'flex',
        flexDirection: 'column',
        ...style,
      }}
    >
      {/* header */}
      <div
        style={{
          background: colors.brandPrimary,
          padding: `${spacing.space7}px ${spacing.space5}px ${spacing.space4}px`,
          display: 'flex',
          alignItems: 'flex-end',
        }}
      >
        <span
          style={{
            fontFamily: typography.fontHeading,
            fontSize: 20,
            fontWeight: 700,
            color: colors.brandPrimaryInk,
            whiteSpace: 'pre-line',
            lineHeight: 1.3,
          }}
        >
          {appName}
        </span>
      </div>

      {/* nav items */}
      <nav style={{ flex: 1, padding: `${spacing.space2}px 0` }}>
        {items.map((item) => {
          const active = currentPath === item.path;
          return (
            <button
              key={item.path}
              onClick={() => onNavigate?.(item.path)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: spacing.space4,
                width: '100%',
                padding: `${spacing.space3}px ${spacing.space5}px`,
                background: active ? `${colors.brandPrimary}18` : 'transparent',
                border: 'none',
                borderLeft: active
                  ? `4px solid ${colors.brandPrimary}`
                  : '4px solid transparent',
                cursor: 'pointer',
                textAlign: 'left',
                color: active ? colors.brandPrimary : colors.ink900,
              }}
            >
              {item.icon && (
                <span style={{ fontSize: 20 }}>{item.icon}</span>
              )}
              <div>
                <div
                  style={{
                    fontFamily: typography.fontBody,
                    fontSize: typography.sizeBody,
                    fontWeight: active ? 700 : 400,
                  }}
                >
                  {item.label}
                </div>
                {item.sublabel && (
                  <div
                    style={{
                      fontFamily: typography.fontBody,
                      fontSize: typography.sizeCaption,
                      color: colors.ink500,
                      marginTop: 2,
                    }}
                  >
                    {item.sublabel}
                  </div>
                )}
              </div>
            </button>
          );
        })}
      </nav>
    </div>
  );
}
