`timescale 1ns/1ps

module tb_top;

    logic clk, rst;
    initial clk = 0;
    always #5 clk = ~clk;

    logic [15:0] s_axis_tdata;
    logic        s_axis_tvalid;
    logic        s_axis_tready;
    logic        s_axis_tlast;
    logic [31:0] m_axis_tdata;
    logic        m_axis_tvalid;
    logic        m_axis_tready;
    logic        m_axis_tlast;

    top #(.DATA_WIDTH(8), .ACC_WIDTH(32)) dut (
        .clk(clk), .rst(rst),
        .s_axis_tdata(s_axis_tdata), .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready), .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata), .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready), .m_axis_tlast(m_axis_tlast)
    );

    localparam int N_BEATS = 9;
    logic signed [7:0] activations [0:N_BEATS-1];
    logic signed [7:0] weights_arr [0:N_BEATS-1];
    integer pass_count, fail_count, i;
    logic result_valid_seen;

    initial begin
        activations = '{8'sd1, 8'sd2, 8'sd3, 8'sd4, 8'sd5,
                        8'sd6, 8'sd7, 8'sd8, 8'sd9};
        weights_arr = '{8'sd1, 8'sd1, 8'sd1, 8'sd1, 8'sd1,
                        8'sd1, 8'sd1, 8'sd1, 8'sd1};
        pass_count  = 0;
        fail_count  = 0;

        $display("=== tb_top: M3 End-to-End Co-Simulation ===");
        $display("Test 1: 3x3 identity kernel, activations 1-9, expected acc=45");

        rst = 1; s_axis_tvalid = 0; s_axis_tdata = 0;
        s_axis_tlast = 0; m_axis_tready = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        $display("\n-- Streaming %0d beats through AXI4-Stream interface --", N_BEATS);
        result_valid_seen = 0;
        for (i = 0; i < N_BEATS; i++) begin
            while (!s_axis_tready) @(posedge clk);
            s_axis_tdata  = {weights_arr[i], activations[i]};
            s_axis_tvalid = 1;
            s_axis_tlast  = (i == N_BEATS-1) ? 1'b1 : 1'b0;
            $display("  Beat %0d: activation=%0d weight=%0d tlast=%0b",
                     i, activations[i], weights_arr[i], s_axis_tlast);
            @(posedge clk); #1;
            // Capture result while valid is asserted during last beat
            if (m_axis_tvalid) result_valid_seen = 1;
        end
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;

        $display("\n-- Checking result (sampled during last beat) --");
        $display("  Expected acc_out = 45");
        $display("  Got      acc_out = %0d (m_axis_tdata)", $signed(m_axis_tdata));

        if ($signed(m_axis_tdata) === 32'sd45) begin
            $display("  [PASS] Output matches expected value 45");
            pass_count++;
        end else begin
            $display("  [FAIL] Output mismatch, expected 45");
            fail_count++;
        end

        if (result_valid_seen) begin
            $display("  [PASS] m_axis_tvalid asserted during transaction");
            pass_count++;
        end else begin
            $display("  [FAIL] m_axis_tvalid never asserted");
            fail_count++;
        end

        // Test 2: negative weights
        $display("\n-- Test 2: activations=[2,4,6], weights=[-1,-1,-1], expected=-12 --");
        rst = 1;
        @(posedge clk); #1; @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        begin
            logic signed [7:0] act2 [0:2];
            logic signed [7:0] wt2  [0:2];
            act2 = '{8'sd2, 8'sd4, 8'sd6};
            wt2  = '{-8'sd1, -8'sd1, -8'sd1};
            for (i = 0; i < 3; i++) begin
                while (!s_axis_tready) @(posedge clk);
                s_axis_tdata  = {wt2[i], act2[i]};
                s_axis_tvalid = 1;
                s_axis_tlast  = (i == 2) ? 1'b1 : 1'b0;
                @(posedge clk); #1;
            end
            s_axis_tvalid = 0;
        end

        @(posedge clk); #1;

        $display("  Got acc_out = %0d (m_axis_tdata)", $signed(m_axis_tdata));
        if ($signed(m_axis_tdata) === -32'sd12) begin
            $display("  [PASS] Negative weight result correct");
            pass_count++;
        end else begin
            $display("  [FAIL] Negative weight result wrong");
            fail_count++;
        end

        $display("\n=== Results: %0d/%0d PASS ===",
                 pass_count, pass_count + fail_count);
        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL: %0d test(s) failed", fail_count);

        $finish;
    end

    initial begin #100000; $display("TIMEOUT"); $finish; end

endmodule