#!/bin/bash
set -euo pipefail

JQ_VERSION="jq-1.8.1"
JQ_URL="https://github.com/jqlang/jq/releases/download/${JQ_VERSION}/jq-linux-amd64"
JQ_SHA256="020468de7539ce70ef1bceaf7cde2e8c4f2ca6c3afb84642aabc5c97d9fc2a0d"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL --retry 3 --connect-timeout 10 -o "$TMP_DIR/jq" "$JQ_URL"
echo "${JQ_SHA256}  $TMP_DIR/jq" | sha256sum -c -
install -m 0755 "$TMP_DIR/jq" /usr/local/bin/jq
