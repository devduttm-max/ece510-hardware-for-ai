// =============================================================================
// Module:      tb_interface
// Project:     INT8 MAC Accelerator for CNN Conv2D Acceleration
// Course:      ECE 410/510 Spring 2026
// Author:      Devdutt Mallick
// Description: Testbench for interface_mod.sv (AXI4-Stream wrapper)
//              Tests: reset, single transaction, multi-beat stream,
//                     tlast propagation, ready/valid handshake.
//              Prints PASS/FAIL for each test.
// =============================================================================

`timescale 1ns/1ps

module tb_interface;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    logic        clk;
    logic        rst;

    // AXI4-Stream slave (input)
    logic [15:0] s_axis_tdata;
    logic        s_axis_tvalid;
    logic        s_axis_tready;
    logic        s_axis_tlast;

    // AXI4-Stream master (output)
    logic [31:0] m_axis_tdata;
    logic        m_axis_tvalid;
    logic        m_axis_tready;
    logic        m_axis_tlast;

    // -------------------------------------------------------------------------
    // Instantiate DUT
    // -------------------------------------------------------------------------
    interface_mod #(
        .DATA_WIDTH(8),
        .ACC_WIDTH(32)
    ) dut (
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
                $display("  [FAIL] %s  tdata=%0d tvalid=%0b tlast=%0b",
                          name, m_axis_tdata, m_axis_tvalid, m_axis_tlast);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Helper: pack activation and weight into tdata
    function automatic [15:0] pack;
        input signed [7:0] act;
        input signed [7:0] wgt;
        pack = {wgt, act};
    endfunction

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $display("=== interface_mod testbench ===");

        // Initialize
        rst           = 1;
        s_axis_tdata  = 16'h0000;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        m_axis_tready = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        // ------------------------------------------------------------------
        // Test 1: Reset — tready deasserted, output zero
        // ------------------------------------------------------------------
        $display("\n-- Test 1: Reset state --");
        check("s_axis_tready == 0 during reset", s_axis_tready === 1'b0);
        check("m_axis_tvalid == 0 during reset", m_axis_tvalid === 1'b0);
        check("m_axis_tdata == 0 during reset",  m_axis_tdata  === 32'd0);

        // ------------------------------------------------------------------
        // Test 2: Single transaction — activation=3, weight=4 -> acc=12
        // ------------------------------------------------------------------
        $display("\n-- Test 2: Single write transaction (3 x 4 = 12) --");
        rst = 0;
        @(posedge clk); #1;
        check("s_axis_tready == 1 after reset", s_axis_tready === 1'b1);

        s_axis_tdata  = pack(8'sd3, 8'sd4);
        s_axis_tvalid = 1;
        s_axis_tlast  = 1;
        @(posedge clk); #1;
        // Sample valid and tlast in same cycle as data is output
        check("m_axis_tvalid == 1", m_axis_tvalid === 1'b1);
        check("m_axis_tlast == 1 (propagated)", m_axis_tlast === 1'b1);
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        @(posedge clk); #1;
        check("m_axis_tdata == 12 after one beat", m_axis_tdata === 32'd12);

        // ------------------------------------------------------------------
        // Test 3: Multi-beat stream — 3 beats of (2 x 5 = 10 each) -> 30
        // ------------------------------------------------------------------
        $display("\n-- Test 3: Multi-beat stream (3 x [2 x 5]) -> acc=30 --");
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        s_axis_tdata  = pack(8'sd2, 8'sd5);
        s_axis_tvalid = 1;
        s_axis_tlast  = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        s_axis_tlast = 1;
        @(posedge clk); #1;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;
        @(posedge clk); #1;
        check("m_axis_tdata == 30 after 3 beats", m_axis_tdata === 32'd30);

        // ------------------------------------------------------------------
        // Test 4: Negative inputs — activation=-5, weight=2 -> acc=-10
        // ------------------------------------------------------------------
        $display("\n-- Test 4: Negative inputs (-5 x 2 = -10) --");
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        s_axis_tdata  = pack(-8'sd5, 8'sd2);
        s_axis_tvalid = 1;
        s_axis_tlast  = 1;
        @(posedge clk); #1;
        s_axis_tvalid = 0;
        @(posedge clk); #1;
        check("m_axis_tdata == -10 (negative inputs)",
              $signed(m_axis_tdata) === -32'sd10);

        // ------------------------------------------------------------------
        // Test 5: Backpressure — m_axis_tready=0
        // ------------------------------------------------------------------
        $display("\n-- Test 5: Backpressure (m_axis_tready=0) --");
        rst = 1;
        @(posedge clk); #1;
        rst = 0; m_axis_tready = 0;
        @(posedge clk); #1;

        s_axis_tdata  = pack(8'sd7, 8'sd7);
        s_axis_tvalid = 1;
        s_axis_tlast  = 0;
        @(posedge clk); #1;
        check("s_axis_tready stays 1 (core not blocked by downstream)",
              s_axis_tready === 1'b1);
        m_axis_tready = 1;
        s_axis_tvalid = 0;

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        @(posedge clk); #1;
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
        #20000;
        $display("TIMEOUT: simulation exceeded 20us");
        $finish;
    end

endmodule