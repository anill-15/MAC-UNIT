//------------------------------------------------------------------------------
// High-Speed Multiply Accumulate (MAC) Unit
// Designed and Developed by Anil
//
// © 2026 Anil. All Rights Reserved.
//------------------------------------------------------------------------------

`timescale 1ns/1ps
module tb_mac_top;
    reg clk;
    reg rstn;
    reg in_valid;
    reg clr_acc;
    reg [15:0] a, b;

    wire out_valid;
    wire [39:0] y;

    mac_top_best dut (
        .clk(clk),
        .rstn(rstn),
        .in_valid(in_valid),
        .clr_acc(clr_acc),
        .a(a),
        .b(b),
        .out_valid(out_valid),
        .y(y)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer seed;
    integer idx;
    integer waitc;
    reg [63:0] ref_acc;

    reg [15:0] a_values[0:2]; 
    reg [15:0] b_values[0:2];

    initial begin
        $dumpfile("tb_mac_top.vcd");
        $dumpvars(0, tb_mac_top);

        a_values[0] = 16'h1001;
        a_values[1] = 16'h00A0;
        a_values[2] = 16'hF00D;
        
        b_values[0] = 16'h00F0;
        b_values[1] = 16'h0200;
        b_values[2] = 16'h000F;

        seed = 424242;
        rstn = 1'b0; // [cite: 96]
        in_valid = 1'b0;
        clr_acc = 1'b0;
        a = 16'd0;
        b = 16'd0;
        ref_acc = 64'd0;

        #12;
        rstn = 1'b1;
        #10;
        clr_acc = 1'b1;
        @(posedge clk);
        clr_acc = 1'b0;

        for (idx = 0; idx < 3; idx = idx + 1) begin 
            a = a_values[idx];
            b = b_values[idx];

            in_valid = 1'b1;
            @(posedge clk);
            in_valid = 1'b0;
            ref_acc = ref_acc + ( {48'd0, a} * {48'd0, b} );

            waitc = 0;
            while (!out_valid && waitc < 100) begin 
                @(posedge clk);
                waitc = waitc + 1;
            end
            if (!out_valid) begin
                $display("ERROR: Timeout waiting for out_valid (txn %0d)", idx);
                $finish;
            end

            if (y !== ref_acc[39:0]) begin
                $display("Mismatch at txn %0d: a=0x%04h b=0x%04h DUT_y=0x%010h REF_y=0x%010h",
                         idx, a, b, y, ref_acc[39:0]);
                $finish;
            end else begin
                $display("Match! DUT=0x%010h REF=0x%010h (txn %0d)",
                         y, ref_acc[39:0], idx);
            end

            @(posedge clk);
        end

        $display("All matching — pass");
        $finish;
    end

endmodule
