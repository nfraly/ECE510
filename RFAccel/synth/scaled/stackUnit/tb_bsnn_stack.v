`timescale 1ns/1ps

module tb_bsnn_stack;

    // Default parameters from bsnn_stack_parametric
    parameter WIDTH = 256;
    parameter N_NEURONS = 256;
    parameter NUM_LAYERS = 24;
    parameter THRESHOLD = 128;

    reg clk, rst, valid;
    reg [WIDTH-1:0] input_row;
    reg [(NUM_LAYERS)*(WIDTH*N_NEURONS)-1:0] weight_matrix_flat_array;
    wire [N_NEURONS-1:0] final_spike_vector;

    bsnn_stack_parametric #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD),
        .NUM_LAYERS(NUM_LAYERS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .input_row(input_row),
        .weight_matrix_flat_array(weight_matrix_flat_array),
        .final_spike_vector(final_spike_vector)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i;

    initial begin
        $display("Time | Final Spike Vector[7:0]");
        $display("----------------------------------");

        clk = 0;
        rst = 1;
        valid = 0;
        input_row = '0;
        weight_matrix_flat_array = '0;
        #10;

        rst = 0;

        // Set input_row to a simple pattern
        input_row = {248'b0, 8'b11111111};  // last 8 bits = all ones

        // Initialize weights for all layers (each neuron = all 1s)
        for (i = 0; i < NUM_LAYERS * N_NEURONS; i = i + 1) begin
            weight_matrix_flat_array[i*WIDTH +: WIDTH] = {248'b0, 8'b11111111};
        end

        // Trigger valid pulse
        @(negedge clk);
        valid = 1;
        @(negedge clk);
        valid = 0;

        // Wait a few cycles for propagation
        repeat (NUM_LAYERS + 2) @(negedge clk);
        $display("%4t | %b", $time, final_spike_vector[7:0]);

        $finish;
    end

endmodule

