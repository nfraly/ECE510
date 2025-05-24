
`timescale 1ns/1ps

module tb_bsnn_stack;

    parameter WIDTH = 256;
    parameter N_NEURONS = 256;
    parameter THRESHOLD = 128;

    logic clk;
    logic rst;
    logic valid;
    logic [WIDTH-1:0] input_row;
    logic [WIDTH*N_NEURONS-1:0] weight_matrix_0;
    logic [WIDTH*N_NEURONS-1:0] weight_matrix_1;
    logic [WIDTH*N_NEURONS-1:0] weight_matrix_2;
    logic [N_NEURONS-1:0] final_spike_vector;

    logic [N_NEURONS-1:0] expected_spikes_0, expected_spikes_1, expected_spikes_2;

    int i, j;
    int cycle_counter;
    int start_cycle;
    int latency;
    int csv_file;
    bit output_checked = 0;

    bsnn_stack #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .input_row(input_row),
        .weight_matrix_0(weight_matrix_0),
        .weight_matrix_1(weight_matrix_1),
        .weight_matrix_2(weight_matrix_2),
        .final_spike_vector(final_spike_vector)
    );

    always #5 clk = ~clk;

    initial begin
        $display("Starting 3-layer BSNN stack test...");
        clk = 0;
        rst = 1;
        valid = 0;
        cycle_counter = 0;

        csv_file = $fopen("bsnn_stack_results.csv", "w");
        $fwrite(csv_file, "cycle,input_row,final_spike_vector\n");

        // Input: alternating bits
        for (j = 0; j < WIDTH; j++) begin
            input_row[j] = j % 2;
        end

        // Weight matrix: checkerboard-style
        for (i = 0; i < N_NEURONS; i++) begin
            for (j = 0; j < WIDTH; j++) begin
                weight_matrix_0[i*WIDTH + j] = (i + j) % 2;
                weight_matrix_1[i*WIDTH + j] = (i + j + 1) % 2;
                weight_matrix_2[i*WIDTH + j] = (i * j) % 2;
            end
        end

        #10 rst = 0;
        #10 valid = 1;
        @(posedge clk);
        start_cycle = cycle_counter;
        valid = 0;

        // Simulate up to 40 cycles for propagation
        for (cycle_counter = 0; cycle_counter < 40; cycle_counter++) begin
            @(posedge clk);
            $fwrite(csv_file, "%0d,%h,%h\n", cycle_counter, input_row, final_spike_vector);

            // Check output exactly once when it becomes non-zero
            if (!output_checked && final_spike_vector !== 0) begin
                output_checked = 1;
                latency = cycle_counter - start_cycle;

                $display("Detected final output at cycle %0d (latency = %0d cycles)", cycle_counter, latency);
                $display("Final Output: %h", final_spike_vector);
            end
        end

        if (!output_checked) begin
            $display("ERROR: No spike output observed within 40 cycles.");
        end

        $fclose(csv_file);
        $display("Test completed. Output logged to bsnn_stack_results.csv.");
        $finish;
    end

endmodule

