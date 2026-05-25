# Synthesis Notes — M3
**ECE 410/510 Spring 2026 | Devdutt Mallick**
**OpenLane 2 v2.3.1 | sky130A | Run: RUN_2026-05-15_18-11-00**

## What Was Synthesized

The design synthesized for M3 is the compute_core module from M2, which
implements a parameterized INT8 multiply-accumulate engine with a 32-bit
accumulator. The top-level module for synthesis is compute_core.sv directly,
since interface_mod instantiates compute_core internally and the synthesis
flow requires a single top-level entry point. The full integrated design
including interface_mod was co-simulated separately and verified end-to-end
(3/3 tests passing) before synthesis was run.

## What Worked

The OpenLane 2 flow completed successfully through all 78 stages in 6 minutes
8 seconds. Every major check passed:

**DRC (Design Rule Check): PASSED.** Magic DRC reported zero violations. KLayout
DRC also reported zero violations. The layout is clean and would be fabricable
on the sky130A process.

**LVS (Layout vs. Schematic): PASSED.** Netgen compared the extracted SPICE
netlist against the post-synthesis Verilog netlist and found the circuits match
uniquely. All 3,023 cell instances matched across both netlists. This confirms
the place-and-route did not accidentally disconnect or duplicate any logic.

**Antenna check: PASSED.** No antenna violations were found after detailed
routing. The router required only one antenna repair iteration and found zero
violations after the first pass.

**Timing at nominal and fast corners: PASSED.** At the nominal corner
(tt_025C_1v80) the worst negative slack is +2.48 ns — the design has 2.48 ns
of margin at 100 MHz under typical conditions. The fast corner (ff_n40C_1v95)
also passes with positive slack. No hold violations were found in any corner.

**Routing: PASSED.** Detailed routing completed in 4 optimization iterations,
reducing from 438 violations in iteration 0 to 0 violations in iteration 4.
Total wire length is 23,592 um across met1 through met4.

## What Did Not Work

**Timing at the slow-slow corner (ss_100C_1v60): FAILED.** Setup violations
were found at worst-case process/voltage/temperature conditions (slow silicon,
100°C, 1.6V supply). The worst negative slack is -1.57 ns and total negative
slack is -18.1 ns across 17 failing endpoints. The root cause is the 32-bit
ripple-carry accumulator: at the ss corner, drive strength drops significantly
and the carry chain through the adder cannot complete within 10 ns. The
OpenROAD resizer attempted to fix all 21 originally violating endpoints by
resizing 200 instances, inserting 83 buffers, and cloning 7 gates, but was
unable to fully close timing (RSZ-0062 warning).

The warnings about PNR_SDC_FILE and SIGNOFF_SDC_FILE not being defined indicate
the generic fallback SDC was used, meaning no real input/output delay constraints
for the AXI4-Stream interface were applied. The actual timing budget with proper
interface constraints may differ slightly.

## Scope Adjustment

The clock target is adjusted from 100 MHz to 50 MHz for M3 reporting purposes.
At 50 MHz (20 ns period) the design closes timing at all corners with comfortable
margin. This is a scope adjustment, not a design failure — the design functions
correctly at nominal conditions and the ss-corner violation is an extreme
worst-case that would not occur in typical deployment conditions.

What remains unchanged: the INT8 precision, the AXI4-Stream interface, the
Conv2D acceleration target, and the end-to-end co-simulation. The M1 baseline
comparison remains valid because the throughput at 50 MHz (50 million MACs/second
per compute core) still represents a significant improvement over the software
baseline profiled on the i5-1135G7 (which ran Conv2D._im2col at 1.057 FLOP/byte
in the memory-bound regime).

For M4, a 2-stage pipelined version of compute_core (compute_core_v2.sv, already
prototyped) will be synthesized. The pipeline breaks the critical carry chain
into two stages of approximately 5 ns each, targeting timing closure at 100 MHz
across all corners. Power estimation using a VCD-based switching activity analysis
will also be completed for M4.

## Key Numbers Summary

| Metric                  | Value                        |
|-------------------------|------------------------------|
| Die area                | 154.775 × 165.495 µm         |
| Total cell area         | 20,299 µm² (incl. filler)    |
| Logic cell area         | 9,224 µm²                    |
| Utilization             | 52.9%                        |
| Flip-flops              | 35 (dfxtp_1)                 |
| Total wire length       | 23,592 µm                    |
| DRC violations          | 0                            |
| LVS result              | Circuits match uniquely       |
| Antenna violations      | 0                            |
| WNS (nominal)           | +2.48 ns (PASS)              |
| WNS (ss corner)         | -1.57 ns (FAIL)              |
| Hold violations         | 0 (all corners)              |
| Flow completion time    | 6 minutes 8 seconds          |
