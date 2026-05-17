# Project Scope Assessment
**ECE 410/510 Spring 2026 | Devdutt Mallick**
**Updated: May 15, 2026 (post-CF7 synthesis)**

## Project Summary

Custom INT8 MAC accelerator for CNN Conv2D acceleration, targeting the
Conv2D._im2col bottleneck profiled on the Intel i5-1135G7. The accelerator
interfaces via AXI4-Stream 128-bit at 200 MHz (3.2 GB/s) and performs INT8
multiply-accumulate operations to accelerate the memory-bound Conv2D operation
(measured arithmetic intensity: 1.057 FLOP/byte, ridge point: 5.25).

## Scope Confirmation

The project scope remains feasible and largely on track. The M2 compute_core.sv
delivered 14/14 passing simulation tests covering reset, MAC, accumulation,
negative values, enable gating, valid_out, and the done signal. The AXI4-Stream
wrapper (interface.sv) passed 10/10 tests.

## Synthesis Results (CF7)

The CF7 OpenLane synthesis on sky130A at 10 ns (100 MHz) produced the following
key numbers:

- **Die area:** 154.775 × 165.495 µm (25,614 µm²)
- **Logic cell area:** ~9,224 µm² at 52.9% utilization
- **Sequential cells:** 35 flip-flops (dfxtp_1)
- **DRC:** Clean ✅
- **LVS:** Circuits match uniquely ✅
- **Timing:** Passes at nominal and fast corners; setup violations at
  ss_100C_1v60 corner with WNS = -1.57 ns

## Scope Adjustments for M3

Based on the synthesis results, two targeted adjustments are made to the project
scope:

1. **Clock target relaxed to 50 MHz for initial M3 submission.** The -1.57 ns
   ss-corner slack and 181 inserted timing repair buffers show the current
   combinational depth cannot close timing at 100 MHz under worst-case
   conditions. 50 MHz provides a clean timing closure baseline across all
   corners. A pipelined version targeting 100 MHz will be attempted if time
   allows.

2. **Pipeline stage added to compute_core.** A 2-stage pipeline (multiply in
   stage 1, accumulate in stage 2) will be implemented to reduce combinational
   depth and recover the 100 MHz target in a follow-up iteration. This is
   already prototyped in compute_core_v2.sv.

All other project parameters remain unchanged: INT8 precision (MAE=0.005148,
max error=0.009728, MAC relative error=0.26%), AXI4-Stream interface, and
Conv2D acceleration scope. The area and utilization numbers from CF7 confirm
the design is well within a reasonable silicon footprint for the target
function.
