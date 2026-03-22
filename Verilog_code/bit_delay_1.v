`timescale 1ns/1ps

module bit_delay_1 (
    input  wire clk,
    input  wire rst_n,
    input  wire ce,
    input  wire din,
    output reg  dout
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= 1'b0;
        else if (ce)
            dout <= din;
    end

endmodule
