#!/usr/bin/env bash
# デザインシステム準拠チェック
# ステージ済み Dart ファイルからトークン違反を検出する
#
# 使い方:
#   design_check.sh          → ステージ済みファイルのみ（pre-commit / hook 用）
#   design_check.sh --all    → lib/ 配下の全 Dart ファイル（/qa Skill 用）
#
# Exit code: 0 = 違反なし、1 = 違反あり

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# tokens.dart / theme.dart はトークン定義ファイルなので除外
# 生成ファイル (.g.dart / .freezed.dart) も対象外
if [ "$1" = "--all" ]; then
  STAGED=$(git -C "$PROJECT_ROOT" ls-files 'lib/*.dart' 'lib/**/*.dart' 2>/dev/null \
    | grep -v '\.g\.dart$' \
    | grep -v '\.freezed\.dart$' \
    | grep -v 'tokens\.dart' \
    | grep -v 'theme\.dart' \
    | grep -v 'colors\.dart')
else
  STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null \
    | grep '\.dart$' \
    | grep -v '\.g\.dart$' \
    | grep -v '\.freezed\.dart$' \
    | grep -v 'tokens\.dart' \
    | grep -v 'theme\.dart' \
    | grep -v 'colors\.dart')
fi

if [ -z "$STAGED" ]; then
  exit 0
fi

VIOLATIONS=""

for FILE in $STAGED; do
  FILEPATH="$PROJECT_ROOT/$FILE"
  [ -f "$FILEPATH" ] || continue

  # 1. ハードコードカラー Color(0x...) → AppColors.* を使うこと
  MATCHES=$(grep -nE 'Color\(0x[0-9A-Fa-f]+' "$FILEPATH" 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    VIOLATIONS="${VIOLATIONS}\n⚠️  [$FILE] ハードコードカラー → AppColors.* を使用してください\n${MATCHES}"
  fi

  # 2. Material カラー定数 Colors.red など → AppColors.* を使うこと
  MATCHES=$(grep -nE 'Colors\.(red|blue|green|black|white|amber|orange|purple|teal|cyan|lime|pink|yellow|grey|gray)[^A-Za-z]' "$FILEPATH" 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    VIOLATIONS="${VIOLATIONS}\n⚠️  [$FILE] Material カラー定数 → AppColors.* を使用してください\n${MATCHES}"
  fi

  # 3. ハードコード BorderRadius.circular(数値) → AppRadii.* を使うこと
  MATCHES=$(grep -nE 'BorderRadius\.circular\([0-9]' "$FILEPATH" 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    VIOLATIONS="${VIOLATIONS}\n⚠️  [$FILE] ハードコード角丸 → AppRadii.sm / md / lg / pill を使用してください\n${MATCHES}"
  fi

  # 4. ハードコード Duration(milliseconds: 数値) → AppMotion.* を使うこと
  MATCHES=$(grep -nE 'Duration\(milliseconds: [0-9]' "$FILEPATH" 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    VIOLATIONS="${VIOLATIONS}\n⚠️  [$FILE] ハードコード Duration → AppMotion.durFast / durBase / durSlow を使用してください\n${MATCHES}"
  fi
done

if [ -n "$VIOLATIONS" ]; then
  echo -e "$VIOLATIONS"
  exit 1
fi

exit 0
