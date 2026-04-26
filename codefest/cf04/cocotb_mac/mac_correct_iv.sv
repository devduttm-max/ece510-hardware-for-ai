`timescale 1ns/1ps
// Iverilog-compatible wrapper of ../hdl/mac_correct.sv
// Identical behaviour; only change: replaced the SV-2012 cast expression
//   out <= out + 32'(signed'(a * b));
// with semantically equivalent iverilog-compatible code.
//
// The cast 32'(signed'(a * b)) widens the signed 8-bit product to 32 bits.
// Because iverilog evaluates 'a * b' in a self-determined 8-bit context (which
// would truncate 127*127 = 16129 → 1), we must explicitly sign-extend the
// operands to 16 bits first, giving a full-precision 16-bit product that then
// sign-extends to 32 bits in the accumulator addition.
//
// Original: LLM A (Claude Sonnet 4.6)

module mac (
    input  logic        clk,
    input  logic        rst,
    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,
    output logic signed [31:0] out
);

    // Sign-extend inputs to 16 bits so the multiplication produces a full
    // 16-bit product (no 8-bit truncation).
    logic signed [15:0] a16, b16;
    always_comb begin
        a16 = $signed(a);   // sign-extends 8→16
        b16 = $signed(b);
    end

    always_ff @(posedge clk) begin
        if (rst)
            out <= 32'sd0;
        else
            out <= out + a16 * b16;  // 16-bit product sign-extends to 32-bit sum
    end

endmodule
