# Synthesis Interpretation — compute_core.sv
**ECE 410/510 Spring 2026 | Codefest 7 CLLM | Devdutt Mallick**

## Clock Period and Worst-Case Slack

The synthesis was run at a 10 ns clock period (100 MHz) targeting the sky130A PDK
with the sky130_fd_sc_hd standard cell library. The design passes timing at the
nominal corner (tt_025C_1v80) and the fast corner (ff_n40C_1v95) with positive
slack. However, setup violations were found at the slow-slow corner
(ss_100C_1v60) across all three extraction corners (nom, min, max). The
worst-case slack during timing repair was approximately -1.57 ns at the ss corner,
meaning the design cannot close timing at 100 MHz under worst-case
process/voltage/temperature conditions. No hold violations were found in any
corner.

## Critical Path

The timing repair log identifies register _2027_/D and _2042_/D as the sink
endpoints of the worst setup paths. The resizer inserted 83 buffers and resized
200 instances during post-CTS timing repair in an attempt to close the critical
path but was unable to fully resolve the ss-corner violations. The dominant cell
types along the critical path are multi-input combinational cells (a21o, o211a,
xnor2 families) driving flip-flop inputs, with delay compounded by the slow
process corner reducing drive strength and increasing propagation delay
significantly.

## Total Cell Area and Top Contributors

Total logic cell area (excluding filler and tap cells) is approximately
**9,224 µm²** after timing repair, within a die area of **154.775 × 165.495 µm
(25,614 µm²)** at 52.9% utilization. The top three contributors by area are:

1. **Multi-input combinational cells** — 989 instances, 7,477 µm² (dominant)
2. **Timing repair buffers** — 181 instances, 1,274 µm²
3. **Sequential cells (dfxtp_1)** — 35 flip-flop instances, 701 µm²

The 181 inserted timing buffers represent significant overhead added to repair
the 21 setup-violating endpoints, indicating the combinational logic depth is
the primary bottleneck.

## Warnings Worth Investigating

The most significant warning is `RSZ-0062: Unable to repair all setup violations`
in the ss_100C_1v60 corner. This is a real constraint failure, not a benign
warning. The `PNR_SDC_FILE` and `SIGNOFF_SDC_FILE` not defined warnings indicate
the generic fallback SDC was used, meaning no custom input/output delay constraints
were applied — the actual timing budget may differ once real interface constraints
are added for M3. The `VSRC_LOC_FILES` warning for IR drop can be ignored since
this is not a full chip integration.
