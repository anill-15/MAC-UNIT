//------------------------------------------------------------------------------
// High-Speed Multiply Accumulate (MAC) Unit
// Designed and Developed by Anil
//
// © 2026 Anil. All Rights Reserved.
//------------------------------------------------------------------------------

`timescale 1ns/1ps
module mac_top_best (
    input         clk,
    input         rstn,   
    input         in_valid,
    input         clr_acc, 
    input  [15:0] a,
    input  [15:0] b,
    output        out_valid,
    output [39:0] y
);
    reg [15:0] s0_a, s0_b;
    reg        s0_valid;

    always @(posedge clk) begin
        if (!rstn) begin
            s0_a <= 16'd0;
            s0_b <= 16'd0;
            s0_valid <= 1'b0;
        end else begin
            if (in_valid) begin
                s0_a <= a;
                s0_b <= b;
                s0_valid <= 1'b1;
            end else begin
                s0_valid <= 1'b0;
            end
        end
    end

    wire [31:0] prod_w;
    vedic16_with_ks vedic (
        .A(s0_a),
        .B(s0_b),
        .P(prod_w)
    );

    reg [31:0] prod_r;
    reg        s2_valid;
    always @(posedge clk) begin
        if (!rstn) begin
            prod_r <= 32'd0;
            s2_valid <= 1'b0;
        end else begin
            if (s0_valid) begin
                prod_r <= prod_w;
                s2_valid <= 1'b1;
            end else begin
                s2_valid <= 1'b0;
            end
        end
    end

    wire [39:0] prod_ext = {8'd0, prod_r};

    wire [39:0] sum_w;
    wire        carry_w;

    hybrid_han_carlson_adder_40 h40 (
        .A(y),     
        .B(prod_ext),
        .Cin(1'b0),
        .Sum(sum_w),
        .Cout(carry_w)
    );

    reg [39:0] acc_r;
    reg        out_valid_r;
    always @(posedge clk) begin
        if (!rstn) begin
            acc_r <= 40'd0;
            out_valid_r <= 1'b0;
        end else begin
            if (clr_acc) begin
                acc_r <= 40'd0;
                out_valid_r <= 1'b0;
            end else begin
                if (s2_valid) begin
                    acc_r <= sum_w;
                    out_valid_r <= 1'b1;
                end else begin
                    out_valid_r <= 1'b0;
                end
            end
        end
    end

    assign out_valid = out_valid_r;
    assign y = acc_r;

endmodule

module hybrid_han_carlson_adder_40 (
    input  [39:0] A,
    input  [39:0] B,
    input         Cin,
    output [39:0] Sum,
    output        Cout
);
    wire [39:0] g0, p0;
    genvar j;
    generate
        for (j = 0; j < 40; j = j + 1) begin : gp0_40
            assign g0[j] = A[j] & B[j];
            assign p0[j] = A[j] ^ B[j];
        end
    endgenerate

    wire [39:0] g1,p1,g2,p2,g3,p3,g4,p4,g5,p5,g6,p6;

    generate
        for (j = 0; j < 40; j = j + 1) begin : L1_40
            if (j == 0) begin
                assign g1[j] = g0[j];
                assign p1[j] = p0[j];
            end else begin
                assign g1[j] = g0[j] | (p0[j] & g0[j-1]);
                assign p1[j] = p0[j] & p0[j-1];
            end
        end
    endgenerate

    generate
        for (j = 0; j < 40; j = j + 1) begin : L2_40
            if (j < 2) begin
                assign g2[j] = g1[j];
                assign p2[j] = p1[j];
            end else begin
                assign g2[j] = g1[j] | (p1[j] & g1[j-2]);
                assign p2[j] = p1[j] & p1[j-2];
            end
        end
    endgenerate

    generate
        for (j = 0; j < 40; j = j + 1) begin : L3_40
            if (j < 4) begin
                assign g3[j] = g2[j];
                assign p3[j] = p2[j];
            end else begin
                assign g3[j] = g2[j] | (p2[j] & g2[j-4]);
                assign p3[j] = p2[j] & p2[j-4];
            end
        end
    endgenerate

    generate
        for (j = 0; j < 40; j = j + 1) begin : L4_40
            if (j < 8) begin
                assign g4[j] = g3[j];
                assign p4[j] = p3[j];
            end else begin
                if ((j % 8) == 7) begin
                    assign g4[j] = g3[j] | (p3[j] & g3[j-8]);
                    assign p4[j] = p3[j] & p3[j-8];
                end else begin
                    assign g4[j] = g3[j];
                    assign p4[j] = p3[j];
                end
            end
        end
    endgenerate

    generate
        for (j = 0; j < 40; j = j + 1) begin : L5_40
            if (j < 16) begin
                assign g5[j] = g4[j];
                assign p5[j] = p4[j];
            end else begin
                if ((j % 16) == 15) begin
                    assign g5[j] = g4[j] | (p4[j] & g4[j-16]);
                    assign p5[j] = p4[j] & p4[j-16];
                end else begin
                    assign g5[j] = g4[j];
                    assign p5[j] = p4[j];
                end
            end
        end
    endgenerate

    generate
        for (j = 0; j < 40; j = j + 1) begin : L6_40
            if (j < 32) begin
                assign g6[j] = g5[j];
                assign p6[j] = p5[j];
            end else begin
                assign g6[j] = g5[j] | (p5[j] & g5[j-32]);
                assign p6[j] = p5[j] & p5[j-32];
            end
        end
    endgenerate

    wire [40:0] carry40;
    assign carry40[0] = Cin;
    generate
        for (j = 0; j < 40; j = j + 1) begin : carry40_calc
            assign carry40[j+1] = g6[j] | (p6[j] & Cin);
        end
    endgenerate

    generate
        for (j = 0; j < 40; j = j + 1) begin : sum40_bits
            assign Sum[j] = p0[j] ^ carry40[j];
        end
    endgenerate

    assign Cout = carry40[40];

endmodule
