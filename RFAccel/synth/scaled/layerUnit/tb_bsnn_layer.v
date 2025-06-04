`timescale 1ns/1ps

module tb_bsnn_layer;

    parameter WIDTH = 8;
    parameter N_NEURONS = 4;
    parameter THRESHOLD = 5;

    reg clk, rst, valid, load;
    reg [$clog2(N_NEURONS)-1:0] load_idx;
    reg [WIDTH-1:0] weight_input, input_bits;
    wire [N_NEURONS-1:0] spikes;

    bsnn_layer #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .load(load),
        .load_idx(load_idx),
        .weight_input(weight_input),
        .input_bits(input_bits),
        .spikes(spikes)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Time | Input      | Spikes");
        $display("-------------------------------");

        // Initialize
        clk = 0;
        rst = 1;
        valid = 0;
        load = 0;
        input_bits = 0;
        weight_input = 0;
        load_idx = 0;
        #10;

        rst = 0;

        // Load weights into all neurons
        load_weights(0, 8'b11011011); // 6 matches expected
        load_weights(1, 8'b11110000); // 4 matches expected
        load_weights(2, 8'b00001111); // 4 matches expected
        load_weights(3, 8'b11111111); // 7 matches expected

        // Apply first input
        @(negedge clk);
        valid = 1;
        input_bits = 8'b11011111;
        @(negedge clk);
        $display("%4t | %b | %b", $time, input_bits, spikes);

        // Apply second input
        input_bits = 8'b11111111;  // max match for all
        @(negedge clk);
        $display("%4t | %b | %b", $time, input_bits, spikes);

        // Reset
        valid = 0;
        rst = 1;
        @(negedge clk);
        rst = 0;
        @(negedge clk);

        $finish;
    end

    task load_weights(input [$clog2(N_NEURONS)-1:0] idx, input [WIDTH-1:0] w);
        begin
            load_idx = idx;
            weight_input = w;
            load = 1;
            @(negedge clk);
            load = 0;
            @(negedge clk);
        end
    endtask

endmodule
