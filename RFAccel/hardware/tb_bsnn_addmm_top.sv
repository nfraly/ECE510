`timescale 1ns/1ps

module tb_bsnn_addmm_top;

    parameter WIDTH = 256;
    parameter N_NEURONS = 256;
    parameter THRESHOLD = 128;
    parameter NUM_VECTORS = 2;

    logic clk;
    logic rst;
    logic valid;
    logic [WIDTH-1:0] input_row;
    logic [N_NEURONS-1:0][WIDTH-1:0] weight_matrix;
    logic [N_NEURONS-1:0] spike_vector;

    logic [N_NEURONS-1:0] expected_spikes;
    logic [WIDTH-1:0] xnor_result;
    int i, j, match_count, cycle_counter;
    int vec;
    int csv;

    logic [NUM_VECTORS-1:0][WIDTH-1:0] input_vectors;

    bsnn_addmm_top #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .input_row(input_row),
        .weight_matrix(weight_matrix),
        .spike_vector(spike_vector)
    );

    always #5 clk = ~clk;

    initial begin
        $display("Starting 256x256 bsnn_addmm_top test...");
        clk = 0;
        rst = 1;
        valid = 0;
        cycle_counter = 0;

        csv = $fopen("bsnn_addmm_256x256_results.csv", "w");
        $fwrite(csv, "vector_id,input_row,spike_vector,expected_spikes,cycles,result\n");

        // Generate example weight matrix and input vectors
        for (i = 0; i < N_NEURONS; i++) begin
            for (j = 0; j < WIDTH; j++) begin
                weight_matrix[i][j] = (i + j) % 2;  // checkerboard pattern
            end
        end

        for (vec = 0; vec < NUM_VECTORS; vec++) begin
            for (j = 0; j < WIDTH; j++) begin
                input_vectors[vec][j] = (j + vec) % 2;  // alternating pattern per vector
            end
        end

        #10 rst = 0;

        for (vec = 0; vec < NUM_VECTORS; vec++) begin
            input_row = input_vectors[vec];
            valid = 1;
            @(posedge clk);
            cycle_counter = 1;
            valid = 0;

            @(posedge clk);
            cycle_counter += 1;

            #20; // allow time for spikes

            for (i = 0; i < N_NEURONS; i++) begin
                xnor_result = ~(input_row ^ weight_matrix[i]);
                match_count = 0;
                for (j = 0; j < WIDTH; j++) begin
                    match_count += xnor_result[j];
                end
                expected_spikes[i] = (match_count >= THRESHOLD);
            end

            $display("Vector %0d: Cycles = %0d", vec, cycle_counter);

            if (spike_vector !== expected_spikes) begin
                $display("ERROR: Spike output mismatch on vector %0d.", vec);
                $fwrite(csv, "%0d,%h,%h,%h,%0d,FAIL\n", vec, input_row, spike_vector, expected_spikes, cycle_counter);
                $fatal;
            end else begin
                $display("PASS: Output matches expected for vector %0d.", vec);
                $fwrite(csv, "%0d,%h,%h,%h,%0d,PASS\n", vec, input_row, spike_vector, expected_spikes, cycle_counter);
            end
        end

        $fclose(csv);
        $finish;
    end

endmodule

