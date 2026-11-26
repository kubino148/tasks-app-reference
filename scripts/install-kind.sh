#!/usr/bin/env bash
# Installs kind v0.33.0 into /usr/local/bin. Writes nothing into your repo. Safe to run twice.
set -euo pipefail

[ "$(uname -m)" = x86_64 ] || { echo "This script is for x86_64"; exit 1; }

V=v0.33.0
SHA=aee6151561422756b764a4ae28e7f44cda5af5a9eead3cc9985112b1de8d8e0d

curl -fsSL -o /tmp/kind "https://github.com/kubernetes-sigs/kind/releases/download/${V}/kind-linux-amd64"
echo "${SHA}  /tmp/kind" | sha256sum -c -
sudo install -m 0755 /tmp/kind /usr/local/bin/kind
kind version
