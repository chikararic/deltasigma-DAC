`timescale 1ns/1ps

module diff2_1b_opt (
    input  wire              cur,
    input  wire              prev1,
    input  wire              prev2,
    output reg  signed [2:0] dout
);

    always @(*) begin
        case ({cur, prev1, prev2})
            3'b000: dout =  3'sd0;   // 0 - 0 + 0 = 0
            3'b001: dout =  3'sd1;   // 0 - 0 + 1 = 1
            3'b010: dout = -3'sd2;   // 0 - 2 + 0 = -2
            3'b011: dout = -3'sd1;   // 0 - 2 + 1 = -1
            3'b100: dout =  3'sd1;   // 1 - 0 + 0 = 1
            3'b101: dout =  3'sd2;   // 1 - 0 + 1 = 2
            3'b110: dout = -3'sd1;   // 1 - 2 + 0 = -1
            3'b111: dout =  3'sd0;   // 1 - 2 + 1 = 0
            default: dout = 3'sd0;
        endcase
    end

endmodule
