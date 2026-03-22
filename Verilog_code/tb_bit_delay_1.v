`timescale 1ns/1ps

module tb_bit_delay_1;

    reg clk;
    reg rst_n;
    reg ce;
    reg din;
    wire dout;

    bit_delay_1 dut (
        .clk  (clk),
        .rst_n(rst_n),
        .ce   (ce),
        .din  (din),
        .dout (dout)
    );

    reg ref_dout;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic apply_and_check;
        input din_i;
        input ce_i;
        begin
            @(negedge clk);
            din = din_i;
            ce  = ce_i;

            if (ce_i)
                ref_dout = din_i;

            @(posedge clk);
            #1;

            if (dout !== ref_dout) begin
                $display("ERROR @ t=%0t | din=%0b ce=%0b | expected dout=%0b, actual dout=%0b",
                         $time, din_i, ce_i, ref_dout, dout);
                $stop;
            end else begin
                $display("PASS  @ t=%0t | din=%0b ce=%0b | dout=%0b",
                         $time, din_i, ce_i, dout);
            end
        end
    endtask

    initial begin
        rst_n    = 1'b0;
        ce       = 1'b0;
        din      = 1'b0;
        ref_dout = 1'b0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        apply_and_check(1'b0, 1'b1); // dout=0
        apply_and_check(1'b1, 1'b1); // dout=1
        apply_and_check(1'b0, 1'b1); // dout=0
        apply_and_check(1'b1, 1'b0); // hold 0
        apply_and_check(1'b1, 1'b0); // hold 0
        apply_and_check(1'b1, 1'b1); // dout=1
        apply_and_check(1'b0, 1'b1); // dout=0

        $display("--------------------------------------------------");
        $display("All bit_delay_1 tests passed.");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
