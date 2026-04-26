// INT8 MAC Accelerator Core
// Project: Custom INT8 MAC unit for CNN Conv2D acceleration
// ECE 410/510 Spring 2026

module int8_mac_core #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    en,
    input  logic signed [DATA_WIDTH-1:0] activation,
    input  logic signed [DATA_WIDTH-1:0] weight,
    output logic signed [ACC_WIDTH-1:0]  acc_out
);

    always_ff @(posedge clk) begin
        if (rst)
            acc_out <= '0;
        else if (en)
            acc_out <= acc_out + ACC_WIDTH'(signed'(activation * weight));
    end

endmodule