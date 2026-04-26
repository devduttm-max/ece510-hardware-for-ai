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
            // Accumulate the product of a and b
            // SystemVerilog automatically sign-extends the 16-bit product 
            // of a * b to 32 bits before the addition.
            out <= out + (a * b);
        end
    end

endmodule