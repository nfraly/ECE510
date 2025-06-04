`timescale 1ns/1ps

module tb_bsnn_layer;

    parameter WIDTH = 8;
    parameter N_NEURONS = 4;
    parameter THRESHOLD = 3;
    parameter N_TESTS = 200;

    reg clk, rst, valid, load;
    reg [$clog2(N_NEURONS)-1:0] load_idx;
    reg [WIDTH-1:0] weight_input, input_bits;
    wire [N_NEURONS-1:0] spikes;

    integer i, j, errors, passes;
    reg [WIDTH-1:0] weights [0:N_NEURONS-1];
    integer fd;

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
        fd = $fopen("layer_test_output.txt", "w");
        clk = 0;
        rst = 1;
        valid = 0;
        load = 0;
        weight_input = 0;
        input_bits = 0;
        load_idx = 0;
        errors = 0;
        passes = 0;
        #10;
        rst = 0;

        for (i = 0; i < N_TESTS; i = i + 1) begin
            // Randomly generate weights for all neurons
            for (j = 0; j < N_NEURONS; j = j + 1) begin
                weights[j] = $random;
                load_weights(j, weights[j]);
            end

            // Random input bits
            input_bits = $random;
            @(negedge clk);
            valid = 1;
            @(negedge clk);
            valid = 0;

            // Check spike outputs
            for (j = 0; j < N_NEURONS; j = j + 1) begin
                integer expected, actual;
                expected = popcount(weights[j] & input_bits) >= THRESHOLD;
                actual = spikes[j];
                if (actual !== expected) begin
                    errors = errors + 1;
                    $fwrite(fd, "FAIL @%0t NEURON[%0d] | w=%b in=%b -> exp=%0d got=%0d\n",
                            $time, j, weights[j], input_bits, expected, actual);
                end else begin
                    passes = passes + 1;
                end
            end

            // Reset layer between tests
            rst = 1;
            @(negedge clk);
            rst = 0;
        end

        $display("SUMMARY: %0d passes / %0d errors out of %0d trials", passes, errors, passes + errors);
        $fwrite(fd, "SUMMARY: %0d passes / %0d errors out of %0d trials\n",
                        passes, errors, passes + errors);
        $fclose(fd);
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

    function integer popcount(input [WIDTH-1:0] x);
        integer k;
        begin
            popcount = 0;
            for (k = 0; k < WIDTH; k = k + 1)
                popcount = popcount + x[k];
        end
    endfunction

endmodule

