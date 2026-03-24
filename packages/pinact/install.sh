#!/bin/bash
set -euo pipefail

PINACT_VERSION="v3.9.0"
PINACT_URL="https://github.com/suzuki-shunsuke/pinact/releases/download/${PINACT_VERSION}/pinact_linux_amd64.tar.gz"
PINACT_SHA256="3829da718de38b1e914b974c3e77045a256999af84789437a7305b09130d8a6a"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL --retry 3 --connect-timeout 10 -o "$TMP_DIR/pinact.tar.gz" "$PINACT_URL"
echo "${PINACT_SHA256}  $TMP_DIR/pinact.tar.gz" | sha256sum -c -
tar -xzf "$TMP_DIR/pinact.tar.gz" -C /usr/local/bin pinact
