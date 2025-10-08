#!/usr/bin/env bash
set -euo pipefail

if command -v openssl >/dev/null 2>&1; then
  openssl rand -base64 48
elif command -v dd >/dev/null 2>&1; then
  dd if=/dev/urandom bs=48 count=1 2>/dev/null | base64
else
  echo "Instala 'openssl' o usa un generador confiable."
  exit 1
fi
