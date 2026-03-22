`timescale 1ns/1ps

module tb_ncn_mash111_opt;

    reg               c1;
    reg  signed [1:0] d1_c2;
    reg  signed [2:0] d2_c3;
    wire signed [3:0] yout;

    integer c1_i;
    integer d1_i;
    integer d2_i;
    integer exp_i;
    integer act_i;

    ncn_mash111_opt dut (
        .c1    (c1),
        .d1_c2 (d1_c2),
        .d2_c3 (d2_c3),
        .yout  (yout)
    );

    initial begin
        for (c1_i = 0; c1_i <= 1; c1_i = c1_i + 1) begin
            for (d1_i = -1; d1_i <= 1; d1_i = d1_i + 1) begin
                for (d2_i = -2; d2_i <= 2; d2_i = d2_i + 1) begin
                    c1    = c1_i[0];
                    d1_c2 = d1_i;
                    d2_c3 = d2_i;
                    #1;

                    exp_i = c1_i + d1_i + d2_i;
                    act_i = $signed(yout);

                    if (act_i !== exp_i) begin
                        $display("ERROR | c1=%0d d1=%0d d2=%0d | expected=%0d actual=%0d",
                                 c1_i, d1_i, d2_i, exp_i, act_i);
                        $stop;
                    end else begin
                        $display("PASS  | c1=%0d d1=%0d d2=%0d | yout=%0d",
                                 c1_i, d1_i, d2_i, act_i);
                    end
                end
            end
        end

        $display("--------------------------------------------------");
        $display("All ncn_mash111_opt tests passed.");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
