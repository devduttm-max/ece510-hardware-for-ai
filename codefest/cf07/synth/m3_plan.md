# M3 Synthesis Plan — compute_core.sv
**ECE 410/510 Spring 2026 | Codefest 7 CLLM | Devdutt Mallick**

For M3 I synthesized my actual project compute core (Option A). Based on the
CF7 synthesis results, I will make the following changes:

**Pipeline the critical path.** The -1.57 ns slack at the ss corner and the 181
inserted timing buffers indicate the combinational depth between flip-flops is
too deep for 100 MHz under slow-corner conditions. For M3 I will insert a
pipeline register in the multiply-accumulate datapath to break the critical path
into two shorter stages, targeting slack closure at the ss corner.

**Relax the clock target to 50 MHz.** The current 10 ns period is aggressive for
this combinational depth on sky130. Dropping to 20 ns (50 MHz) will likely close
timing at all corners without pipelining, giving a clean baseline before
attempting higher frequencies.

**Add proper SDC constraints.** The fallback SDC used in CF7 has no real
input/output delay constraints. For M3 I will add explicit set_input_delay and
set_output_delay matching the AXI4-Stream interface at 200 MHz to get
accurate timing numbers.

**Keep INT8 precision.** The 35 flip-flop count and 9,224 µm² area are
reasonable for the target function. No precision reduction is needed.
