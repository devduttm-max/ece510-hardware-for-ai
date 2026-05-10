// LLM: Claude Sonnet 4.6
// 4x4 Binary-Weight Crossbar MAC Unit
// ECE 410/510 Spring 2026 ? Codefest 6

module crossbar_mac (
    input  logic        clk,
    input  logic        rst,
    input  logic        en,
    input  logic signed [7:0]  in0, in1, in2, in3,
    output logic signed [31:0] out0, out1, out2, out3
);

    // Weight register array: weights[i][j] = +1 or -1
    // encoded as 2-bit signed: 2'b01 = +1, 2'b11 = -1
    logic signed [1:0] weights [0:3][0:3];

    // Initialize weights to the crossbar pattern
    // W = [[ 1,-1, 1,-1],
    //      [ 1, 1,-1,-1],
    //      [-1, 1, 1,-1],
    //      [-1,-1,-1, 1]]
    always_ff @(posedge clk) begin
        if (rst) begin
            // Row 0
            weights[0][0] <=  2'sb01;  // +1
            weights[0][1] <= -2'sb01;  // -1
            weights[0][2] <=  2'sb01;  // +1
            weights[0][3] <= -2'sb01;  // -1
            // Row 1
            weights[1][0] <=  2'sb01;  // +1
            weights[1][1] <=  2'sb01;  // +1
            weights[1][2] <= -2'sb01;  // -1
            weights[1][3] <= -2'sb01;  // -1
            // Row 2
            weights[2][0] <= -2'sb01;  // -1
            weights[2][1] <=  2'sb01;  // +1
            weights[2][2] <=  2'sb01;  // +1
            weights[2][3] <= -2'sb01;  // -1
            // Row 3
            weights[3][0] <= -2'sb01;  // -1
            weights[3][1] <= -2'sb01;  // -1
            weights[3][2] <= -2'sb01;  // -1
            weights[3][3] <=  2'sb01;  // +1
        end
    end

    // Input array for easier indexing
    logic signed [7:0] inputs [0:3];
    assign inputs[0] = in0;
    assign inputs[1] = in1;
    assign inputs[2] = in2;
    assign inputs[3] = in3;

    // Output array
    logic signed [31:0] outputs [0:3];
    assign out0 = outputs[0];
    assign out1 = outputs[1];
    assign out2 = outputs[2];
    assign out3 = outputs[3];

    // MAC computation: out[j] = sum_i(weight[i][j] * in[i])
    always_ff @(posedge clk) begin
        if (rst) begin
            outputs[0] <= '0;
            outputs[1] <= '0;
            outputs[2] <= '0;
            outputs[3] <= '0;
        end else if (en) begin
            outputs[0] <= (weights[0][0] * inputs[0]) +
                          (weights[1][0] * inputs[1]) +
                          (weights[2][0] * inputs[2]) +
                          (weights[3][0] * inputs[3]);
            outputs[1] <= (weights[0][1] * inputs[0]) +
                          (weights[1][1] * inputs[1]) +
                          (weights[2][1] * inputs[2]) +
                          (weights[3][1] * inputs[3]);
            outputs[2] <= (weights[0][2] * inputs[0]) +
                          (weights[1][2] * inputs[1]) +
                          (weights[2][2] * inputs[2]) +
                          (weights[3][2] * inputs[3]);
            outputs[3] <= (weights[0][3] * inputs[0]) +
                          (weights[1][3] * inputs[1]) +
                          (weights[2][3] * inputs[2]) +
                          (weights[3][3] * inputs[3]);
        end
    end

endmodule