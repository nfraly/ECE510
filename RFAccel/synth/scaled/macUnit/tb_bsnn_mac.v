`timescale 1ns/1ps

module tb_bsnn_mac;

    parameter WIDTH = 8;
    parameter THRESHOLD = 5;

    reg clk, rst, valid, load;
    reg [WIDTH-1:0] weight_input, input_bits;
    wire spike;

    bsnn_mac #(
        .WIDTH(WIDTH),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .load(load),
        .weight_input(weight_input),
        .input_bits(input_bits),
        .spike(spike)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Time | Weight   | Input    | Spike");
        $display("------------------------------------");

        // Init
        clk = 0;
        rst = 1;
        load = 0;
        valid = 0;
        weight_input = 0;
        input_bits = 0;
        #10;

        rst = 0;

        // Load weights: 8'b11011011
        load = 1;
        weight_input = 8'b11011011;
        #10;
        load = 0;

        // Test 1: XNOR count = 6 → spike = 1 (>= 5)
        valid = 1;
        input_bits = 8'b11011111;
        #10;
        $display("%4t | %b | %b |   %b", $time, weight_input, input_bits, spike);

        // Test 2: XNOR count = 4 → spike = 0 (< 5)
        input_bits = 8'b11110000;
        #10;
        $display("%4t | %b | %b |   %b", $time, weight_input, input_bits, spike);

        // Test 3: XNOR count = 8 → spike = 1
        input_bits = 8'b11011011;
        #10;
        $display("%4t | %b | %b |   %b", $time, weight_input, input_bits, spike);

        valid = 0;
        #10;

        $finish;
    end

endmodule
