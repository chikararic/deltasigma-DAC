`timescale 1ns / 1ps

module tb_prototype_stress;

    /*
    ============================================================================
    Testbench name : tb_prototype_stress
    Target module  : prototype

    Purpose
    -------
    This is the numerical stress testbench for the HB interpolator. It focuses
    on extreme signed input values, high activity patterns, and long pseudo-
    random runs. The goal is to expose hidden arithmetic, sign, alignment, or
    state-corruption issues that may not appear in a short nominal test.

    Why a separate stress testbench is needed
    -----------------------------------------
    A short functional testbench can pass while the design still contains issues
    that only appear under aggressive input statistics, for example:
        - full-scale positive block
        - full-scale negative block
        - alternating +FS / -FS sequence
        - very small signed values around zero
        - long random sequences

    Reference model and formulas
    ----------------------------
    The same explicit zero-insertion FIR model is used:

        x_u[m] = x[n],  m = 2n
               = 0,     m = 2n+1

        y[m] = sum_{k=0}^{22} h[k] * x_u[m-k]

    with the same CSD side coefficients and center tap h[11] = 1/2.

    Execution flow
    --------------
    A) Reset DUT/reference.
    B) Apply a long +FS block.
    C) Apply a long -FS block.
    D) Apply alternating full-scale sequence.
    E) Apply near-zero alternating sequence.
    F) Apply long pseudo-random signed sequence.
    G) Compare every output sample against the explicit reference model.
    H) Report mismatch count and observed output range.

    Why observed range is printed
    -----------------------------
    Even if the DUT matches the reference model, it is still useful to know the
    practical output dynamic range reached during stress testing:

        dout_min <= dout <= dout_max

    This helps later when auditing fixed-point headroom and report figures.
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
    reg                ref_phase;
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
    reg signed [19:0]  dout_min;
    reg signed [19:0]  dout_max;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_phase <= 1'b0;
            exp_dout  <= 20'sd0;
            exp_valid <= 1'b0;
            for (k = 0; k < 23; k = k + 1)
                xu[k] <= 14'sd0;
        end else begin
            if ((ref_phase == 1'b0) && din_valid)
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

            ref_phase <= ~ref_phase;
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
                $display("DATA  MISMATCH @ t=%0t | dout=%0d | exp=%0d",
                         $time, $signed(dout), $signed(exp_dout));
            end

            if ($signed(dout) < $signed(dout_min))
                dout_min = dout;
            if ($signed(dout) > $signed(dout_max))
                dout_max = dout;
        end
    end

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

    initial begin
        rst_n     = 1'b0;
        din       = 14'sd0;
        din_valid = 1'b0;
        errors    = 0;
        checks    = 0;
        seed      = 32'h55aa1234;
        dout_min  = 20'sd524287;
        dout_max  = -20'sd524288;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        // 1) Full-scale positive block
        for (i = 0; i < 64; i = i + 1)
            send_legal_sample(14'sd8191);
        flush_zeros(24);

        // 2) Full-scale negative block
        for (i = 0; i < 64; i = i + 1)
            send_legal_sample(-14'sd8192);
        flush_zeros(24);

        // 3) Alternating full-scale signs
        for (i = 0; i < 128; i = i + 1) begin
            if ((i % 2) == 0)
                send_legal_sample(14'sd8191);
            else
                send_legal_sample(-14'sd8192);
        end
        flush_zeros(24);

        // 4) Small-value region around zero
        for (i = 0; i < 64; i = i + 1) begin
            case (i % 4)
                0: send_legal_sample(14'sd1);
                1: send_legal_sample(-14'sd1);
                2: send_legal_sample(14'sd2);
                default: send_legal_sample(-14'sd2);
            endcase
        end
        flush_zeros(24);

        // 5) Long pseudo-random signed block
        for (i = 0; i < 2048; i = i + 1) begin
            rand_tmp = $random(seed);
            send_legal_sample(rand_tmp[13:0]);
        end
        flush_zeros(32);

        repeat (6) @(negedge clk);

        if (errors == 0) begin
            $display("PASS(tb_prototype_stress): checks=%0d, no mismatches.", checks);
            $display("Observed dout range: min=%0d, max=%0d", $signed(dout_min), $signed(dout_max));
        end else begin
            $display("FAIL(tb_prototype_stress): checks=%0d, mismatches=%0d.", checks, errors);
            $display("Observed dout range: min=%0d, max=%0d", $signed(dout_min), $signed(dout_max));
        end

        $finish;
    end

endmodule

