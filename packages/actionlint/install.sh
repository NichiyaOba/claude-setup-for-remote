#!/bin/bash
set -euo pipefail

ACTIONLINT_VERSION="v1.7.12"
ACTIONLINT_VERSION_NUM="${ACTIONLINT_VERSION#v}"
ACTIONLINT_URL="https://github.com/rhysd/actionlint/releases/download/${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION_NUM}_linux_amd64.tar.gz"
ACTIONLINT_SHA256="8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL --retry 3 --connect-timeout 10 -o "$TMP_DIR/actionlint.tar.gz" "$ACTIONLINT_URL"
echo "${ACTIONLINT_SHA256}  $TMP_DIR/actionlint.tar.gz" | sha256sum -c -
tar -xzf "$TMP_DIR/actionlint.tar.gz" -C "$TMP_DIR"
install -m 0755 "$TMP_DIR/actionlint" /usr/local/bin/actionlint
