// =============================================================================
// Module:      compute_core
// Project:     INT8 MAC Accelerator for CNN Conv2D Acceleration
// Course:      ECE 410/510 Spring 2026
// Author:      Devdutt Mallick
// Description: Parameterized INT8 multiply-accumulate compute core.
//              Accepts signed 8-bit activation and weight inputs, accumulates
//              products into a 32-bit signed register. Designed to accelerate
//              the Conv2D._im2col kernel identified as memory-bound at
//              1.057 FLOP/byte on Intel i5-1135G7.
//
// Interface:
//   clk        - system clock (rising edge triggered)
//   rst        - synchronous active-high reset, clears accumulator to 0
//   en         - enable: when high, performs MAC operation each cycle
//   activation - signed 8-bit input activation (from image patch)
//   weight     - signed 8-bit filter weight (preloaded, stationary)
//   valid_in   - asserted when activation and weight inputs are valid
//   acc_out    - signed 32-bit accumulated result
//   valid_out  - registered, asserted one cycle after valid_in
//   done       - asserted when rst deasserts after computation (one cycle)
//
// Precision:   INT8 inputs, INT32 accumulator
//              Product of two INT8 values is 16-bit; sign-extended to 32-bit
//              before accumulation to prevent overflow.
// =============================================================================

module compute_core #(
    parameter DATA_WIDTH = 8,   // Width of activation and weight inputs (INT8)
    parameter ACC_WIDTH  = 32   // Width of accumulator (INT32)
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         en,
    input  logic                         valid_in,
    input  logic signed [DATA_WIDTH-1:0] activation,
    input  logic signed [DATA_WIDTH-1:0] weight,
    output logic signed [ACC_WIDTH-1:0]  acc_out,
    output logic                         valid_out,
    output logic                         done
);

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic signed [2*DATA_WIDTH-1:0] product;   // 16-bit signed product
    logic                           rst_prev;   // previous cycle rst for done pulse

    // -------------------------------------------------------------------------
    // Multiply: combinational
    // Explicitly cast to signed to guarantee correct sign extension
    // across all synthesizers (IEEE 1800-2017)
    // -------------------------------------------------------------------------
    assign product = $signed(activation) * $signed(weight);

    // -------------------------------------------------------------------------
    // Accumulator: sequential (always_ff, synchronous reset)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            acc_out <= '0;
        else if (en && valid_in)
            acc_out <= acc_out + ACC_WIDTH'(signed'(product));
    end

    // -------------------------------------------------------------------------
    // Valid output: registered, one cycle latency after valid_in
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            valid_out <= 1'b0;
        else
            valid_out <= valid_in & en;
    end

    // -------------------------------------------------------------------------
    // Done signal: pulses high for one cycle when rst deasserts
    // Signals that accumulator has been cleared and core is ready
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            rst_prev <= 1'b1;
            done     <= 1'b0;
        end else begin
            rst_prev <= 1'b0;
            done     <= rst_prev;  // one-cycle pulse after rst falls
        end
    end

endmodule