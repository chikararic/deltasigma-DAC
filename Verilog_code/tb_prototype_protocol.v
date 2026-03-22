`timescale 1ns / 1ps

module tb_prototype_protocol;

    /*
    ============================================================================
    Testbench name : tb_prototype_protocol
    Target module  : prototype

    Purpose
    -------
    This testbench verifies *protocol and boundary behavior*, not just nominal
    filter arithmetic. The core question here is:

        "What happens when din_valid is not driven in the ideal 1-sample-per-2-
         clocks pattern?"

    Why this matters
    ----------------
    The DUT is effectively a 2x interpolator with an internal phase schedule.
    A common hidden bug is that the data path looks correct for ideal stimuli,
    but the module fails when:
        - din_valid arrives on the wrong phase
        - din_valid is held high for multiple clocks
        - long idle gaps occur
        - reset is asserted in the middle of operation

    Reference interpretation used in this testbench
    -----------------------------------------------
    A testbench-side phase tracker is maintained:

        tb_phase = 0,1,0,1,... after reset release

    The intended legal meaning is:

        if tb_phase == 0 and din_valid == 1 : consume real sample
        else                                : insert zero in upsampled stream

    Therefore, an illegal-phase pulse is *expected to be ignored* by the
    reference model. This is the correct thing to test when the DUT is supposed
    to accept data only in one phase slot.

    FIR model and formula
    ---------------------
    The same explicit zero-insertion + 23-tap FIR model is used:

        x_u[m] = x[n],  m = 2n and accepted by phase rule
               = 0,     otherwise

        y[m] = sum_{k=0}^{22} h[k] * x_u[m-k]

    with the same six CSD side coefficients and center coefficient 1/2.

    Execution flow
    --------------
    A) Reset DUT and reference state.
    B) Run baseline legal traffic.
    C) Inject an illegal-phase pulse and verify that it is ignored.
    D) Hold din_valid high across consecutive clocks and verify the behavior.
    E) Insert long idle gaps and verify no state corruption occurs.
    F) Assert asynchronous reset in the middle of traffic and verify restart.
    G) Compare DUT vs reference on every active cycle.

    Scope / limitation
    ------------------
    This testbench is about control/usage robustness. It is not the main long
    random stress testbench; that is placed in tb_prototype_stress.v.
    ============================================================================
    */

    reg                clk;
    reg                rst_n;
    reg                din_valid;
    reg  signed [13:0] din;
    wire signed [19:0] dout;
    wire               dout_valid;

    prototype dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .din_valid (din_valid),
        .din       (din),
        .dout      (dout),
        .dout_valid(dout_valid)
    );

    reg  signed [13:0] xu [0:22];
    reg                tb_phase;
    reg  signed [19:0] exp_dout;
    reg                exp_valid;

    reg  signed [13:0] in_u;
    reg  signed [13:0] w_next [0:22];
    reg  signed [31:0] ref_val;

    integer            errors;
    integer            checks;
    integer            k;
    integer            i;
    integer            seed;
    reg signed [31:0]  rand_tmp;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // Reference model driven by the explicit protocol rule.
    // Only phase-0 valid pulses are considered accepted input samples.
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tb_phase  <= 1'b0;
            exp_dout  <= 20'sd0;
            exp_valid <= 1'b0;
            for (k = 0; k < 23; k = k + 1)
                xu[k] <= 14'sd0;
        end else begin
            if ((tb_phase == 1'b0) && din_valid)
                in_u = din;
            else
                in_u = 14'sd0;

            w_next[0] = in_u;
            for (k = 1; k < 23; k = k + 1)
                w_next[k] = xu[k-1];

            ref_val = 32'sd0;

            ref_val = ref_val
                    + (($signed(w_next[10]) + $signed(w_next[12])) >>> 2)
                    + (($signed(w_next[10]) + $signed(w_next[12])) >>> 4)
                    + (($signed(w_next[10]) + $signed(w_next[12])) >>> 9);

            ref_val = ref_val
                    + (($signed(w_next[8]) + $signed(w_next[14])) >>> 3)
                    - (($signed(w_next[8]) + $signed(w_next[14])) >>> 5)
                    + (($signed(w_next[8]) + $signed(w_next[14])) >>> 9);

            ref_val = ref_val
                    + (($signed(w_next[6]) + $signed(w_next[16])) >>> 4)
                    - (($signed(w_next[6]) + $signed(w_next[16])) >>> 6)
                    + (($signed(w_next[6]) + $signed(w_next[16])) >>> 9);

            ref_val = ref_val
                    + (($signed(w_next[4]) + $signed(w_next[18])) >>> 5)
                    - (($signed(w_next[4]) + $signed(w_next[18])) >>> 8)
                    - (($signed(w_next[4]) + $signed(w_next[18])) >>> 10);

            ref_val = ref_val
                    + (($signed(w_next[2]) + $signed(w_next[20])) >>> 6)
                    - (($signed(w_next[2]) + $signed(w_next[20])) >>> 9)
                    - (($signed(w_next[2]) + $signed(w_next[20])) >>> 14);

            ref_val = ref_val
                    + (($signed(w_next[0]) + $signed(w_next[22])) >>> 7)
                    - (($signed(w_next[0]) + $signed(w_next[22])) >>> 11)
                    - (($signed(w_next[0]) + $signed(w_next[22])) >>> 13);

            ref_val = ref_val + ($signed(w_next[11]) >>> 1);

            exp_dout  <= ref_val[19:0];
            exp_valid <= 1'b1;

            for (k = 0; k < 23; k = k + 1)
                xu[k] <= w_next[k];

            tb_phase <= ~tb_phase;
        end
    end

    always @(negedge clk) begin
        if (rst_n && exp_valid) begin
            checks = checks + 1;

            if (dout_valid !== exp_valid) begin
                errors = errors + 1;
                $display("VALID MISMATCH @ t=%0t | dout_valid=%b | exp_valid=%b",
                         $time, dout_valid, exp_valid);
            end

            if (dout !== exp_dout) begin
                errors = errors + 1;
                $display("DATA  MISMATCH @ t=%0t | dout=%0d | exp=%0d | din_valid=%b | din=%0d | tb_phase=%b",
                         $time, $signed(dout), $signed(exp_dout), din_valid, $signed(din), tb_phase);
            end

            if ((^dout) === 1'bx) begin
                errors = errors + 1;
                $display("X DETECTED @ t=%0t | dout has unknown bits", $time);
            end
        end
    end

    // ------------------------------------------------------------------------
    // One-cycle driver: drive values on negedge so DUT/reference sample them on
    // the following posedge.
    // ------------------------------------------------------------------------
    task drive_cycle;
        input        v;
        input signed [13:0] s;
        begin
            @(negedge clk);
            din       <= s;
            din_valid <= v;
        end
    endtask

    task idle_cycles;
        input integer count;
        integer n;
        begin
            for (n = 0; n < count; n = n + 1)
                drive_cycle(1'b0, 14'sd0);
        end
    endtask

    task legal_sample;
        input signed [13:0] s;
        begin
            drive_cycle(1'b1, s);
            drive_cycle(1'b0, 14'sd0);
        end
    endtask

    initial begin
        rst_n     = 1'b0;
        din       = 14'sd0;
        din_valid = 1'b0;
        errors    = 0;
        checks    = 0;
        seed      = 32'h2468ace1;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        // 1) Baseline legal traffic
        legal_sample(14'sd1000);
        legal_sample(-14'sd1500);
        legal_sample(14'sd2300);
        idle_cycles(8);

        // 2) Illegal-phase pulse: after one legal sample, we intentionally place
        //    a valid pulse in the following phase-1 slot. The reference model
        //    ignores it by construction.
        legal_sample(14'sd2048);
        drive_cycle(1'b1, 14'sd3333);  // intentionally wrong phase
        drive_cycle(1'b0, 14'sd0);
        idle_cycles(8);

        // 3) Hold din_valid high across consecutive cycles. Only the phase-0 slot
        //    should be treated as real input according to the reference rule.
        drive_cycle(1'b1, 14'sd1200);
        drive_cycle(1'b1, 14'sd2200);
        drive_cycle(1'b1, -14'sd3200);
        drive_cycle(1'b0, 14'sd0);
        idle_cycles(8);

        // 4) Irregular gaps between legal samples
        legal_sample(14'sd500);
        idle_cycles(5);
        legal_sample(-14'sd700);
        idle_cycles(3);
        legal_sample(14'sd900);
        idle_cycles(9);

        // 5) Random protocol traffic: valid may appear on any cycle
        for (i = 0; i < 80; i = i + 1) begin
            rand_tmp = $random(seed);
            drive_cycle(rand_tmp[0], rand_tmp[13:0]);
        end
        idle_cycles(16);

        // 6) Mid-stream asynchronous reset and restart
        legal_sample(14'sd1111);
        legal_sample(14'sd2222);
        @(negedge clk);
        rst_n     <= 1'b0;
        din       <= 14'sd0;
        din_valid <= 1'b0;
        @(negedge clk);
        @(negedge clk);
        rst_n     <= 1'b1;
        idle_cycles(4);
        legal_sample(-14'sd1357);
        legal_sample(14'sd2468);
        idle_cycles(16);

        repeat (4) @(negedge clk);

        if (errors == 0)
            $display("PASS(tb_prototype_protocol): checks=%0d, no mismatches.", checks);
        else
            $display("FAIL(tb_prototype_protocol): checks=%0d, mismatches=%0d.", checks, errors);

        $finish;
    end

endmodule

