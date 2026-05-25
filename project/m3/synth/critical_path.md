# Critical Path Analysis — compute_core
**ECE 410/510 Spring 2026 | M3 | Devdutt Mallick**

## Critical Path Identification

The critical path starts at a flip-flop output in the accumulator register
chain and ends at the D input of flip-flop **_2027_/D** (and secondarily
**_2042_/D**), as identified by the OpenROAD resizer timing repair log during
the post-CTS optimization pass.

**Start point:** Output of an accumulator register (acc_out flip-flop, dfxtp_1)

**Logic stages on the path:**
1. Accumulator register Q output drives the adder network
2. 32-bit signed addition: sign-extended 16-bit product added to 32-bit accumulator — this is the dominant delay stage, involving a carry-ripple chain through multiple a21o, o211a, xnor2, and nor2 cells
3. Saturation/mux logic selecting between reset value and new accumulated value
4. Output registered at the next flip-flop D input (_2027_/D)

**End point:** Flip-flop _2027_/D (accumulator pipeline register input)

## Why This Is the Critical Path

The 32-bit accumulator addition is the bottleneck because:

1. **Carry propagation depth.** Adding a sign-extended 16-bit product to a 32-bit accumulator requires carry to ripple through up to 32 bit positions. The sky130_fd_sc_hd standard cells do not include a dedicated carry-lookahead adder — Yosys synthesizes this as a ripple-carry structure using a21o and xnor2 cells, making the delay proportional to the accumulator width.

2. **Sign extension overhead.** The product of two INT8 values is 16-bit signed. Extending this to 32-bit before addition adds a small but non-zero mux/inversion stage before the adder input.

3. **ss corner sensitivity.** At slow-slow corner (100°C, 1.6V), drive strength of each standard cell drops significantly, stretching the carry chain delay from ~7.5 ns (nominal) to ~11.6 ns (ss), which exceeds the 10 ns clock period.

## What Would Shorten It

**Option 1 — Pipeline the accumulator (planned for M4).**
Insert a register between the multiply stage and the accumulate stage. This breaks the critical path into two shorter stages: multiply (≈3 ns) and accumulate (≈7 ns), both comfortably within 10 ns even at the ss corner.

**Option 2 — Reduce clock period to 15 ns (67 MHz).**
The ss-corner WNS is -1.57 ns. Adding 2 ns margin gives a safe period of ~12 ns. Targeting 15 ns (67 MHz) would close timing at all corners without any RTL changes.

**Option 3 — Use a carry-save or Kogge-Stone adder.**
Constraining Yosys to instantiate a parallel prefix adder would reduce the carry chain depth from O(N) to O(log N). This requires a custom synthesis script and is the most complex option.

For M4 Option 1 (pipelining) will be implemented as it is the most
architecturally clean solution and directly improves throughput.
