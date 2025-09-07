#!/usr/bin/env bash
set -euo pipefail

# Quality-of-life symlinks
ln -sf /opt/tools/ai-angr-solve.py  /usr/local/bin/ai-angr-solve
ln -sf /opt/tools/ai-r2-quick.sh    /usr/local/bin/ai-r2-quick
ln -sf /opt/tools/ai-ghidra-decompile.sh /usr/local/bin/ai-ghidra-decompile

echo "[postCreate] Tooling linked. Try: ai-r2-quick ./samples/hello-xor/hello_xor"
