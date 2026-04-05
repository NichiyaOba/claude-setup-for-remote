#!/bin/bash
set -euo pipefail

GH_VERSION="v2.89.0"
GH_VERSION_NUM="${GH_VERSION#v}"
GH_URL="https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION_NUM}_linux_amd64.tar.gz"
GH_SHA256="d0422caade520530e76c1c558da47daebaa8e1203d6b7ff10ad7d6faba3490d8"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL --retry 3 --connect-timeout 10 -o "$TMP_DIR/gh.tar.gz" "$GH_URL"
echo "${GH_SHA256}  $TMP_DIR/gh.tar.gz" | sha256sum -c -
tar -xzf "$TMP_DIR/gh.tar.gz" -C "$TMP_DIR"
install -m 0755 "$TMP_DIR/gh_${GH_VERSION_NUM}_linux_amd64/bin/gh" /usr/local/bin/gh
