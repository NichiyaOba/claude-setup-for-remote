#!/bin/bash
set -euo pipefail

SHELLCHECK_VERSION="v0.11.0"
SHELLCHECK_URL="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
SHELLCHECK_SHA256="8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL --retry 3 --connect-timeout 10 -o "$TMP_DIR/shellcheck.tar.xz" "$SHELLCHECK_URL"
echo "${SHELLCHECK_SHA256}  $TMP_DIR/shellcheck.tar.xz" | sha256sum -c -
tar -xJf "$TMP_DIR/shellcheck.tar.xz" -C "$TMP_DIR"
install -m 0755 "$TMP_DIR/shellcheck-${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/shellcheck
