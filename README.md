# ece510-hardware-for-ai-ml

**Name:** Devdutt M.  
**Course:** ECE 410/510 Spring 2026  
**Project topic:** Custom MAC accelerator: designing an efficient INT8 multiply-accumulate unit optimized for neural network inference

---

## Course overview

This course explores the hardware foundations of artificial intelligence and machine learning. Topics include workload analysis, neural network inference, hardware accelerator design, and the trade-offs between precision, power, and performance in AI systems.

---

## Project overview

Modern AI inference on edge devices is bottlenecked by the cost of 32-bit floating-point (FP32) arithmetic. This project designs a custom Multiply-Accumulate (MAC) hardware unit that operates on 8-bit integers (INT8) instead of FP32. By reducing operand width from 32 bits to 8 bits, the design achieves a 4x improvement in memory bandwidth utilization and a simpler arithmetic datapath, making it better suited for battery-powered and resource-constrained devices. The contribution is a detailed PPA (power, performance, area) analysis of the INT8 MAC unit compared to a baseline FP32 MAC.

---

## Languages and tools

- Python — model profiling, workload analysis, cocotb testbenches
- PyTorch — ResNet-18 profiling via torchinfo
- SystemVerilog — INT8 MAC unit HDL implementation
- cocotb — hardware simulation and verification framework
- Icarus Verilog — open-source RTL simulator
- QuestaSim — industry-standard RTL simulator
- CUDA — GPU kernel implementation (CF3)
- Markdown — documentation and analysis write-ups
- Git / GitHub — version control and submission

---

## Project HDL module

The INT8 MAC compute core is implemented in `project/hdl/int8_mac_core.sv`.

**What the module does:** Accumulates signed 8-bit integer multiply-accumulate
operations into a 32-bit register. On each clock edge, when enabled, it computes
activation × weight and adds the result to the running accumulator. Reset clears
the accumulator to zero.

**Interface:** AXI4 Stream (128-bit, 200 MHz) — selected based on M1 arithmetic
intensity analysis showing 2 GB/s bandwidth requirement at 1 billion MACs/second
target throughput. AXI4 Stream at 128-bit width delivers 3.2 GB/s, providing
sufficient headroom.

**Precision:** INT8 (8-bit signed integers) for both activation and weight inputs,
32-bit signed accumulator to prevent overflow during dot product accumulation.

---

## Repository structure
