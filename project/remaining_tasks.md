# M4 Remaining Tasks
**ECE 410/510 Spring 2026 | Devdutt Mallick**

## Task 1 — Pipeline the accumulator to close ss-corner timing

The 32-bit ripple-carry accumulator is the critical path. At the ss_100C_1v60
corner the carry chain takes approximately 11.6 ns, exceeding the 10 ns clock
period by 1.57 ns. Insert a pipeline register between the multiply stage
(INT8 × INT8 → INT16 product) and the accumulate stage (INT16 + INT32 →
INT32 sum) in compute_core_v2.sv. This breaks the critical path into two stages
of approximately 4–5 ns each, targeting WNS > 0 at all corners including ss.
Re-run OpenLane synthesis and verify timing closure across all 9 corners.

## Task 2 — Replace the ripple-carry adder with a carry-save adder on the
critical accumulate path

Even after pipelining, the 32-bit adder in the accumulate stage may remain
the bottleneck at higher clock targets. Replace the inferred `+` operator in
the accumulate stage with an explicit carry-save adder (CSA) instantiation
using sky130_fd_sc_hd__full adder cells. This reduces the adder delay from
O(N) ripple-carry to O(log N) prefix structure, targeting 150 MHz operation
at the nominal corner.

## Task 3 — VCD-based switching power analysis

The M3 synthesis produces only IR drop estimates; no dynamic power numbers are
available because no VCD activity file was provided to OpenROAD. In M4, run a
gate-level simulation of compute_core_v2.sv in QuestaSim with `$dumpvars`
enabled on all nets, export the resulting VCD file, and feed it to OpenROAD
power analysis (`read_power_intent` / `report_power`). Target: dynamic power
< 5 mW at 100 MHz nominal, used to compute energy per MAC and compare against
the SW baseline energy per MAC from M1 profiling data.
