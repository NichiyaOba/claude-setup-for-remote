#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TARGET_DIR="$(pwd)"

# CI環境ではsettings.json変更とフック配置をスキップ
if [[ "${CI:-}" == "true" ]]; then
  echo "CI environment detected. Running syntax check only."
  bash -n "${SCRIPT_DIR}/hooks/stop-feedback-detector.sh"
  echo "Syntax check passed."
  exit 0
fi

# jq の存在確認（なければ packages/jq/install.sh を先行実行）
if ! command -v jq &> /dev/null; then
  echo "jq not found. Installing jq first..."
  JQ_INSTALL="${REPO_ROOT}/packages/jq/install.sh"
  if [[ -f "$JQ_INSTALL" ]]; then
    bash "$JQ_INSTALL"
  else
    echo "Error: jq is required but packages/jq/install.sh not found." >&2
    exit 1
  fi
fi

HOOKS_DIR="${TARGET_DIR}/.claude/hooks"
SETTINGS_FILE="${TARGET_DIR}/.claude/settings.json"
HOOK_SCRIPT="${HOOKS_DIR}/stop-feedback-detector.sh"
HOOK_CMD=".claude/hooks/stop-feedback-detector.sh"

# .claude/hooks/ ディレクトリ作成
mkdir -p "$HOOKS_DIR"

# フックスクリプトをコピー
cp "${SCRIPT_DIR}/hooks/stop-feedback-detector.sh" "$HOOK_SCRIPT"
chmod +x "$HOOK_SCRIPT"

# settings.json が存在しない場合は空のオブジェクトを作成
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# 既登録チェック（冪等性保証）
if jq -e --arg cmd "$HOOK_CMD" \
  '[.hooks.Stop // [] | .[] | .hooks[]? | select(.command == $cmd)] | length > 0' \
  "$SETTINGS_FILE" > /dev/null 2>&1; then
  echo "Stop hook already registered. Skipping."
  exit 0
fi

# settings.json に hooks.Stop エントリを追記マージ
jq --arg cmd "$HOOK_CMD" '
  .hooks.Stop = (.hooks.Stop // []) + [{
    "matcher": "",
    "hooks": [{"type": "command", "command": $cmd}]
  }]
' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

echo "agent-feedback-updater: Stop hook registered successfully."
