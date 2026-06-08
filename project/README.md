# M4 README — INT8 MAC Accelerator
**ECE 410/510 Spring 2026 | Devdutt Mallick**

## Project Summary

Custom INT8 MAC accelerator for CNN Conv2D acceleration. Synthesized on
sky130A using OpenLane 2. AXI4-Stream 128-bit interface at 200 MHz.
3/3 co-simulation tests passing. 0.200 GFLOP/s projected throughput at 100 MHz.

## Diff from M3

No RTL changes between M3 and M4. The RTL (top.sv, compute_core.sv,
interface.sv) and testbench (tb_top.sv) are identical to M3. The synthesis
was not re-run; the M3 OpenLane results are carried forward. New in M4:
power_report.txt, benchmark_data.csv, roofline_final.png, design_justification.pdf,
and this README.

## File Catalog

### rtl/
| File | Description | Checklist |
|------|-------------|-----------|
| `rtl/top.sv` | Top-level integration module. Instantiates interface_mod which internally instantiates compute_core. Exposes AXI4-Stream slave and master ports. | Item 2 |
| `rtl/compute_core.sv` | INT8 MAC compute core. Parameterized DATA_WIDTH=8, ACC_WIDTH=32. Synchronous reset, enable gating, valid_out and done signals. | Item 2 |
| `rtl/interface.sv` | AXI4-Stream 128-bit wrapper. Unpacks {weight[7:0], activation[7:0]} from tdata, drives compute_core, returns INT32 result on master port. | Item 2 |

### tb/
| File | Description | Checklist |
|------|-------------|-----------|
| `tb/tb_top.sv` | End-to-end co-simulation testbench. Drives host-side AXI4-Stream only. Tests identity kernel (acc=45) and negative weights (acc=−12). Prints 3/3 PASS. | Item 2 |

### sim/
| File | Description | Checklist |
|------|-------------|-----------|
| `sim/final_run.log` | QuestaSim simulation transcript. 3/3 PASS. No FAIL, ERROR, or MISMATCH strings. | Item 2 |
| `sim/final_waveform.png` | Waveform screenshot showing AXI4-Stream transaction, compute activity, and result output. | Item 2 |

### synth/
| File | Description | Checklist |
|------|-------------|-----------|
| `synth/config.json` | OpenLane 2 configuration. Clock 10 ns, design compute_core, sky130A PDK. | Item 3 |
| `synth/openlane_run.log` | Full OpenLane 2 stdout from Docker run May 15 2026. Flow complete 6:08. | Item 3 |
| `synth/timing_report.txt` | Post-PnR STA. WNS=+2.48 ns nominal, −1.57 ns ss corner. No hold violations. | Item 3 |
| `synth/area_report.txt` | Cell count and area. 25,614 µm² die, 9,224 µm² logic, 52.9% utilization. | Item 3 |
| `synth/power_report.txt` | IR drop analysis + activity-based estimate: ~406 µW total, 4.06 pJ/MAC. VCD not available. | Item 3 |

### bench/
| File | Description | Checklist |
|------|-------------|-----------|
| `bench/benchmark.md` | Throughput, speedup (19.4×), energy comparison (~200× better per MAC vs i5). | Item 4 |
| `bench/benchmark_data.csv` | Raw numbers backing all benchmark claims. Every reported value traceable here. | Item 4 |
| `bench/roofline_final.png` | Final roofline: i5 and sky130A rooflines, SW baseline measured point, M4 accelerator point. | Item 4 |

### report/
| File | Description | Checklist |
|------|-------------|-----------|
| `report/design_justification.pdf` | 9-section design justification report. 2,800+ words. | Item 5 |
| `report/design_justification.md` | Markdown source for the PDF. | Item 5 |
| `report/figures/fig1_block_diagram.png` | Figure 1: top.sv block diagram. Referenced in Section 4. | Item 5 |
| `report/figures/fig2_dataflow.png` | Figure 2: streaming MAC dataflow. Referenced in Section 4. | Item 5 |
| `report/figures/fig3_roofline.png` | Figure 3: final roofline plot. Referenced in Sections 2 and 8. | Item 5 |

## How to Reproduce Co-Simulation

**Tool:** QuestaSim 2021.1 or compatible

```bash
cd project/m4/rtl
vlib work
vlog -sv +acc compute_core.sv interface.sv top.sv ../tb/tb_top.sv
vsim -c tb_top -do "run -all; quit" -l ../sim/final_run.log
```

Expected: `=== Results: 3/3 PASS ===` and `PASS` on the final line.
No FAIL, ERROR, or MISMATCH anywhere in the log.

## How to Reproduce Synthesis

**Tool:** OpenLane 2 v2.3.1 via Docker

```bash
docker pull ghcr.io/efabless/openlane2:2.3.1
docker run --rm \
  -v "PATH_TO_RTL:/work" \
  -v "PATH_TO_PDK:/work/pdk" \
  ghcr.io/efabless/openlane2:2.3.1 \
  python3 -m openlane --pdk-root /work/pdk --design-dir /work /work/config.json
```

PDK: sky130A downloaded via volare on first run.
