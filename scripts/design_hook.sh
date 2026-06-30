#!/usr/bin/env bash
# Claude Code PreToolUse フック用スクリプト
# Bash ツールで git commit が実行される直前にデザインチェックを走らせる
#
# 呼び出し元: .claude/settings.local.json の hooks.PreToolUse
# 入力:       stdin に Claude Code のツール入力 JSON が渡される
# 出力（違反あり）: {"decision":"block","reason":"..."} を stdout に出力、exit 2
# 出力（問題なし）: exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# stdin からツール入力 JSON を読み込む
INPUT=$(cat)

# Python3 で command フィールドを抽出
COMMAND=""
for PYTHON in python3 python; do
  if command -v "$PYTHON" &>/dev/null; then
    COMMAND=$(printf '%s' "$INPUT" | "$PYTHON" -c \
      "import json,sys; print(json.load(sys.stdin).get('command',''))" 2>/dev/null) && break
  fi
done

# git commit を含むコマンドのみ対象
if ! echo "$COMMAND" | grep -q "git commit"; then
  exit 0
fi

# デザインチェック実行
RESULT=$("$SCRIPT_DIR/design_check.sh" 2>&1) || true

if [ -n "$RESULT" ]; then
  # 違反あり: ブロック決定と理由を JSON で返す
  for PYTHON in python3 python; do
    if command -v "$PYTHON" &>/dev/null; then
      printf '%s' "$RESULT" | "$PYTHON" -c "
import json, sys
violations = sys.stdin.read().strip()
reason = (
  'デザイントークン違反が見つかりました。'
  'Edit ツールで以下の問題を修正してから再度コミットしてください:\n\n'
  + violations
  + '\n\n【参照】lib/core/theme/tokens.dart'
)
print(json.dumps({'decision': 'block', 'reason': reason}, ensure_ascii=False))
"
      break
    fi
  done
  exit 2
fi

exit 0
