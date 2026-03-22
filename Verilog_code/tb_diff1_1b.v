`timescale 1ns/1ps

module tb_diff1_1b;

    reg  cur;
    reg  pre;
    wire signed [1:0] dout;

    integer errors;
    integer exp_val;
    integer got_val;

    diff1_1b dut (
        .cur (cur),
        .pre (pre),
        .dout(dout)
    );

    task run_case;
        input c;
        input p;
    begin
        cur = c;
        pre = p;
        #1;

        exp_val = (c ? 1 : 0) - (p ? 1 : 0);
        got_val = $signed(dout);

        if (got_val !== exp_val) begin
            $display("[ERR][diff1_1b] cur=%0d pre=%0d got=%0d exp=%0d",
                     c, p, got_val, exp_val);
            errors = errors + 1;
        end
    end
    endtask

    initial begin
        errors = 0;

        run_case(1'b0, 1'b0);
        run_case(1'b0, 1'b1);
        run_case(1'b1, 1'b0);
        run_case(1'b1, 1'b1);

        if (errors == 0)
            $display("[PASS] tb_diff1_1b passed.");
        else
            $display("[FAIL] tb_diff1_1b failed with %0d errors.", errors);

        $finish;
    end

endmodule
