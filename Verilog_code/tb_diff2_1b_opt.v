`timescale 1ns/1ps

module tb_diff2_1b_opt;

    reg  cur;
    reg  prev1;
    reg  prev2;
    wire signed [2:0] dout;

    diff2_1b_opt dut (
        .cur   (cur),
        .prev1 (prev1),
        .prev2 (prev2),
        .dout  (dout)
    );

    task automatic apply_and_check;
        input cur_i;
        input prev1_i;
        input prev2_i;
        input signed [2:0] exp_i;
        begin
            cur   = cur_i;
            prev1 = prev1_i;
            prev2 = prev2_i;
            #1;

            if (dout !== exp_i) begin
                $display("ERROR | cur=%0b prev1=%0b prev2=%0b | expected=%0d actual=%0d",
                         cur_i, prev1_i, prev2_i, exp_i, dout);
                $stop;
            end else begin
                $display("PASS  | cur=%0b prev1=%0b prev2=%0b | dout=%0d",
                         cur_i, prev1_i, prev2_i, dout);
            end
        end
    endtask

    initial begin
        apply_and_check(1'b0, 1'b0, 1'b0,  3'sd0);
        apply_and_check(1'b0, 1'b0, 1'b1,  3'sd1);
        apply_and_check(1'b0, 1'b1, 1'b0, -3'sd2);
        apply_and_check(1'b0, 1'b1, 1'b1, -3'sd1);
        apply_and_check(1'b1, 1'b0, 1'b0,  3'sd1);
        apply_and_check(1'b1, 1'b0, 1'b1,  3'sd2);
        apply_and_check(1'b1, 1'b1, 1'b0, -3'sd1);
        apply_and_check(1'b1, 1'b1, 1'b1,  3'sd0);

        $display("--------------------------------------------------");
        $display("All diff2_1b_opt tests passed.");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
