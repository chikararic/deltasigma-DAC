module diff1_1b (
    input  wire        cur,
    input  wire        pre,
    output wire signed [1:0] dout
);

    wire signed [1:0] cur_s;
    wire signed [1:0] pre_s;

    assign cur_s = {1'b0, cur};
    assign pre_s = {1'b0, pre};

    assign dout  = cur_s - pre_s;

endmodule
