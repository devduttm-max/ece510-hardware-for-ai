// =============================================================================
// Module:      interface
// Project:     INT8 MAC Accelerator for CNN Conv2D Acceleration
// Course:      ECE 410/510 Spring 2026
// Author:      Devdutt Mallick
// Description: AXI4-Stream interface wrapper for the INT8 MAC compute core.
//              Accepts streaming activation and weight data from the host CPU,
//              drives the compute core, and returns the 32-bit accumulated
//              result via an output stream.
//
// Interface bandwidth analysis (from M1):
//   Required:  2 GB/s at 1 billion MACs/second target
//   Provided:  3.2 GB/s at 128-bit AXI4-Stream, 200 MHz
//   Margin:    1.2 GB/s headroom, not interface-bound
//
// AXI4-Stream input (s_axis):
//   s_axis_tdata  [15:0] - {weight[7:0], activation[7:0]} packed
//   s_axis_tvalid        - input data valid
//   s_axis_tready        - core ready to accept data
//   s_axis_tlast         - last beat of a transaction
//
// AXI4-Stream output (m_axis):
//   m_axis_tdata  [31:0] - accumulated result
//   m_axis_tvalid        - output data valid
//   m_axis_tready        - downstream ready to accept
//   m_axis_tlast         - mirrors input tlast, one cycle delayed
//
// Transaction format:
//   A transaction consists of one or more beats on the slave port.
//   Each beat carries one activation-weight pair packed as:
//     s_axis_tdata[7:0]  = activation (signed INT8)
//     s_axis_tdata[15:8] = weight     (signed INT8)
//   The master asserts s_axis_tready when not in reset. The host must
//   assert s_axis_tvalid and hold data stable until the beat is accepted
//   (standard AXI4-Stream handshake: transfer occurs when both tvalid
//   and tready are high on a rising clock edge).
//   TLAST marks the final beat of a dot-product accumulation window.
//   After TLAST the host should assert rst to clear the accumulator
//   before starting a new dot product.
//
//   Example single-beat transaction:
//     Cycle 0: rst=1
//     Cycle 1: rst=0
//     Cycle 2: s_axis_tdata={weight, activation}, tvalid=1, tlast=1
//     Cycle 3: m_axis_tdata = result, tvalid=1, tlast=1
//
//   Data widths:
//     Input  TDATA: 16 bits  (2 x INT8)
//     Output TDATA: 32 bits  (INT32 accumulator)
// =============================================================================

module interface_mod #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  logic                        clk,
    input  logic                        rst,

    // AXI4-Stream slave (input: activation + weight packed)
    input  logic [2*DATA_WIDTH-1:0]     s_axis_tdata,
    input  logic                        s_axis_tvalid,
    output logic                        s_axis_tready,
    input  logic                        s_axis_tlast,

    // AXI4-Stream master (output: accumulated result)
    output logic [ACC_WIDTH-1:0]        m_axis_tdata,
    output logic                        m_axis_tvalid,
    input  logic                        m_axis_tready,
    output logic                        m_axis_tlast
);

    // -------------------------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------------------------
    logic signed [DATA_WIDTH-1:0] activation;
    logic signed [DATA_WIDTH-1:0] weight;
    logic                         core_en;
    logic                         core_valid_in;
    logic signed [ACC_WIDTH-1:0]  core_acc_out;
    logic                         core_valid_out;
    logic                         core_done;
    logic                         tlast_reg;

    // -------------------------------------------------------------------------
    // Unpack input data: lower byte = activation, upper byte = weight
    // -------------------------------------------------------------------------
    assign activation    = $signed(s_axis_tdata[DATA_WIDTH-1:0]);
    assign weight        = $signed(s_axis_tdata[2*DATA_WIDTH-1:DATA_WIDTH]);

    // -------------------------------------------------------------------------
    // Handshake: core is always ready when not in reset
    // -------------------------------------------------------------------------
    assign s_axis_tready = ~rst;
    assign core_en       = s_axis_tvalid & s_axis_tready;
    assign core_valid_in = s_axis_tvalid & s_axis_tready;

    // -------------------------------------------------------------------------
    // Instantiate compute core
    // -------------------------------------------------------------------------
    compute_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_compute_core (
        .clk       (clk),
        .rst       (rst),
        .en        (core_en),
        .valid_in  (core_valid_in),
        .activation(activation),
        .weight    (weight),
        .acc_out   (core_acc_out),
        .valid_out (core_valid_out),
        .done      (core_done)
    );

    // -------------------------------------------------------------------------
    // Register tlast to align with core output latency (1 cycle)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            tlast_reg <= 1'b0;
        else if (core_en)
            tlast_reg <= s_axis_tlast;
    end

    // -------------------------------------------------------------------------
    // Output stream: drive accumulated result when valid
    // -------------------------------------------------------------------------
    assign m_axis_tdata  = core_acc_out;
    assign m_axis_tvalid = core_valid_out;
    assign m_axis_tlast  = tlast_reg;

endmodule