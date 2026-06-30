#!/usr/bin/env bash
# デザインチェック git フックをインストールする
# 実行: bash scripts/install_hooks.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$GIT_ROOT/.git/hooks"
PRE_COMMIT="$HOOKS_DIR/pre-commit"

echo "🔧 デザインチェックフックをインストールします..."

# スクリプトに実行権限を付与
chmod +x "$SCRIPT_DIR/design_check.sh"
chmod +x "$SCRIPT_DIR/design_hook.sh"
chmod +x "$SCRIPT_DIR/install_hooks.sh"
echo "  ✓ scripts/ に実行権限を付与"

# .git/hooks/pre-commit を生成（非ブロッキング警告のみ）
cat > "$PRE_COMMIT" << 'HOOK'
#!/usr/bin/env bash
# design-check pre-commit hook (non-blocking — warnings only)
REPO_ROOT="$(git rev-parse --show-toplevel)"
RESULT=$("$REPO_ROOT/scripts/design_check.sh" 2>&1) || true
if [ -n "$RESULT" ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────┐"
  echo "│  ⚠️  デザインシステム警告（コミットは続行）     │"
  echo "└─────────────────────────────────────────────────┘"
  echo -e "$RESULT"
  echo ""
  echo "  自動修正: claude \"デザイン違反を修正して\""
  echo ""
fi
exit 0
HOOK

chmod +x "$PRE_COMMIT"
echo "  ✓ .git/hooks/pre-commit をインストール"

echo ""
echo "✅ セットアップ完了"
echo "   - ターミナルからの git commit: 違反があっても警告のみ（commit は通る）"
echo "   - Claude Code 経由の commit: 違反があれば自動修正してから再コミット"
