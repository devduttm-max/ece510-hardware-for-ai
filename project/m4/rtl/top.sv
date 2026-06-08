// =============================================================================
// Module:      top
// Project:     INT8 MAC Accelerator for CNN Conv2D Acceleration
// Course:      ECE 410/510 Spring 2026
// Author:      Devdutt Mallick
// Description: Top-level integration module for M3. Instantiates interface_mod
//              which internally contains compute_core, forming the complete
//              end-to-end pipeline from AXI4-Stream host input to accumulated
//              INT8 MAC result output.
//
// Glue logic:  None required. interface_mod already instantiates compute_core
//              and wires all inter-module signals internally. The top module
//              exposes only the AXI4-Stream slave and master ports plus clock
//              and reset.
//
// Port list:
//   clk            - system clock, rising edge triggered
//   rst            - synchronous active-high reset
//   s_axis_tdata   [15:0] - packed {weight[7:0], activation[7:0]} from host
//   s_axis_tvalid  - host asserts when input data is valid
//   s_axis_tready  - accelerator ready to accept data (driven by interface_mod)
//   s_axis_tlast   - host asserts on final beat of dot-product window
//   m_axis_tdata   [31:0] - INT32 accumulated result returned to host
//   m_axis_tvalid  - result valid, asserted one cycle after input beat
//   m_axis_tready  - host ready to accept result
//   m_axis_tlast   - mirrors s_axis_tlast, one cycle delayed
// =============================================================================

module top #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  logic                    clk,
    input  logic                    rst,

    // AXI4-Stream slave (host -> accelerator)
    input  logic [2*DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                    s_axis_tvalid,
    output logic                    s_axis_tready,
    input  logic                    s_axis_tlast,

    // AXI4-Stream master (accelerator -> host)
    output logic [ACC_WIDTH-1:0]    m_axis_tdata,
    output logic                    m_axis_tvalid,
    input  logic                    m_axis_tready,
    output logic                    m_axis_tlast
);

    // -------------------------------------------------------------------------
    // Instantiate interface_mod (which internally instantiates compute_core)
    // No additional glue logic required between interface and compute core.
    // -------------------------------------------------------------------------
    interface_mod #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) u_interface (
        .clk           (clk),
        .rst           (rst),
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .s_axis_tlast  (s_axis_tlast),
        .m_axis_tdata  (m_axis_tdata),
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready),
        .m_axis_tlast  (m_axis_tlast)
    );

endmodule