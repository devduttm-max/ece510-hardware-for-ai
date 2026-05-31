# Roofline Analysis — CF9 CLLM
**ECE 410/510 Spring 2026 | Devdutt Mallick**

The accelerator projected operating point (0.2 GFLOP/s at AI = 0.82) lands
on the flat compute-bound region of the sky130A roofline, exactly at the peak.
This is expected because the ridge point of the sky130A target (0.063 FLOP/byte)
is far to the left of the kernel's arithmetic intensity range (0.82–1.38
FLOP/byte). The design is compute-limited, not interface-limited.

The dominant uncertainty in this projection is the clock frequency assumption.
The synthesis closes timing at nominal corner (tt_025C_1v80) with +2.48 ns
slack at 100 MHz, but fails at the slow corner (ss_100C_1v60) with -1.57 ns.
If the design is derated to 65 MHz to close timing at all corners, the projected
throughput drops from 0.2 GFLOP/s to approximately 0.13 GFLOP/s, shifting the
operating point down but remaining on the compute-bound flat region.

The gap between the SW baseline (16.73 GFLOP/s on i5) and the accelerator
(0.2 GFLOP/s projected on sky130A) is expected and not a design failure.
The SW baseline benefits from a 268.8 GFLOP/s peak processor with wide SIMD
units running NumPy's optimized matrix operations, while the accelerator is a
single serial MAC unit. The accelerator advantage is in energy efficiency and
targeted area, not raw throughput against a general-purpose CPU. Converting
the projection to a measurement requires running a gate-level simulation with
a VCD activity file and comparing cycle counts directly against the SW profiling
data from M1.
