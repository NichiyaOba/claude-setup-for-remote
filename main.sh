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

echo "Done."
