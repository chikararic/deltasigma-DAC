`timescale 1ns / 1ps

module tb_prototype;

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

    // Explicit zero-insertion FIR reference model
    reg  signed [13:0] xu [0:22];
    reg                ref_phase;
    reg  signed [19:0] exp_dout;
    reg                exp_valid;

    reg  signed [13:0] in_u;
    reg  signed [13:0] w_next [0:22];

    reg  signed [31:0] ref_val;
    reg         [31:0] rand_tmp;

    integer errors;
    integer i;
    integer k;

    // ------------------------------------------------------------
    // clock
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Reference model: explicit zero insertion + 23-tap FIR
    // ------------------------------------------------------------
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

    // ------------------------------------------------------------
    // Compare after outputs settle
    // ------------------------------------------------------------
    always @(negedge clk) begin
        if (rst_n && exp_valid) begin
            if (dout !== exp_dout) begin
                errors = errors + 1;
                $display("MISMATCH @ t=%0t | dout=%0d | exp=%0d",
                         $time, $signed(dout), $signed(exp_dout));
            end
        end
    end

    // ------------------------------------------------------------
    // One real input sample every 2 clocks
    // ------------------------------------------------------------
    task send_sample;
        input [13:0] s;
        begin
            @(negedge clk);
            din       <= s;
            din_valid <= 1'b1;

            @(negedge clk);
            din       <= 14'sd0;
            din_valid <= 1'b0;
        end
    endtask

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------
    initial begin
        rst_n     = 1'b0;
        din       = 14'sd0;
        din_valid = 1'b0;
        errors    = 0;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        // Test 1: impulse
        send_sample(14'sd7000);
        for (i = 0; i < 20; i = i + 1)
            send_sample(14'sd0);

        // Test 2: random 14-bit patterns
        for (i = 0; i < 100; i = i + 1) begin
            rand_tmp = $random;
            send_sample(rand_tmp[13:0]);
        end

        repeat (6) @(negedge clk);

        if (errors == 0)
            $display("PASS: DUT matches explicit zero-insertion 23-tap FIR reference.");
        else
            $display("FAIL: total mismatches = %0d", errors);

        $stop;
    end

endmodule
