# MAC Code Review — LLM A vs LLM B
## ECE 410/510 Spring 2026 — Codefest 4

---

## 1. LLM Identification

| File | LLM | Model Version |
|------|-----|---------------|
| mac_llm_A.sv | Claude | Claude Sonnet 4.6 |
| mac_llm_B.sv | Gemini | Gemini Pro |

Both LLMs were given the identical specification:

> **Module name:** mac  
> **Inputs:** clk (1-bit), rst (1-bit, active-high synchronous reset), a (8-bit signed), b (8-bit signed)  
> **Output:** out (32-bit signed accumulator)  
> **Behavior:** On each rising clock edge: if rst is high, set out to 0; else add a×b to out.  
> **Constraints:** Synthesizable SystemVerilog only. No initial blocks, no $display, no delays (#). Use always_ff.

---

## 2. Generated Code

### LLM A — Claude Sonnet 4.6 (mac_llm_A.sv)

```verilog
// LLM A: Claude Sonnet 4.6
module mac (
    input  logic        clk,
    input  logic        rst,
    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,
    output logic signed [31:0] out
);

    always_ff @(posedge clk) begin
        if (rst)
            out <= 32'sd0;
        else
            out <= out + 32'(signed'(a * b));
    end

endmodule
```

### LLM B — Gemini Pro (mac_llm_B.sv)

```verilog
// LLM B: Gemini Pro
module mac (
    input  logic               clk,
    input  logic               rst,
    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,
    output logic signed [31:0] out
);

    always_ff @(posedge clk) begin
        if (rst) begin
            out <= 32'sd0;
        end else begin
            // SystemVerilog automatically sign-extends the 16-bit product
            // of a * b to 32 bits before the addition.
            out <= out + (a * b);
        end
    end

endmodule
```

---

## 3. Compilation Results

Both files were compiled using QuestaSim 2021.1 with the `-sv` flag:

```
vlog -sv mac_llm_A.sv
-- Compiling module mac
Errors: 0, Warnings: 0

vlog -sv mac_llm_B.sv
-- Compiling module mac
Errors: 0, Warnings: 0
```

Both files compiled cleanly with zero errors and zero warnings.

---

## 4. Simulation Results

The testbench applied [a=3, b=4] for 3 cycles, asserted rst, then applied
[a=−5, b=2] for 2 cycles. mac_correct.sv was simulated using QuestaSim:

```
Cycle 1: out=12  (expect 12)  ✓
Cycle 2: out=24  (expect 24)  ✓
Cycle 3: out=36  (expect 36)  ✓
After rst: out=0 (expect 0)   ✓
Cycle 1: out=-10 (expect -10) ✓
Cycle 2: out=-20 (expect -20) ✓
Errors: 0, Warnings: 0
```

Additionally, the cocotb testbench ran 6 tests using Icarus Verilog and
mac_correct_iv.sv with all tests passing:

```
[PASS] test_reset
[PASS] test_single_accumulation
[PASS] test_accumulation_sequence
[PASS] test_negative_inputs
[PASS] test_reset_mid_accumulation
[PASS] test_max_positive
Results: 6/6 PASS
```

---

## 5. Code Review — Issues Found

### Issue 1 — Implicit sign extension without explicit cast (LLM B)

**Offending lines in mac_llm_B.sv:**
```verilog
out <= out + (a * b);
```

**Why it is wrong:**

In SystemVerilog, when two `signed [7:0]` operands are multiplied, the result
is a 16-bit signed value. When this 16-bit product is added to a 32-bit signed
accumulator without an explicit cast, the behavior depends on the tool's
interpretation of implicit type conversion rules. Some synthesizers treat the
intermediate product as unsigned before sign-extending it to 32 bits, which
produces incorrect results for negative operands.

For example, if a=-5 and b=2, the product is -10 (0xFFF6 in 16-bit two's
complement). Without explicit casting, some tools may zero-extend this to
0x0000FFF6 = 65526 instead of sign-extending to 0xFFFFFFF6 = -10, causing
completely wrong accumulation results.

**Corrected version:**
```verilog
out <= out + 32'(signed'(a * b));
```

The `signed'()` cast explicitly marks the 16-bit product as signed, and `32'()`
sign-extends it to 32 bits before addition. This is unambiguous across all
synthesizers and simulators and complies with IEEE 1800-2017.

---

### Issue 2 — Misleading comment claiming automatic sign extension (LLM B)

**Offending lines in mac_llm_B.sv:**
```verilog
// SystemVerilog automatically sign-extends the 16-bit product
// of a * b to 32 bits before the addition.
out <= out + (a * b);
```

**Why it is wrong:**

The comment claims that SystemVerilog automatically and correctly sign-extends
the product, which is misleading. The SystemVerilog LRM (IEEE 1800-2017) specifies
that implicit conversion rules depend on the context of the expression and the
tools involved. This comment could cause a designer to trust the code is correct
when it may silently produce wrong results on certain synthesizers. Misleading
comments in RTL code are dangerous because they discourage further review of the
actual logic.

**Corrected version:**

Remove the misleading comment and replace with an accurate one:
```verilog
// Explicitly sign-extend 16-bit product to 32 bits before accumulation
// to guarantee correct behavior across all synthesizers (IEEE 1800-2017)
out <= out + 32'(signed'(a * b));
```

---

### Issue 3 — iverilog incompatibility with SV-2012 cast syntax (LLM A)

**Offending lines in mac_llm_A.sv:**
```verilog
out <= out + 32'(signed'(a * b));
```

**Why it is a concern:**

While this syntax is correct per the SystemVerilog-2012 standard and synthesizes
correctly in QuestaSim and other modern tools, Icarus Verilog 12.0 does not
support the `32'(signed'(...))` cast expression syntax. This means mac_llm_A.sv
compiles in QuestaSim but fails in iverilog, which is commonly used with cocotb
testbenches. This is a tool compatibility issue rather than a logical correctness
issue, but it is important for simulation portability.

**Corrected version for iverilog compatibility:**
```verilog
logic signed [15:0] product;
assign product = $signed(a) * $signed(b);

always_ff @(posedge clk) begin
    if (rst)
        out <= 32'sd0;
    else
        out <= out + {{16{product[15]}}, product};
end
```

This version uses explicit sign extension via bit replication
(`{{16{product[15]}}, product}`) which is supported by all tools including
iverilog 12.0, while maintaining full signed arithmetic correctness.

---

## 6. Correct Implementation

Two correct versions were produced:

- **mac_correct.sv** — uses QuestaSim-compatible explicit cast syntax from
  LLM A. Passes the QuestaSim testbench with 6/6 results correct.
- **mac_correct_iv.sv** — uses iverilog-compatible sign extension from Issue 3
  above. Used for the cocotb simulation and passes all 6 cocotb tests.

Both versions implement identical behavior: synchronous active-high reset,
signed 8-bit multiply-accumulate into a 32-bit register, using always_ff
with no non-synthesizable constructs.
