`timescale 1ns / 1ps

module tb_prototype_func;

    /*
    ============================================================================
    Testbench name : tb_prototype_func
    Target module  : prototype

    Purpose
    -------
    This is the main functional self-checking testbench for the HB interpolator.
    It verifies the DUT on the *legal operating path* only, i.e. one real input
    sample is applied every 2 clock cycles, which matches the intended 2x
    interpolation schedule of this prototype.

    What this testbench checks
    --------------------------
    1) Sample-by-sample correctness of the DUT output `dout`
       against an explicit reference model.
    2) Basic output handshake observation through `dout_valid`.
    3) Correctness on several representative stimuli:
          - impulse
          - step / DC block
          - alternating sign sequence
          - pseudo-random signed sequence

    Why the reference model is written this way
    -------------------------------------------
    The DUT is a 2x half-band interpolator. In algorithm form:

        x_u[m] = x[n],  m = 2n
               = 0,     m = 2n+1

    where x_u[m] is the explicitly zero-inserted sequence.

    The 23-tap HB FIR output is:

        y[m] = sum_{k=0}^{22} h[k] * x_u[m-k]

    For a half-band filter, almost every other coefficient is zero, and the
    center coefficient is 1/2. In this specific prototype, the non-zero even-
    phase side coefficients are implemented with CSD shift-add forms, while the
    odd phase uses the center tap:

        h_center = 1/2

    The six symmetric non-zero side coefficients used here are equivalent to:

        c1 =  2^-2 + 2^-4 + 2^-9
        c2 =  2^-3 - 2^-5 + 2^-9
        c3 =  2^-4 - 2^-6 + 2^-9
        c4 =  2^-5 - 2^-8 - 2^-10
        c5 =  2^-6 - 2^-9 - 2^-14
        c6 =  2^-7 - 2^-11 - 2^-13

    Execution flow
    --------------
    A) Generate clock.
    B) Release reset.
    C) For each legal input sample, drive one valid pulse over 2 clocks:
           cycle 0 : din_valid = 1, din = real sample
           cycle 1 : din_valid = 0, din = 0
       This matches the intended 2x interpolation input contract.
    D) In parallel, the testbench updates an explicit zero-insertion FIR
       reference model on each positive clock edge.
    E) On each negative clock edge, after DUT/reference outputs have settled,
       compare:
           - dout       vs exp_dout
           - dout_valid vs exp_valid
    F) Report PASS/FAIL with mismatch count.

    Scope / limitation
    ------------------
    This testbench is intentionally restricted to the normal legal use model.
    It is *not* the protocol-stress or extreme-value stress testbench.
    Those are separated into other files to keep responsibilities clean.
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

    // ------------------------------------------------------------------------
    // Explicit zero-insertion 23-tap FIR reference model
    // ------------------------------------------------------------------------
    reg  signed [13:0] xu [0:22];
    reg                ref_phase;
    reg  signed [19:0] exp_dout;
    reg                exp_valid;

    reg  signed [13:0] in_u;
    reg  signed [13:0] w_next [0:22];
    reg  signed [31:0] ref_val;
    integer            k;

    integer            errors;
    integer            checks;
    integer            i;
    integer            seed;
    reg signed [31:0]  rand_tmp;

    // ------------------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // Reference model update
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_phase <= 1'b0;
            exp_dout  <= 20'sd0;
            exp_valid <= 1'b0;
            for (k = 0; k < 23; k = k + 1)
                xu[k] <= 14'sd0;
        end else begin
            // Legal input interpretation for the 2x interpolator:
            // only the phase-0 slot carries a real sample; the next slot is zero.
            if ((ref_phase == 1'b0) && din_valid)
                in_u = din;
            else
                in_u = 14'sd0;

            // Shift the explicitly upsampled sequence window.
            w_next[0] = in_u;
            for (k = 1; k < 23; k = k + 1)
                w_next[k] = xu[k-1];

            // 23-tap HB FIR reference evaluation.
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

            ref_phase <= ~ref_phase;
        end
    end

    // ------------------------------------------------------------------------
    // Self-check after settle time (negedge avoids same-edge race)
    // ------------------------------------------------------------------------
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
                $display("DATA  MISMATCH @ t=%0t | dout=%0d | exp=%0d",
                         $time, $signed(dout), $signed(exp_dout));
            end
        end
    end

    // ------------------------------------------------------------------------
    // Legal 2x-interpolator sample driver:
    // one real sample every two clocks.
    // ------------------------------------------------------------------------
    task send_legal_sample;
        input signed [13:0] s;
        begin
            @(negedge clk);
            din       <= s;
            din_valid <= 1'b1;

            @(negedge clk);
            din       <= 14'sd0;
            din_valid <= 1'b0;
        end
    endtask

    task flush_zeros;
        input integer count;
        integer n;
        begin
            for (n = 0; n < count; n = n + 1)
                send_legal_sample(14'sd0);
        end
    endtask

    // ------------------------------------------------------------------------
    // Stimulus plan
    //   1) impulse
    //   2) positive DC block
    //   3) alternating sign block
    //   4) signed random block
    // ------------------------------------------------------------------------
    initial begin
        rst_n     = 1'b0;
        din       = 14'sd0;
        din_valid = 1'b0;
        errors    = 0;
        checks    = 0;
        seed      = 32'h13579bdf;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        // 1) impulse response sanity check
        send_legal_sample(14'sd7000);
        flush_zeros(24);

        // 2) DC / step-like excitation
        for (i = 0; i < 32; i = i + 1)
            send_legal_sample(14'sd2048);
        flush_zeros(24);

        // 3) alternating sign sequence
        for (i = 0; i < 32; i = i + 1) begin
            if ((i % 2) == 0)
                send_legal_sample(14'sd4095);
            else
                send_legal_sample(-14'sd4096);
        end
        flush_zeros(24);

        // 4) long pseudo-random signed sequence
        for (i = 0; i < 512; i = i + 1) begin
            rand_tmp = $random(seed);
            send_legal_sample(rand_tmp[13:0]);
        end
        flush_zeros(24);

        repeat (6) @(negedge clk);

        if (errors == 0)
            $display("PASS(tb_prototype_func): checks=%0d, no mismatches.", checks);
        else
            $display("FAIL(tb_prototype_func): checks=%0d, mismatches=%0d.", checks, errors);

        $finish;
    end

endmodule

