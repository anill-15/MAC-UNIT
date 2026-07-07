//------------------------------------------------------------------------------
// High-Speed Multiply Accumulate (MAC) Unit
// Designed and Developed by Anil
//
// © 2026 Anil. All Rights Reserved.
//------------------------------------------------------------------------------

`timescale 1ns/1ps
module kogge_stone_adder_32(
    input  [31:0] A,
    input  [31:0] B,
    input         Cin,
    output [31:0] Sum,
    output        Cout
);
    wire [31:0] g0;
    wire [31:0] p0;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gp0
            assign g0[i] = A[i] & B[i];
            assign p0[i] = A[i] ^ B[i];
        end
    endgenerate

    wire [31:0] g1, p1;
    generate
        for (i = 0; i < 32; i = i + 1) begin : st1
            if (i == 0) begin
                assign g1[i] = g0[i];
                assign p1[i] = p0[i];
            end else begin
                assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign p1[i] = p0[i] & p0[i-1];
            end
        end
    endgenerate

    wire [31:0] g2, p2;
    generate
        for (i = 0; i < 32; i = i + 1) begin : st2
            if (i < 2) begin
                assign g2[i] = g1[i];
                assign p2[i] = p1[i];
            end else begin
                assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
                assign p2[i] = p1[i] & p1[i-2];
            end
        end
    endgenerate

    wire [31:0] g3, p3;
    generate
        for (i = 0; i < 32; i = i + 1) begin : st3
            if (i < 4) begin
                assign g3[i] = g2[i];
                assign p3[i] = p2[i];
            end else begin
                assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
                assign p3[i] = p2[i] & p2[i-4];
            end
        end
    endgenerate

    wire [31:0] g4, p4;
    generate
        for (i = 0; i < 32; i = i + 1) begin : st4
            if (i < 8) begin
                assign g4[i] = g3[i];
                assign p4[i] = p3[i];
            end else begin
                assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
                assign p4[i] = p3[i] & p3[i-8];
            end
        end
    endgenerate

    wire [31:0] g5, p5;
    generate
        for (i = 0; i < 32; i = i + 1) begin : st5
            if (i < 16) begin
                assign g5[i] = g4[i];
                assign p5[i] = p4[i];
            end else begin
                assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
                assign p5[i] = p4[i] & p4[i-16];
            end
        end
    endgenerate

    wire [32:0] carry;
    assign carry[0] = Cin;
    generate
        for (i = 0; i < 32; i = i + 1) begin : carry_calc
            assign carry[i+1] = g5[i] | (p5[i] & Cin);
        end
    endgenerate

    generate
        for (i = 0; i < 32; i = i + 1) begin : sum_bits
            assign Sum[i] = p0[i] ^ carry[i];
        end
    endgenerate

    assign Cout = carry[32];

endmodule
