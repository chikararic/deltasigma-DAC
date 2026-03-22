module mash_acc_ce #(
    parameter W = 14
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         ce,
    input  wire [W-1:0] din,
    output wire         p_out,
    output wire [W-1:0] res_out,
    output wire [W-1:0] state_out
);

    reg  [W-1:0] acc;
    wire [W:0]   sum;

    assign sum       = {1'b0, acc} + {1'b0, din};
    assign p_out     = sum[W];
    assign res_out   = sum[W-1:0];
    assign state_out = acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            acc <= {W{1'b0}};
        else if (ce)
            acc <= res_out;
    end

endmodule
