#!/usr/bin/env bash
set -euo pipefail
BIN="${1:-}"
if [[ -z "$BIN" || ! -f "$BIN" ]]; then
  echo "Usage: ai-r2-quick <binary>" >&2; exit 1
fi
echo "[r2] file info"
file "$BIN" || true
echo "[r2] checksec"
checksec --file="$BIN" || true
echo "[r2] strings (top 40 uniq)"
strings -n 4 "$BIN" | sort -u | head -n 40 || true
echo "[r2] analysis summary"
r2 -2qc "aaa; afl~main; iI~arch; iS~.text" "$BIN" || true
