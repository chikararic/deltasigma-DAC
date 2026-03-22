`timescale 1ns/1ps

module tb_mash111_top;

    parameter W = 14;

    reg               clk;
    reg               rst_n;
    reg               ce;
    reg  [W-1:0]      din;

    wire              p0;
    wire              p1;
    wire              p2;
    wire signed [1:0] d1;
    wire signed [2:0] d2;
    wire signed [3:0] y_raw;
    wire [2:0]        y_map;

    reg  [W-1:0] acc1_ref;
    reg  [W-1:0] acc2_ref;
    reg  [W-1:0] acc3_ref;

    reg          p1_d1_ref;
    reg          p2_d1_ref;
    reg          p2_d2_ref;

    reg  [W:0]   sum1_ref;
    reg  [W:0]   sum2_ref;
    reg  [W:0]   sum3_ref;

    reg          exp_p0;
    reg          exp_p1;
    reg          exp_p2;
    reg  [W-1:0] exp_e1;
    reg  [W-1:0] exp_e2;
    reg  [W-1:0] exp_e3;

    integer      exp_d1;
    integer      exp_d2;
    integer      exp_y_raw;
    integer      exp_y_map;

    integer      got_d1;
    integer      got_d2;
    integer      got_y_raw;

    integer      errors;
    integer      i;
    integer      seed;

    mash111_top #(.W(W)) dut (
        .clk  (clk),
        .rst_n(rst_n),
        .ce   (ce),
        .din  (din),
        .p0   (p0),
        .p1   (p1),
        .p2   (p2),
        .d1   (d1),
        .d2   (d2),
        .y_raw(y_raw),
        .y_map(y_map)
    );

    always #5 clk = ~clk;

    task calc_expected;
    begin
        // current-cycle combinational outputs based on current state + current din
        sum1_ref = {1'b0, acc1_ref} + {1'b0, din};
        exp_p0   = sum1_ref[W];
        exp_e1   = sum1_ref[W-1:0];

        sum2_ref = {1'b0, acc2_ref} + {1'b0, exp_e1};
        exp_p1   = sum2_ref[W];
        exp_e2   = sum2_ref[W-1:0];

        sum3_ref = {1'b0, acc3_ref} + {1'b0, exp_e2};
        exp_p2   = sum3_ref[W];
        exp_e3   = sum3_ref[W-1:0];

        exp_d1    = (exp_p1 ? 1 : 0) - (p1_d1_ref ? 1 : 0);
        exp_d2    = (exp_p2 ? 1 : 0) - 2*(p2_d1_ref ? 1 : 0) + (p2_d2_ref ? 1 : 0);
        exp_y_raw = (exp_p0 ? 1 : 0) + exp_d1 + exp_d2;
        exp_y_map = exp_y_raw + 3;
    end
    endtask

    task check_outputs;
    begin
        calc_expected;
        #1; // settle away from posedge

        got_d1    = $signed(d1);
        got_d2    = $signed(d2);
        got_y_raw = $signed(y_raw);

        if (p0 !== exp_p0) begin
            $display("[ERR][top] p0 mismatch @%0t : got=%0d exp=%0d", $time, p0, exp_p0);
            errors = errors + 1;
        end
        if (p1 !== exp_p1) begin
            $display("[ERR][top] p1 mismatch @%0t : got=%0d exp=%0d", $time, p1, exp_p1);
            errors = errors + 1;
        end
        if (p2 !== exp_p2) begin
            $display("[ERR][top] p2 mismatch @%0t : got=%0d exp=%0d", $time, p2, exp_p2);
            errors = errors + 1;
        end
        if (got_d1 !== exp_d1) begin
            $display("[ERR][top] d1 mismatch @%0t : got=%0d exp=%0d", $time, got_d1, exp_d1);
            errors = errors + 1;
        end
        if (got_d2 !== exp_d2) begin
            $display("[ERR][top] d2 mismatch @%0t : got=%0d exp=%0d", $time, got_d2, exp_d2);
            errors = errors + 1;
        end
        if (got_y_raw !== exp_y_raw) begin
            $display("[ERR][top] y_raw mismatch @%0t : got=%0d exp=%0d", $time, got_y_raw, exp_y_raw);
            errors = errors + 1;
        end
        if (y_map !== exp_y_map[2:0]) begin
            $display("[ERR][top] y_map mismatch @%0t : got=%0d exp=%0d", $time, y_map, exp_y_map);
            errors = errors + 1;
        end

        if (got_y_raw < -3 || got_y_raw > 4) begin
            $display("[ERR][top] y_raw out of range @%0t : got=%0d", $time, got_y_raw);
            errors = errors + 1;
        end
        if (y_map > 3'd7) begin
            $display("[ERR][top] y_map out of range @%0t : got=%0d", $time, y_map);
            errors = errors + 1;
        end
    end
    endtask

    task update_reference;
    begin
        if (!rst_n) begin
            acc1_ref  = {W{1'b0}};
            acc2_ref  = {W{1'b0}};
            acc3_ref  = {W{1'b0}};
            p1_d1_ref = 1'b0;
            p2_d1_ref = 1'b0;
            p2_d2_ref = 1'b0;
        end
        else if (ce) begin
            acc1_ref  = exp_e1;
            acc2_ref  = exp_e2;
            acc3_ref  = exp_e3;

            p1_d1_ref = exp_p1;

            // two cascaded delays sample old values on the same edge
            p2_d2_ref = p2_d1_ref;
            p2_d1_ref = exp_p2;
        end
    end
    endtask

    task run_vector;
        input [W-1:0] val;
        input         ce_val;
    begin
        @(negedge clk);
        din = val;
        ce  = ce_val;

        #3;          // stay clear of the next posedge
        check_outputs;

        @(posedge clk);
        update_reference;
    end
    endtask

    initial begin
        clk       = 1'b0;
        rst_n     = 1'b0;
        ce        = 1'b1;
        din       = {W{1'b0}};
        acc1_ref  = {W{1'b0}};
        acc2_ref  = {W{1'b0}};
        acc3_ref  = {W{1'b0}};
        p1_d1_ref = 1'b0;
        p2_d1_ref = 1'b0;
        p2_d2_ref = 1'b0;
        errors    = 0;
        seed      = 32'h2468ACE1;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // deterministic tests
        run_vector(14'd0,     1'b1);
        run_vector(14'd0,     1'b1);
        run_vector(14'd1,     1'b1);
        run_vector(14'd8192,  1'b1);
        run_vector(14'd8192,  1'b1);
        run_vector(14'd16383, 1'b1);
        run_vector(14'd16383, 1'b1);

        // alternating stress
        for (i = 0; i < 12; i = i + 1) begin
            if (i[0] == 1'b0)
                run_vector(14'd0, 1'b1);
            else
                run_vector(14'd16383, 1'b1);
        end

        // CE freeze state test
        run_vector(14'd5000, 1'b1);
        run_vector(14'd9000, 1'b0);
        run_vector(14'd2000, 1'b0);
        run_vector(14'd5000, 1'b1);

        // ramp-like test
        run_vector(14'd1024,  1'b1);
        run_vector(14'd2048,  1'b1);
        run_vector(14'd4096,  1'b1);
        run_vector(14'd6144,  1'b1);
        run_vector(14'd8192,  1'b1);
        run_vector(14'd12288, 1'b1);
        run_vector(14'd14336, 1'b1);

        // random regression
        for (i = 0; i < 10; i = i + 1)
            run_vector($random(seed) & 14'h3FFF, (i % 9 != 4));

        if (errors == 0)
            $display("[PASS] tb_mash111_top passed.");
        else
            $display("[FAIL] tb_mash111_top failed with %0d errors.", errors);

        $stop;
    end

endmodule
