---
applyTo: '**'
---

## Workflow
1. **Get context first**:
   - Always ask (or check prompt context) for:
     - Path to the executable (e.g., `/work/challs/crackme`).
     - The goal (e.g., "find the flag", "understand algorithm", "patch check").
   - If not specified, request clarification before running commands.

2. **Basic triage** (always start here):
   - `file <bin>` → architecture & format.
   - `checksec --file=<bin>` → protections.
   - `strings -n 4 <bin> | head` → quick hints.
   - `ai-r2-quick <bin>` → run the helper script to list main function, arch, sections.

3. **Deeper analysis**:
   - Use radare2: `r2 -AAA <bin>` and `afl`, `pdf @main`.
   - Use Ghidra headless script: `ai-ghidra-decompile <bin> main` or target function.
   - If needed: symbolic execution with `ai-angr-solve <bin> <success_substr>`.

4. **Dynamic checks**:
   - Run with `./bin` (if safe, small CTF crackme).
   - Debug with `gdb -q ./bin` and `starti`.

5. **Summarize findings**:
   - Explain what the binary does (e.g., compares input to constant, checksum, xor loop).
   - Give next step: patch, derive input, brute force.

6. **Safety rules**:
   - Never run unknown binaries with network. Default to `--network=none`.
   - Only run with QEMU if architecture mismatch.
   - Always use `/work` as the workspace for files.

## Good agent behavior
- When you produce output, also summarize what it means (“NX enabled means no stack exec, so ROP instead of shellcode”).  
- Keep command outputs concise (use `head`, grep, summarize).  
- Prefer using the provided helper scripts (`ai-r2-quick`, `ai-ghidra-decompile`, `ai-angr-solve`) before raw long tool commands.  
- Suggest next logical steps rather than dumping raw info.
# Copilot Agent Instructions for Reversing

## Workflow
1. **Get context first**:
   - Always ask (or check prompt context) for:
     - Path to the executable (e.g., `/work/challs/crackme`).
     - The goal (e.g., "find the flag", "understand algorithm", "patch check").
   - If not specified, request clarification before running commands.

2. **Basic triage** (always start here):
   - `file <bin>` → architecture & format.
   - `checksec --file=<bin>` → protections.
   - `strings -n 4 <bin> | head` → quick hints.
   - `ai-r2-quick <bin>` → run the helper script to list main function, arch, sections.

3. **Deeper analysis**:
   - Use radare2: `r2 -AAA <bin>` and `afl`, `pdf @main`.
   - Use Ghidra headless script: `ai-ghidra-decompile <bin> main` or target function.
   - If needed: symbolic execution with `ai-angr-solve <bin> <success_substr>`.

4. **Dynamic checks**:
   - Run with `./bin` (if safe, small CTF crackme).
   - Debug with `gdb -q ./bin` and `starti`.

5. **Summarize findings**:
   - Explain what the binary does (e.g., compares input to constant, checksum, xor loop).
   - Give next step: patch, derive input, brute force.

6. **Safety rules**:
   - Never run unknown binaries with network. Default to `--network=none`.
   - Only run with QEMU if architecture mismatch.
   - Always use `/work` as the workspace for files.

## Good agent behavior
- When you produce output, also summarize what it means (“NX enabled means no stack exec, so ROP instead of shellcode”).  
- Keep command outputs concise (use `head`, grep, summarize).  
- Prefer using the provided helper scripts (`ai-r2-quick`, `ai-ghidra-decompile`, `ai-angr-solve`) before raw long tool commands.  
- Suggest next logical steps rather than dumping raw info.
