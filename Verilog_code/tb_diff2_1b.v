`timescale 1ns/1ps

module tb_diff2_1b;

    reg  cur;
    reg  pre1;
    reg  pre2;
    wire signed [2:0] dout;

    integer errors;
    integer exp_val;
    integer got_val;
    integer c, p1, p2;

    diff2_1b dut (
        .cur (cur),
        .pre1(pre1),
        .pre2(pre2),
        .dout(dout)
    );

    initial begin
        errors = 0;

        for (c = 0; c < 2; c = c + 1) begin
            for (p1 = 0; p1 < 2; p1 = p1 + 1) begin
                for (p2 = 0; p2 < 2; p2 = p2 + 1) begin
                    cur  = c[0];
                    pre1 = p1[0];
                    pre2 = p2[0];
                    #1;

                    exp_val = c - 2*p1 + p2;
                    got_val = $signed(dout);

                    if (got_val !== exp_val) begin
                        $display("[ERR][diff2_1b] cur=%0d pre1=%0d pre2=%0d got=%0d exp=%0d",
                                 c, p1, p2, got_val, exp_val);
                        errors = errors + 1;
                    end
                end
            end
        end

        if (errors == 0)
            $display("[PASS] tb_diff2_1b passed.");
        else
            $display("[FAIL] tb_diff2_1b failed with %0d errors.", errors);

        $finish;
    end

endmodule
