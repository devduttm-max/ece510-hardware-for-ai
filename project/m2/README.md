# Milestone 2 — INT8 MAC Accelerator

**Course:** ECE 410/510 — Spring 2026  
**Author:** Devdutt Mallick

## Overview

Milestone 2 implements and verifies the two core RTL modules for the INT8 MAC
accelerator: the compute core and the AXI4-Stream interface wrapper. Both
modules are written in synthesizable SystemVerilog and verified with directed
testbenches using Icarus Verilog.

## Repository structure

```
project/m2/
├── README.md              ← this file
├── precision.md           ← numeric precision analysis (INT8 justification)
├── compute_core.sv        ← signed INT8 multiply-accumulate engine
├── interface.sv           ← AXI4-Stream wrapper around compute core
├── tb_compute_core.sv     ← testbench for compute core (14 tests)
├── tb_interface.sv        ← testbench for interface module (10 tests)
├── compute_core.log       ← simulation output for compute core
├── interface.log          ← simulation output for interface module
└── waveform.png           ← GTKWave screenshot of interface simulation
```

## Module descriptions

### compute_core

Performs signed 8-bit × 8-bit multiply-accumulate into a 32-bit accumulator.
Accepts `activation` and `weight` inputs with a `valid_in` enable signal.
The accumulator is cleared on reset and the `done` signal pulses one cycle
after reset deasserts to indicate readiness. `valid_out` follows `valid_in`
by one cycle to reflect the registered output.

### interface (interface_mod)

Wraps `compute_core` with AXI4-Stream slave (input) and master (output) ports.
Input data is packed as `{weight[7:0], activation[7:0]}` in a 16-bit TDATA
field. The module performs the AXI4-Stream handshake (TVALID/TREADY) and
forwards the 32-bit accumulator result on the master port. TLAST is registered
to align with the one-cycle compute latency.

The module is named `interface_mod` because `interface` is a SystemVerilog
reserved keyword.

## Simulation results

### compute_core — 14/14 tests passed

Tests cover: reset behavior, basic multiplication, accumulation across
multiple cycles, negative × positive, negative × negative, zero inputs,
boundary values (−128 × 127, −128 × −128), multi-cycle accumulation,
enable gating (valid_in low), valid_out latency, done signal behavior,
re-accumulation after reset, and large accumulation sequences.

### interface — 10/10 tests passed

Tests cover: reset state, single-word transfer, back-to-back streaming,
TLAST propagation, backpressure handling (TREADY deasserted), stall and
resume, accumulation over a multi-beat burst, reset mid-stream, maximum
positive and negative values, and pass/fail counter verification.

## Waveform

The waveform screenshot (`waveform.png`) shows a GTKWave capture of the
interface testbench simulation. Visible signals include the AXI4-Stream
handshake (TVALID, TREADY, TDATA, TLAST) on both slave and master ports,
along with the pass and fail counters. The waveform confirms correct
handshake timing and data flow through the compute core.

## Build and run

```bash
# Compile and simulate compute core
iverilog -g2012 -o tb_compute_core tb_compute_core.sv compute_core.sv
vvp tb_compute_core | tee compute_core.log

# Compile and simulate interface
iverilog -g2012 -o tb_interface tb_interface.sv interface.sv compute_core.sv
vvp tb_interface | tee interface.log
```

## Precision summary

INT8 signed integers are used for activations and weights. A 32-bit
accumulator provides sufficient headroom for dot products up to 65,536 MACs
without overflow risk. This format delivers near-FP32 inference accuracy
(within 1–2% on ImageNet) at roughly 18.5× less area and 30× less energy
per operation compared to FP32. Full analysis is in `precision.md`.
