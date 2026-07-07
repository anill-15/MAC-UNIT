//------------------------------------------------------------------------------
// High-Speed Multiply Accumulate (MAC) Unit
// Designed and Developed by Anil
//
// © 2026 Anil. All Rights Reserved.
//------------------------------------------------------------------------------

`timescale 1ns/1ps
module vedic16_with_ks(
    input  [15:0] A,
    input  [15:0] B,
    output [31:0] P
);
    wire [7:0] A_lo = A[7:0];
    wire [7:0] A_hi = A[15:8];
    wire [7:0] B_lo = B[7:0];
    wire [7:0] B_hi = B[15:8];

    wire [15:0] pp0 = A_lo * B_lo;
    wire [15:0] pp1 = A_lo * B_hi;
    wire [15:0] pp2 = A_hi * B_lo;
    wire [15:0] pp3 = A_hi * B_hi;

    wire [31:0] s_pp0 = {16'b0, pp0};
    wire [31:0] s_pp1 = {8'b0, pp1, 8'b0};
    wire [31:0] s_pp2 = {8'b0, pp2, 8'b0}; 
    wire [31:0] s_pp3 = {pp3, 16'b0};     

    wire [31:0] sum_lo;
    wire co_lo;
    kogge_stone_adder_32 ks_lo (
        .A(s_pp0),
        .B(s_pp1),
        .Cin(1'b0),
        .Sum(sum_lo),
        .Cout(co_lo)
    );

    wire [31:0] sum_hi;
    wire co_hi;
    kogge_stone_adder_32 ks_hi (
        .A(s_pp2),
        .B(s_pp3),
        .Cin(1'b0),
        .Sum(sum_hi),
        .Cout(co_hi)
    );

    wire [31:0] final_sum;
    wire co_final;
    kogge_stone_adder_32 ks_final (
        .A(sum_lo),
        .B(sum_hi),
        .Cin(1'b0),
        .Sum(final_sum),
        .Cout(co_final)
    );

    assign P = final_sum;

endmodule
