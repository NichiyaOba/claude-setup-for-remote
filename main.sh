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

# .claude/commands/ と .claude/agents/ をターゲットプロジェクト（CWD）にコピー
# セットアップリポジトリが CWD と異なる場所にある場合のみ実行
TARGET_DIR="$(pwd)"
if [[ "$(cd "$SCRIPT_DIR" && pwd)" != "$(cd "$TARGET_DIR" && pwd)" ]]; then
  for config_dir in commands agents; do
    src="${SCRIPT_DIR}/.claude/${config_dir}"
    dest="${TARGET_DIR}/.claude/${config_dir}"
    if [[ -d "$src" ]]; then
      mkdir -p "$dest"
      cp -r "${src}/"* "$dest/" 2>/dev/null || true
      echo "Installed .claude/${config_dir}/ to target project."
    fi
  done
fi

echo "Done."
