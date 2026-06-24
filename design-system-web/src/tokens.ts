/** Comic-Tabloid design tokens — mirrors Flutter tokens.dart */

export const colors = {
  brandPrimary:    '#D70026',
  brandPrimaryInk: '#F8F5F2',
  accent:          '#EDB83D',
  accentInk:       '#000B29',
  ink900: '#000B29',
  ink700: '#1C2647',
  ink500: '#5E6A8C',
  ink300: '#AEB6CC',
  surface:     '#F8F5F2',
  surfaceAlt:  '#EFEBE6',
  background:  '#FDFCFB',
  accentGreen:  '#258039',
  accentYellow: '#EDB83D',
  accentTeal:   '#31A9B8',
  accentRed:    '#D70026',
  success: '#258039',
  warning: '#EDB83D',
  error:   '#D70026',
} as const;

const GENRE_ACCENTS = [
  colors.accentGreen,
  colors.accentYellow,
  colors.accentTeal,
  colors.accentRed,
] as const;

export function accentForGenre(genre: string): string {
  let hash = 0;
  for (let i = 0; i < genre.length; i++) hash = (hash * 31 + genre.charCodeAt(i)) | 0;
  return GENRE_ACCENTS[Math.abs(hash) % GENRE_ACCENTS.length];
}

export const spacing = {
  space1: 4,  space2: 8,  space3: 12, space4: 16,
  space5: 24, space6: 32, space7: 48, space8: 64,
} as const;

export const radii = {
  sm: 4, md: 6, lg: 8, pill: 9999,
} as const;

export const borders = {
  thin: 1.5, base: 2.5, thick: 4,
} as const;

export const motion = {
  durFast: 150,
  durBase: 250,
  durSlow: 400,
  easeStandard: 'ease-in-out',
  easeBounce:   'cubic-bezier(0.34, 1.56, 0.64, 1)',
} as const;

export const typography = {
  fontHeading: "'M PLUS 1p', sans-serif",
  fontBody:    "'Noto Sans JP', sans-serif",
  sizeDisplay:   40, sizeHeadline: 28, sizeTitle:     22,
  sizeBodyLarge: 18, sizeBody:     16, sizeLabel:     14, sizeCaption: 12,
  lineHeightChild:  1.35,
  lineHeightParent: 1.5,
  lineHeightCommon: 1.7,
} as const;
