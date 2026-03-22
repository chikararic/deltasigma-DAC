module delay_1 #(
    parameter W = 1
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         ce,
    input  wire [W-1:0] din,
    output reg  [W-1:0] dout
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= {W{1'b0}};
        else if (ce)
            dout <= din;
    end

endmodule
