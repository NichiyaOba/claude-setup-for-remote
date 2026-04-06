#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

shopt -s nullglob
install_scripts=( "$SCRIPT_DIR"/packages/*/install.sh )

if ((${#install_scripts[@]} == 0)); then
  echo "No install scripts found."
  exit 0
fi

for install_script in "${install_scripts[@]}"; do
  echo "Installing: $(basename "$(dirname "$install_script")")"
  bash "$install_script"
done

# .claude/ 設定をターゲットプロジェクト（CWD）にデプロイ
# セットアップリポジトリが CWD と異なる場所にある場合のみ実行
TARGET_DIR="$(pwd)"
if [[ "$(cd "$SCRIPT_DIR" && pwd)" != "$(cd "$TARGET_DIR" && pwd)" ]]; then

  # commands/ と agents/ をコピー
  for config_dir in commands agents; do
    src="${SCRIPT_DIR}/.claude/${config_dir}"
    dest="${TARGET_DIR}/.claude/${config_dir}"
    if [[ -d "$src" ]]; then
      mkdir -p "$dest"
      cp -r "${src}/"* "$dest/" 2>/dev/null || true
      echo "Installed .claude/${config_dir}/ to target project."
    fi
  done

  # permissions を settings.local.json にマージ（既存の settings.json には触れない）
  if command -v jq &> /dev/null; then
    LOCAL_SETTINGS="${TARGET_DIR}/.claude/settings.local.json"
    SETUP_PERMISSIONS="$(jq -c '.permissions.allow // []' "${SCRIPT_DIR}/.claude/settings.json")"
    if [[ ! -f "$LOCAL_SETTINGS" ]]; then
      echo '{}' > "$LOCAL_SETTINGS"
    fi
    jq --argjson new_perms "$SETUP_PERMISSIONS" '
      .permissions.allow = ((.permissions.allow // []) + $new_perms | unique)
    ' "$LOCAL_SETTINGS" > "${LOCAL_SETTINGS}.tmp" && mv "${LOCAL_SETTINGS}.tmp" "$LOCAL_SETTINGS"
    echo "Merged permissions into .claude/settings.local.json."
  fi

  # .git/info/exclude にセットアップ生成ファイルを追加（git diff に出さない）
  EXCLUDE_FILE="${TARGET_DIR}/.git/info/exclude"
  if [[ -f "$EXCLUDE_FILE" ]]; then
    MARKER="# claude-setup-for-remote"
    if ! grep -q "$MARKER" "$EXCLUDE_FILE" 2>/dev/null; then
      cat >> "$EXCLUDE_FILE" <<'EXCLUDE'

# claude-setup-for-remote: auto-installed config (not for commit)
.claude/commands/
.claude/agents/
.claude/hooks/
.claude/settings.local.json
EXCLUDE
      echo "Added exclusion patterns to .git/info/exclude."
    fi
  fi
fi

echo "Done."
