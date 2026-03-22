`timescale 1ns/1ps

module tb_mash_acc_ce;

    parameter W = 14;

    reg             clk;
    reg             rst_n;
    reg             ce;
    reg  [W-1:0]    din;
    wire            p_out;
    wire [W-1:0]    res_out;
    wire [W-1:0]    state_out;

    reg  [W-1:0]    acc_ref;
    reg  [W:0]      sum_ref;
    reg             exp_p;
    reg  [W-1:0]    exp_res;

    integer errors;
    integer i;
    integer seed;

    mash_acc_ce #(.W(W)) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .ce       (ce),
        .din      (din),
        .p_out    (p_out),
        .res_out  (res_out),
        .state_out(state_out)
    );

    always #5 clk = ~clk;

    task calc_expected;
    begin
        sum_ref = {1'b0, acc_ref} + {1'b0, din};
        exp_p   = sum_ref[W];
        exp_res = sum_ref[W-1:0];
    end
    endtask

    task check_outputs;
    begin
        calc_expected;
        #1; // settle, but NOT on posedge anymore
        if (state_out !== acc_ref) begin
            $display("[ERR][mash_acc_ce] state mismatch @%0t : got=%0d exp=%0d",
                     $time, state_out, acc_ref);
            errors = errors + 1;
        end
        if (p_out !== exp_p) begin
            $display("[ERR][mash_acc_ce] p_out mismatch @%0t : got=%0d exp=%0d",
                     $time, p_out, exp_p);
            errors = errors + 1;
        end
        if (res_out !== exp_res) begin
            $display("[ERR][mash_acc_ce] res_out mismatch @%0t : got=%0d exp=%0d",
                     $time, res_out, exp_res);
            errors = errors + 1;
        end
    end
    endtask

    task update_reference;
    begin
        if (!rst_n)
            acc_ref = {W{1'b0}};
        else if (ce)
            acc_ref = exp_res;
    end
    endtask

    task run_vector;
        input [W-1:0] val;
        input         ce_val;
    begin
        @(negedge clk);
        din = val;
        ce  = ce_val;

        #3;          // leave margin before posedge
        check_outputs;

        @(posedge clk);
        update_reference;
    end
    endtask

    initial begin
        clk     = 1'b0;
        rst_n   = 1'b0;
        ce      = 1'b1;
        din     = {W{1'b0}};
        acc_ref = {W{1'b0}};
        errors  = 0;
        seed    = 32'h12345678;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        run_vector(14'd0,     1'b1);
        run_vector(14'd1,     1'b1);
        run_vector(14'd8192,  1'b1);
        run_vector(14'd16383, 1'b1);
        run_vector(14'd1234,  1'b1);

        run_vector(14'd4000,  1'b0);
        run_vector(14'd9000,  1'b0);
        run_vector(14'd4000,  1'b1);

        for (i = 0; i < 40; i = i + 1)
            run_vector($random(seed) & 14'h3FFF, (i % 7 != 3));

        if (errors == 0)
            $display("[PASS] tb_mash_acc_ce passed.");
        else
            $display("[FAIL] tb_mash_acc_ce failed with %0d errors.", errors);

        $finish;
    end

endmodule
