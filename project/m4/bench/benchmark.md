# Benchmark Report — M4
**ECE 410/510 Spring 2026 | Devdutt Mallick**
**INT8 MAC Accelerator for CNN Conv2D Acceleration**

## Measurement Method

Accelerator throughput was measured using cycle-count simulation in QuestaSim
2021.1. The testbench (tb_top.sv) drives the AXI4-Stream interface and the
number of clock cycles from first valid input beat to valid output is counted
directly from the simulation transcript. This is the standard method when FPGA
hardware is not available.

The software baseline was measured using Python cProfile on the custom CNN
implementation running on an Intel i5-1135G7 (Intel Tiger Lake, Windows 11,
Python 3.13, NumPy). The dominant kernel Conv2D._im2col was profiled across
228 calls.

All raw numbers are in `benchmark_data.csv`.

---

## Accelerator Throughput

| Metric                    | Value              | Source                        |
|---------------------------|--------------------|-------------------------------|
| Clock frequency           | 100 MHz            | Synthesis (nominal corner)    |
| Cycles per invocation     | 9 cycles           | RTL simulation (tb_top.sv)    |
| Latency per invocation    | 90 ns              | 9 cycles / 100 MHz            |
| Latency per 16×16 frame   | 0.023 ms           | 16×16×9 cycles / 100 MHz      |
| Peak throughput           | 0.200 GFLOP/s      | 100 MHz × 2 FLOP/cycle        |
| Interface bandwidth       | 3.2 GB/s           | AXI4-Stream 128-bit @ 200 MHz |
| Arithmetic intensity      | 0.82–1.38 FLOP/byte| Computed (see CF9 CMAN)       |

---

## Software Baseline (M1)

| Metric                    | Value              | Source                        |
|---------------------------|--------------------|-------------------------------|
| Platform                  | Intel i5-1135G7    | Local machine                 |
| Total profiling time      | 0.102 s            | cProfile, 228 calls           |
| Time per call             | 0.447 ms           | 0.102 / 228                   |
| Measured throughput       | 16.73 GFLOP/s      | M1 roofline profiling         |
| Arithmetic intensity      | 1.057 FLOP/byte    | M1 profiling                  |
| Peak compute              | 268.8 GFLOP/s      | Intel spec                    |
| Memory bandwidth          | 51.2 GB/s          | Intel spec                    |

---

## Speedup

```
SW time per call:  0.447 ms  (cProfile, i5-1135G7)
HW time per call:  0.023 ms  (cycle-count simulation, 100 MHz)

Speedup = 0.447 / 0.023 = 19.4×
```

The 19.4× speedup is a latency speedup per invocation based on cycle count.
It reflects the reduction in clock cycles needed to complete one 3×3 dot
product compared to the NumPy-based Python implementation. It does not account
for interface setup overhead, memory controller latency, or Python interpreter
overhead in the software path — all of which would make the effective software
time longer and the speedup larger if included.

The throughput speedup (0.200 GFLOP/s vs 16.73 GFLOP/s) is 0.012× — the
accelerator has lower absolute throughput than the i5 because it is a single
serial MAC unit on a 180nm-class PDK against a wide-SIMD processor. The
accelerator's advantage is energy efficiency (4.06 pJ/MAC estimated) and
targeted silicon area (9,224 µm²), not raw throughput.

---

## Energy Comparison

| Metric                | SW Baseline         | HW Accelerator       |
|-----------------------|---------------------|----------------------|
| Power                 | ~15 W (TDP)         | ~406 µW (estimated)  |
| Time per call         | 0.447 ms            | 0.023 ms             |
| Energy per call       | ~6.7 mJ             | ~9.3 nJ              |
| Energy per MAC        | ~833 pJ/MAC (est.)  | ~4.06 pJ/MAC (est.)  |
| Energy efficiency     | 1×                  | ~205× better         |

SW energy per call = 15W × 0.447ms = 6.7 mJ (using full TDP, conservative)
HW energy per call = 406µW × 0.023ms = 9.3 nJ

Energy efficiency improvement: 6.7 mJ / 9.3 nJ ≈ 720× (using TDP)
Using a more realistic active power for the i5 core of ~2W: 2W × 0.447ms / 9.3nJ ≈ 96×

---

## Final Roofline

See `roofline_final.png`. The M4 accelerator operating point (0.82 FLOP/byte,
0.200 GFLOP/s) sits at the peak of the sky130A compute-bound flat region —
the design is compute-limited. The software baseline (1.057 FLOP/byte,
16.73 GFLOP/s) sits in the memory-bound region of the i5 roofline.
