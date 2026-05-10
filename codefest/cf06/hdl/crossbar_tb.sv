`timescale 1ns/1ps

module crossbar_tb;

    logic        clk, rst, en;
    logic signed [7:0]  in0, in1, in2, in3;
    logic signed [31:0] out0, out1, out2, out3;

    crossbar_mac dut (
        .clk(clk), .rst(rst), .en(en),
        .in0(in0), .in1(in1), .in2(in2), .in3(in3),
        .out0(out0), .out1(out1), .out2(out2), .out3(out3)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input string name;
        input logic condition;
        begin
            if (condition) begin
                $display("  [PASS] %s", name);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s", name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== crossbar_mac testbench ===");

        // Reset to load weights
        rst = 1; en = 0;
        in0 = 0; in1 = 0; in2 = 0; in3 = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;

        // Apply input [10, 20, 30, 40]
        // Expected: out0=-40, out1=0, out2=-20, out3=-20
        $display("\n-- Test: input=[10,20,30,40] --");
        $display("Expected: out0=-40, out1=0, out2=-20, out3=-20");
        en = 1;
        in0 = 8'sd10; in1 = 8'sd20;
        in2 = 8'sd30; in3 = 8'sd40;
        @(posedge clk); #1;
        @(posedge clk); #1;

        $display("Got:      out0=%0d, out1=%0d, out2=%0d, out3=%0d",
                  out0, out1, out2, out3);
        check("out0 == -40", out0 === -32'sd40);
        check("out1 ==   0", out1 ===  32'sd0);
        check("out2 == -20", out2 === -32'sd20);
        check("out3 == -20", out3 === -32'sd20);

        // Test reset clears outputs
        $display("\n-- Test: reset clears outputs --");
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        check("out0 == 0 after reset", out0 === 32'sd0);
        check("out1 == 0 after reset", out1 === 32'sd0);
        check("out2 == 0 after reset", out2 === 32'sd0);
        check("out3 == 0 after reset", out3 === 32'sd0);

        $display("\n=== Results: %0d/%0d PASS ===",
                  pass_count, pass_count + fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

endmodule