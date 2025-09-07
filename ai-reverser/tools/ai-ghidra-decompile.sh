#!/usr/bin/env bash
set -euo pipefail
BIN="${1:-}"; FUNC="${2:-main}"
if [[ -z "$BIN" || ! -f "$BIN" ]]; then
  echo "Usage: ai-ghidra-decompile <binary> [function]" >&2; exit 1
fi
TMPPROJ="${HOME}/projects/gh_${RANDOM}"
mkdir -p "$TMPPROJ"
"${GHIDRA_HOME}/support/analyzeHeadless" "$TMPPROJ" ghproj \
  -import "$BIN" -scriptPath "${GHIDRA_HOME}/Ghidra/Features/Decompiler/ghidra_scripts" \
  -postScript DecompileFunction.java "$FUNC" \
  -deleteProject \
  > /dev/stdout 2>/dev/null | sed -n '/^Decompiling/,/^END DECOMPILATION/p'
