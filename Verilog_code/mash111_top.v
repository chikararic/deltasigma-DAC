module mash111_top #(
    parameter W = 14
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         ce,
    input  wire [W-1:0] din,

    output wire         p0,
    output wire         p1,
    output wire         p2,

    output wire signed [1:0] d1,
    output wire signed [2:0] d2,
    output wire signed [3:0] y_raw,
    output wire [2:0]   y_map
);

    wire [W-1:0] e1;
    wire [W-1:0] e2;
    wire [W-1:0] st1;
    wire [W-1:0] st2;
    wire [W-1:0] st3;

    wire p1_d1;
    wire p2_d1;
    wire p2_d2;

    wire signed [3:0] p0_s;
    wire signed [3:0] d1_s;
    wire signed [3:0] d2_s;
    wire signed [3:0] y_map_s;

    // -----------------------------
    // Three cascaded first-order stages
    // -----------------------------
    mash_acc_ce #(.W(W)) u_stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(ce),
        .din(din),
        .p_out(p0),
        .res_out(e1),
        .state_out(st1)
    );

    mash_acc_ce #(.W(W)) u_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(ce),
        .din(e1),
        .p_out(p1),
        .res_out(e2),
        .state_out(st2)
    );

    mash_acc_ce #(.W(W)) u_stage3 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(ce),
        .din(e2),
        .p_out(p2),
        .res_out(),      // not used in current top
        .state_out(st3)
    );

    // -----------------------------
    // Delay chain
    // -----------------------------
    delay_1 #(.W(1)) u_p1_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(ce),
        .din(p1),
        .dout(p1_d1)
    );

    delay_1 #(.W(1)) u_p2_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(ce),
        .din(p2),
        .dout(p2_d1)
    );

    delay_1 #(.W(1)) u_p2_d2 (
        .clk(clk),
        .rst_n(rst_n),
        .ce(ce),
        .din(p2_d1),
        .dout(p2_d2)
    );

    // -----------------------------
    // Difference logic
    // -----------------------------
    diff1_1b u_diff1 (
        .cur (p1),
        .pre (p1_d1),
        .dout(d1)
    );

    diff2_1b u_diff2 (
        .cur (p2),
        .pre1(p2_d1),
        .pre2(p2_d2),
        .dout(d2)
    );

    // -----------------------------
    // Output recombination
    // y_raw = p0 + d1 + d2
    // y_map = y_raw + 3
    // -----------------------------
    assign p0_s    = {3'b000, p0};
    assign d1_s    = {{2{d1[1]}}, d1};
    assign d2_s    = {{1{d2[2]}}, d2};

    assign y_raw   = p0_s + d1_s + d2_s;
    assign y_map_s = y_raw + 4'sd3;
    assign y_map   = y_map_s[2:0];

endmodule
