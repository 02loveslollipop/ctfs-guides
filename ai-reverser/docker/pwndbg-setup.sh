#!/usr/bin/env bash
set -e
cd /home/ctf
git clone --depth=1 https://github.com/pwndbg/pwndbg.git
cd pwndbg
./setup.sh || true
