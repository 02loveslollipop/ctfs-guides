# ai-reverser

CTF reversing & pwn toolbox for VS Code + Copilot Agent

## Features
- Disassemblers: radare2, rizin, Ghidra headless
- Debug: gdb + pwndbg, strace, ltrace
- RE/pwn toolbelt: checksec, ropper, one_gadget, patchelf, file, strings, xxd
- Python stack: pwntools, angr, capstone, r2pipe, z3-solver
- Multi-arch: qemu-user-static
- Helper scripts: ai-r2-quick, ai-ghidra-decompile, ai-angr-solve
- Optional MCP sidecars (docker-compose)

## Usage
- Open in VS Code → "Reopen in Container"
- Try:
  - `ai-r2-quick ./tools/samples/hello-xor/hello_xor`
  - `ai-ghidra-decompile ./tools/samples/hello-xor/hello_xor main`
  - `ai-angr-solve ./tools/samples/hello-xor/hello_xor "Correct"`

## Security
- Non-root user
- Default ptrace capabilities for debugging
- Workspace mounted at /work
- Optional: run with --network=none for unknown binaries
