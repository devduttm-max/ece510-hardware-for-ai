# Benchmark Results — CF9 CLLM
**ECE 410/510 Spring 2026 | Devdutt Mallick**

## Platform Notes

- **SW baseline:** Intel i5-1135G7, Windows 11, Python 3.13, NumPy (custom CNN, no PyTorch)
- **HW accelerator:** QuestaSim 2021.1 co-simulation, sky130A target
- **Workload:** Conv2D._im2col dominant kernel, 16×16 input feature map, 3×3 kernel, 1 input channel

---

## Results Table

| Metric                  | SW Baseline (measured)         | HW Accelerator (projected)              |
|-------------------------|--------------------------------|------------------------------------------|
| Platform                | Intel i5-1135G7                | sky130A ASIC, 100 MHz                   |
| Execution time          | 0.102 s (228 calls total)      | 4.52 ms per 16×16 frame (projected)     |
| Time per call           | 0.447 ms per call (measured)   | 0.023 ms per call (projected)           |
| Peak compute            | 268.8 GFLOP/s                  | 0.2 GFLOP/s (projected)                 |
| Measured/projected perf | 16.73 GFLOP/s (measured)       | 0.2 GFLOP/s (projected, compute-bound) |
| Memory usage            | ~512 KB (im2col buffer)        | ~18 bytes per invocation (streaming)    |
| Interface bandwidth     | 51.2 GB/s DRAM                 | 3.2 GB/s AXI4-Stream                   |
| Arithmetic intensity    | 1.057 FLOP/byte (measured)     | 0.82–1.38 FLOP/byte (computed)          |
| Co-sim verification     | N/A                            | 3/3 PASS (tb_top.sv)                    |

---

## Speedup Computation

**Throughput speedup (per invocation):**

```
SW time per call:  0.447 ms
HW time per call:  0.023 ms (projected at 100 MHz, 9 cycles/invocation)

Speedup = 0.447 / 0.023 ≈ 19.4×  (projected)
```

Note: This speedup is projected from the synthesis clock frequency and cycle count.
It does not account for interface overhead, memory latency, or bus arbitration.
A measured speedup will be computed in M4 after full benchmark instrumentation.

**Energy efficiency:**
Full dynamic power estimation requires a VCD-based switching activity analysis
which will be completed in M4. Static leakage estimate from sky130_fd_sc_hd
library: approximately 140 µW. Full dynamic power target: < 5 mW at 100 MHz.

---

## Projection Assumptions

1. Clock frequency: 100 MHz (timing passes at nominal corner, fails at ss corner)
2. Cycles per invocation: 9 (one MAC per cycle, streaming, no pipelining)
3. Latency per 16×16 frame: 16 × 16 × 9 cycles / 100 MHz = 0.023 ms
4. Interface does not stall (AXI4-Stream 128-bit @ 200 MHz provides 3.2 GB/s,
   sufficient for streaming INT8 data at the required rate)
5. No memory controller latency modeled (off-chip DRAM latency not included)

All projected numbers are labeled **[PROJECTED]** in this document and in M4.
