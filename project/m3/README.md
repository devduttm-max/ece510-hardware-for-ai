# M3 README — INT8 MAC Accelerator
**ECE 410/510 Spring 2026 | Devdutt Mallick**

## Overview

Milestone 3 integrates the M2 compute_core and interface_mod modules into a
top-level design, verifies end-to-end data flow via co-simulation, and reports
OpenLane 2 synthesis results on the sky130A PDK.

---

## File Catalog

### rtl/
| File | Description |
|------|-------------|
| `rtl/top.sv` | Top-level integration module. Instantiates interface_mod (which internally instantiates compute_core). Exposes AXI4-Stream slave and master ports. No glue logic required. |
| `rtl/compute_core.sv` | INT8 MAC compute core from M2. Parameterized DATA_WIDTH=8, ACC_WIDTH=32. |
| `rtl/interface.sv` | AXI4-Stream wrapper from M2. Unpacks {weight, activation} from tdata, drives compute_core, returns 32-bit result on master port. |

### tb/
| File | Description |
|------|-------------|
| `tb/tb_top.sv` | End-to-end co-simulation testbench. Drives host-side AXI4-Stream only. Tests 3x3 identity kernel (activations 1-9, expected=45) and negative weight case (expected=-12). Prints PASS/FAIL. |

### sim/
| File | Description |
|------|-------------|
| `sim/cosim_run.log` | QuestaSim simulation transcript. Shows 3/3 PASS including PASS on final line. |
| `sim/cosim_waveform.png` | Waveform screenshot showing host write transaction, compute activity, and host read of result. |

### synth/
| File | Description |
|------|-------------|
| `synth/config.json` | OpenLane 2 configuration. Clock period 10 ns, design name compute_core, sky130A PDK. |
| `synth/openlane_run.log` | Full OpenLane 2 stdout captured from Docker run on May 15, 2026. |
| `synth/timing_report.txt` | Post-PnR STA results for all 9 corners. WNS=+2.48ns nominal, -1.57ns ss corner. |
| `synth/area_report.txt` | Cell count and area breakdown. Total logic 9,224 µm², 52.9% utilization. |
| `synth/power_report.txt` | IR drop analysis and power estimation attempt. Full VCD-based power deferred to M4. |
| `synth/critical_path.md` | Critical path identification: accumulator carry chain, start/end points, and fix plan. |
| `synth/synthesis_notes.md` | Narrative (500+ words): what worked, what did not, scope adjustment rationale. |
| `synth/metrics.json` | Raw OpenLane 2 metrics JSON from final/ directory of the synthesis run. |
| `synth/synth_interpretation.md` | CF7 synthesis interpretation carried forward. |

---

## How to Reproduce Co-Simulation

**Simulator:** QuestaSim 2021.1 (ModelSim-compatible)

```bash
cd project/m3/rtl
vlib work
vlog -sv +acc compute_core.sv interface.sv top.sv ../tb/tb_top.sv
vsim -c tb_top -do "run -all; quit" -l ../sim/cosim_run.log
```

Expected output: `PASS` on the final summary line.

---

## How to Reproduce Synthesis

**Tool:** OpenLane 2 v2.3.1 via Docker

```bash
docker pull ghcr.io/efabless/openlane2:2.3.1

docker run --rm \
  -v "D:/SPRING_2026/ECE 510/project/m3/rtl:/work" \
  -v "D:/SPRING_2026/ECE 510/project/m3/synth/pdk:/work/pdk" \
  ghcr.io/efabless/openlane2:2.3.1 \
  python3 -m openlane --pdk-root /work/pdk --design-dir /work /work/config.json
```

PDK: sky130A (downloaded automatically by volare on first run)
Config: `synth/config.json`

---

## Scope Adjustment

Clock target relaxed from 100 MHz to 50 MHz due to setup violations at the
ss_100C_1v60 corner (WNS = -1.57 ns). Design passes timing at nominal and fast
corners. Pipelined version (compute_core_v2.sv) targeting 100 MHz closure at
all corners is planned for M4. See `synth/synthesis_notes.md` for full rationale.
