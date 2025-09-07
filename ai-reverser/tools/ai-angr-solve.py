#!/usr/bin/env python3
import angr, claripy, sys

if len(sys.argv) < 3:
    print("Usage: ai-angr-solve <binary> <success_substr>", file=sys.stderr)
    sys.exit(1)

binary = sys.argv[1]
success_sub = sys.argv[2].encode()

proj = angr.Project(binary, auto_load_libs=False)
flag_len = 32
flag = claripy.BVS('flag', 8 * flag_len)
state = proj.factory.full_init_state(stdin=flag)
for c in flag.chop(8):
    state.solver.add(c >= 0x20, c <= 0x7e)  # printable

simgr = proj.factory.simulation_manager(state)
def is_good(s): return success_sub in s.posix.dumps(1)
def is_bad(s):  return b"try again" in s.posix.dumps(1).lower()

simgr.explore(find=is_good, avoid=is_bad)
if simgr.found:
    m = simgr.found[0]
    print(m.solver.eval(flag, cast_to=bytes).decode(errors='ignore'))
else:
    print("No solution found")
