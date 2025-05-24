`timescale 1ns/1ps

module tb_bsnn_stack_parametric;

    parameter WIDTH = 256;
    parameter N_NEURONS = 256;
    parameter THRESHOLD = 128;
    parameter NUM_LAYERS = 6;

    logic clk;
    logic rst;
    logic valid;
    logic [WIDTH-1:0] input_row;
    logic [NUM_LAYERS*WIDTH*N_NEURONS-1:0] weight_matrix_flat_array;
    logic [N_NEURONS-1:0] final_spike_vector;

    int i, j, k;
    int cycle_counter;
    int start_cycle;
    int latency;
    int csv_file;
    bit output_checked = 0;

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

    always #5 clk = ~clk;

    initial begin
        $display("Starting parametric BSNN stack test...");
        clk = 0;
        rst = 1;
        valid = 0;
        cycle_counter = 0;

        csv_file = $fopen("bsnn_stack_parametric_results.csv", "w");
        $fwrite(csv_file, "cycle,input_row,final_spike_vector\n");

        // Alternating input vector
        for (j = 0; j < WIDTH; j++) begin
            input_row[j] = j % 2;
        end

        // Fill weights with repeating checkerboard pattern per layer
        for (i = 0; i < NUM_LAYERS; i++) begin
            for (j = 0; j < N_NEURONS; j++) begin
                for (k = 0; k < WIDTH; k++) begin
                    weight_matrix_flat_array[
                        (i*WIDTH*N_NEURONS) + (j*WIDTH) + k
                    ] = (i + j + k) % 2;
                end
            end
        end

        #10 rst = 0;
        #10 valid = 1;
        @(posedge clk);
        start_cycle = cycle_counter;
        valid = 0;

        for (cycle_counter = 0; cycle_counter < 100; cycle_counter++) begin
            @(posedge clk);
            $fwrite(csv_file, "%0d,%h,%h\n", cycle_counter, input_row, final_spike_vector);
            if (!output_checked && final_spike_vector !== 0) begin
                output_checked = 1;
                latency = cycle_counter - start_cycle;
                $display("Detected output at cycle %0d (latency = %0d cycles)", cycle_counter, latency);
                $display("Final Output: %h", final_spike_vector);
            end
        end

        if (!output_checked) begin
            $display("ERROR: No spike output observed within 100 cycles.");
        end

        $fclose(csv_file);
        $display("Test completed. Output logged to bsnn_stack_parametric_results.csv.");
        $finish;
    end

endmodule

