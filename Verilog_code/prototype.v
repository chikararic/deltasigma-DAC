module prototype (
    input  wire               clk,        // 2x output-rate clock
    input  wire               rst_n,
    input  wire               din_valid,  // asserted on real input sample cycles
    input  wire signed [13:0] din,
    output reg  signed [19:0] dout,
    output reg                dout_valid
);

    integer i;
    reg phase;  // 1'b0: even-phase output, 1'b1: odd-phase output

    // d[0] = newest original-rate sample, d[11] = oldest
    reg signed [13:0] d [0:11];

    // Virtual taps used only for the even phase
    wire signed [13:0] t0;
    wire signed [13:0] t1;
    wire signed [13:0] t2;
    wire signed [13:0] t3;
    wire signed [13:0] t4;
    wire signed [13:0] t5;
    wire signed [13:0] t6;
    wire signed [13:0] t7;
    wire signed [13:0] t8;
    wire signed [13:0] t9;
    wire signed [13:0] t10;
    wire signed [13:0] t11;

    wire signed [14:0] s6;
    wire signed [14:0] s5;
    wire signed [14:0] s4;
    wire signed [14:0] s3;
    wire signed [14:0] s2;
    wire signed [14:0] s1;

    wire signed [23:0] s6e;
    wire signed [23:0] s5e;
    wire signed [23:0] s4e;
    wire signed [23:0] s3e;
    wire signed [23:0] s2e;
    wire signed [23:0] s1e;

    wire signed [23:0] p1;
    wire signed [23:0] p2;
    wire signed [23:0] p3;
    wire signed [23:0] p4;
    wire signed [23:0] p5;
    wire signed [23:0] p6;

    wire signed [26:0] even_sum;
    wire signed [19:0] odd_sum;

    // ------------------------------------------------------------
    // phase toggle
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            phase <= 1'b0;
        else
            phase <= ~phase;
    end

    // ------------------------------------------------------------
    // delay line update only on real input cycles
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 12; i = i + 1)
                d[i] <= 14'sd0;
        end else if ((phase == 1'b0) && din_valid) begin
            d[0] <= din;
            for (i = 1; i < 12; i = i + 1)
                d[i] <= d[i-1];
        end
    end

    // ------------------------------------------------------------
    // virtual shifted taps for EVEN phase computation
    // The current input sample must be visible immediately in y[2n].
    // ------------------------------------------------------------
    assign t0  = ((phase == 1'b0) && din_valid) ? din   : d[0];
    assign t1  = ((phase == 1'b0) && din_valid) ? d[0]  : d[1];
    assign t2  = ((phase == 1'b0) && din_valid) ? d[1]  : d[2];
    assign t3  = ((phase == 1'b0) && din_valid) ? d[2]  : d[3];
    assign t4  = ((phase == 1'b0) && din_valid) ? d[3]  : d[4];
    assign t5  = ((phase == 1'b0) && din_valid) ? d[4]  : d[5];
    assign t6  = ((phase == 1'b0) && din_valid) ? d[5]  : d[6];
    assign t7  = ((phase == 1'b0) && din_valid) ? d[6]  : d[7];
    assign t8  = ((phase == 1'b0) && din_valid) ? d[7]  : d[8];
    assign t9  = ((phase == 1'b0) && din_valid) ? d[8]  : d[9];
    assign t10 = ((phase == 1'b0) && din_valid) ? d[9]  : d[10];
    assign t11 = ((phase == 1'b0) && din_valid) ? d[10] : d[11];

    // ------------------------------------------------------------
    // symmetric pre-adders for EVEN phase
    // ------------------------------------------------------------
    assign s6 = $signed({t0[13],  t0 }) + $signed({t11[13], t11});
    assign s5 = $signed({t1[13],  t1 }) + $signed({t10[13], t10});
    assign s4 = $signed({t2[13],  t2 }) + $signed({t9[13],  t9 });
    assign s3 = $signed({t3[13],  t3 }) + $signed({t8[13],  t8 });
    assign s2 = $signed({t4[13],  t4 }) + $signed({t7[13],  t7 });
    assign s1 = $signed({t5[13],  t5 }) + $signed({t6[13],  t6 });

    assign s6e = {{9{s6[14]}}, s6};
    assign s5e = {{9{s5[14]}}, s5};
    assign s4e = {{9{s4[14]}}, s4};
    assign s3e = {{9{s3[14]}}, s3};
    assign s2e = {{9{s2[14]}}, s2};
    assign s1e = {{9{s1[14]}}, s1};

    // ------------------------------------------------------------
    // CSD constant multipliers
    // ------------------------------------------------------------
    // C1 = 2^-2 + 2^-4 + 2^-9
    assign p1 = (s1e >>> 2) + (s1e >>> 4) + (s1e >>> 9);

    // C2 = 2^-3 - 2^-5 + 2^-9
    assign p2 = (s2e >>> 3) - (s2e >>> 5) + (s2e >>> 9);

    // C3 = 2^-4 - 2^-6 + 2^-9
    assign p3 = (s3e >>> 4) - (s3e >>> 6) + (s3e >>> 9);

    // C4 = 2^-5 - 2^-8 - 2^-10
    assign p4 = (s4e >>> 5) - (s4e >>> 8) - (s4e >>> 10);

    // C5 = 2^-6 - 2^-9 - 2^-14
    assign p5 = (s5e >>> 6) - (s5e >>> 9) - (s5e >>> 14);

    // C6 = 2^-7 - 2^-11 - 2^-13
    assign p6 = (s6e >>> 7) - (s6e >>> 11) - (s6e >>> 13);

    assign even_sum =
        $signed({{3{p1[23]}}, p1}) +
        $signed({{3{p2[23]}}, p2}) +
        $signed({{3{p3[23]}}, p3}) +
        $signed({{3{p4[23]}}, p4}) +
        $signed({{3{p5[23]}}, p5}) +
        $signed({{3{p6[23]}}, p6});

    // odd-phase output: center tap only = 0.5 * x[n-5]
    assign odd_sum = ({{6{d[5][13]}}, d[5]} >>> 1);

    // ------------------------------------------------------------
    // output register
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout       <= 20'sd0;
            dout_valid <= 1'b0;
        end else begin
            dout_valid <= 1'b1;
            if (phase == 1'b1)
                dout <= odd_sum;
            else
                dout <= even_sum[19:0];
        end
    end

endmodule
