import React, { useCallback, useRef, useState } from 'react';
import { motion } from './tokens';

export interface BouncyTapProps {
  children: React.ReactNode;
  onClick?: () => void;
  onLongPress?: () => void;
  /** Scale factor at press depth (default 0.96, mirrors Flutter). */
  scaleDown?: number;
  className?: string;
  style?: React.CSSProperties;
}

/**
 * Tap wrapper that scales to `scaleDown` on press and bounces back
 * with an easeOutBack curve — mirrors Flutter's BouncyTap widget.
 */
export function BouncyTap({
  children,
  onClick,
  onLongPress,
  scaleDown = 0.96,
  className,
  style,
}: BouncyTapProps) {
  const [pressed, setPressed] = useState(false);
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const handlePointerDown = useCallback(() => {
    setPressed(true);
    if (onLongPress) {
      longPressTimer.current = setTimeout(() => {
        onLongPress();
        longPressTimer.current = null;
      }, 500);
    }
  }, [onLongPress]);

  const handlePointerUp = useCallback(() => {
    setPressed(false);
    if (longPressTimer.current) {
      clearTimeout(longPressTimer.current);
      longPressTimer.current = null;
    }
    onClick?.();
  }, [onClick]);

  const handlePointerCancel = useCallback(() => {
    setPressed(false);
    if (longPressTimer.current) {
      clearTimeout(longPressTimer.current);
      longPressTimer.current = null;
    }
  }, []);

  return (
    <div
      className={className}
      style={{
        display: 'inline-flex',
        cursor: onClick || onLongPress ? 'pointer' : 'default',
        userSelect: 'none',
        transform: pressed ? `scale(${scaleDown})` : 'scale(1)',
        transition: pressed
          ? `transform ${motion.durFast}ms ease-in`
          : `transform ${motion.durBase}ms ${motion.easeBounce}`,
        ...style,
      }}
      onPointerDown={handlePointerDown}
      onPointerUp={handlePointerUp}
      onPointerCancel={handlePointerCancel}
      onPointerLeave={handlePointerCancel}
    >
      {children}
    </div>
  );
}
