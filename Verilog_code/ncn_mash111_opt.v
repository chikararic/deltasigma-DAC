`timescale 1ns/1ps

module ncn_mash111_opt (
    input  wire              c1,
    input  wire signed [1:0] d1_c2,
    input  wire signed [2:0] d2_c3,
    output wire signed [3:0] yout
);

    wire signed [3:0] c1_s;
    wire signed [3:0] d1_s;
    wire signed [3:0] d2_s;

    assign c1_s = c1 ? 4'sd1 : 4'sd0;
    assign d1_s = {{2{d1_c2[1]}}, d1_c2};
    assign d2_s = {{1{d2_c3[2]}}, d2_c3};

    assign yout = c1_s + d1_s + d2_s;

endmodule
