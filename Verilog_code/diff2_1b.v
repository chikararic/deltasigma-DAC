module diff2_1b (
    input  wire        cur,
    input  wire        pre1,
    input  wire        pre2,
    output wire signed [2:0] dout
);

    wire signed [2:0] cur_s;
    wire signed [2:0] pre1_s;
    wire signed [2:0] pre2_s;

    assign cur_s  = {2'b00, cur};
    assign pre1_s = {2'b00, pre1};
    assign pre2_s = {2'b00, pre2};

    assign dout   = cur_s - (pre1_s + pre1_s) + pre2_s;

endmodule
