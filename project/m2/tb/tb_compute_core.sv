// =============================================================================
// Module:      tb_compute_core
// Project:     INT8 MAC Accelerator for CNN Conv2D Acceleration
// Course:      ECE 410/510 Spring 2026
// Author:      Devdutt Mallick
// Description: Testbench for compute_core.sv
//              Tests: reset, basic MAC, accumulation, negative inputs,
//                     enable gating, valid_out latency, done signal.
//              Prints PASS/FAIL for each test.
// =============================================================================

`timescale 1ns/1ps

module tb_compute_core;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    logic        clk;
    logic        rst;
    logic        en;
    logic        valid_in;
    logic signed [7:0]  activation;
    logic signed [7:0]  weight;
    logic signed [31:0] acc_out;
    logic               valid_out;
    logic               done;

    // -------------------------------------------------------------------------
    // Instantiate DUT
    // -------------------------------------------------------------------------
    compute_core #(
        .DATA_WIDTH(8),
        .ACC_WIDTH(32)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .en        (en),
        .valid_in  (valid_in),
        .activation(activation),
        .weight    (weight),
        .acc_out   (acc_out),
        .valid_out (valid_out),
        .done      (done)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 10ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Test counter
    // -------------------------------------------------------------------------
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
                $display("  [FAIL] %s  acc_out=%0d valid_out=%0b done=%0b",
                          name, acc_out, valid_out, done);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $display("=== compute_core testbench ===");

        // Initialize
        rst = 1; en = 0; valid_in = 0;
        activation = 0; weight = 0;
        @(posedge clk); #1;

        // ------------------------------------------------------------------
        // Test 1: Reset clears accumulator
        // ------------------------------------------------------------------
        $display("\n-- Test 1: Reset clears accumulator --");
        @(posedge clk); #1;
        check("acc_out == 0 after reset", acc_out === 32'sd0);
        check("valid_out == 0 after reset", valid_out === 1'b0);

        // ------------------------------------------------------------------
        // Test 2: Basic MAC — 3 x 4 = 12
        // ------------------------------------------------------------------
        $display("\n-- Test 2: Basic MAC (3 x 4 = 12) --");
        rst = 0; en = 1; valid_in = 1;
        activation = 8'sd3; weight = 8'sd4;
        @(posedge clk); #1;
        check("acc_out == 12", acc_out === 32'sd12);
        check("valid_out == 1", valid_out === 1'b1);

        // ------------------------------------------------------------------
        // Test 3: Accumulation over 3 cycles (3x4 each) -> 12, 24, 36
        // ------------------------------------------------------------------
        $display("\n-- Test 3: Accumulation over 3 cycles --");
        @(posedge clk); #1;
        check("acc_out == 24 (cycle 2)", acc_out === 32'sd24);
        @(posedge clk); #1;
        check("acc_out == 36 (cycle 3)", acc_out === 32'sd36);

        // ------------------------------------------------------------------
        // Test 4: Enable gating — acc_out should NOT change when en=0
        // ------------------------------------------------------------------
        $display("\n-- Test 4: Enable gating (en=0) --");
        en = 0;
        @(posedge clk); #1;
        check("acc_out unchanged when en=0", acc_out === 32'sd36);

        // ------------------------------------------------------------------
        // Test 5: Negative inputs — -5 x 2 = -10
        // ------------------------------------------------------------------
        $display("\n-- Test 5: Negative inputs (-5 x 2) --");
        rst = 1;
        @(posedge clk); #1;
        rst = 0; en = 1; valid_in = 1;
        activation = -8'sd5; weight = 8'sd2;
        @(posedge clk); #1;
        check("acc_out == -10 (-5 x 2)", acc_out === -32'sd10);
        @(posedge clk); #1;
        check("acc_out == -20 (-10 + -10)", acc_out === -32'sd20);

        // ------------------------------------------------------------------
        // Test 6: Negative x Negative — -8 x -8 = 64
        // ------------------------------------------------------------------
        $display("\n-- Test 6: Negative x Negative (-8 x -8 = 64) --");
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        activation = -8'sd8; weight = -8'sd8;
        @(posedge clk); #1;
        check("acc_out == 64 (-8 x -8)", acc_out === 32'sd64);

        // ------------------------------------------------------------------
        // Test 7: Max positive INT8 (127 x 127 = 16129)
        // ------------------------------------------------------------------
        $display("\n-- Test 7: Max positive INT8 (127 x 127 = 16129) --");
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        activation = 8'sd127; weight = 8'sd127;
        @(posedge clk); #1;
        check("acc_out == 16129 (127 x 127)", acc_out === 32'sd16129);

        // ------------------------------------------------------------------
        // Test 8: Done signal pulses after reset
        // ------------------------------------------------------------------
        $display("\n-- Test 8: Done signal pulses after reset --");
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;
        check("done pulses one cycle after rst falls", done === 1'b1);
        @(posedge clk); #1;
        check("done deasserts after one cycle", done === 1'b0);

        // ------------------------------------------------------------------
        // Test 9: valid_in gating — no accumulation when valid_in=0
        // ------------------------------------------------------------------
        $display("\n-- Test 9: valid_in gating --");
        rst = 1;
        @(posedge clk); #1;
        rst = 0; en = 1; valid_in = 0;
        activation = 8'sd10; weight = 8'sd10;
        @(posedge clk); #1;
        check("acc_out == 0 when valid_in=0", acc_out === 32'sd0);

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("\n=== Results: %0d/%0d PASS ===",
                  pass_count, pass_count + fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

    // Timeout watchdog
    initial begin
        #10000;
        $display("TIMEOUT: simulation exceeded 10us");
        $finish;
    end

endmodule