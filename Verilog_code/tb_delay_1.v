`timescale 1ns/1ps

module tb_delay_1;

    parameter W = 8;

    reg             clk;
    reg             rst_n;
    reg             ce;
    reg  [W-1:0]    din;
    wire [W-1:0]    dout;

    reg  [W-1:0]    exp_dout;
    integer         errors;

    delay_1 #(.W(W)) dut (
        .clk (clk),
        .rst_n(rst_n),
        .ce  (ce),
        .din (din),
        .dout(dout)
    );

    always #5 clk = ~clk;

    task check_after_posedge;
    begin
        #1;
        if (dout !== exp_dout) begin
            $display("[ERR][delay_1] dout mismatch @%0t : got=%0d exp=%0d",
                     $time, dout, exp_dout);
            errors = errors + 1;
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

        @(posedge clk);
        if (!rst_n)
            exp_dout = {W{1'b0}};
        else if (ce)
            exp_dout = val;

        check_after_posedge;
    end
    endtask

    initial begin
        clk      = 1'b0;
        rst_n    = 1'b0;
        ce       = 1'b1;
        din      = {W{1'b0}};
        exp_dout = {W{1'b0}};
        errors   = 0;

        repeat (2) @(posedge clk);
        #1;
        if (dout !== {W{1'b0}}) begin
            $display("[ERR][delay_1] reset output not zero");
            errors = errors + 1;
        end

        @(negedge clk);
        rst_n = 1'b1;

        run_vector(8'h12, 1'b1);
        run_vector(8'hA5, 1'b1);
        run_vector(8'h3C, 1'b0); // hold
        run_vector(8'h7E, 1'b0); // hold
        run_vector(8'h55, 1'b1);

        if (errors == 0)
            $display("[PASS] tb_delay_1 passed.");
        else
            $display("[FAIL] tb_delay_1 failed with %0d errors.", errors);

        $finish;
    end

endmodule
