`timescale 1ns/1ps

module tb_bsnn_stream_wrapper_faulty;

    parameter WIDTH = 256;
    parameter N_NEURONS = 256;
    parameter THRESHOLD = 128;
    parameter NUM_LAYERS = 24;
    parameter NUM_INPUTS = 4;

    logic clk;
    logic rst;
    logic valid_in;
    logic ready_in;
    logic [WIDTH-1:0] input_row;
    logic valid_out;
    logic ready_out;
    logic [N_NEURONS-1:0] output_spikes;
    logic [NUM_LAYERS*WIDTH*N_NEURONS-1:0] weight_matrix_flat_array;

    int i, j, k;
    int csv_file;
    int send_index;
    int cycle_counter;
    bit output_checked = 0;

    // Instantiate DUT
    bsnn_stream_wrapper #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD),
        .NUM_LAYERS(NUM_LAYERS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .input_row(input_row),
        .valid_out(valid_out),
        .ready_out(ready_out),
        .output_spikes(output_spikes),
        .weight_matrix_flat_array(weight_matrix_flat_array)
    );

    always #5 clk = ~clk;

    initial begin
        $display("Starting streaming BSNN test with randomized backpressure...");
        clk = 0;
        rst = 1;
        valid_in = 0;
        ready_out = 1;
        cycle_counter = 0;

        // Open CSV
        csv_file = $fopen("bsnn_stream_faulty_results.csv", "w");
        $fwrite(csv_file, "cycle,valid_in,ready_in,input_row,valid_out,ready_out,output_spikes\n");

        // Init weights with deterministic pattern
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
        #10;

        send_index = 0;

        for (cycle_counter = 0; cycle_counter < 200; cycle_counter++) begin
            @(posedge clk);

            // Simulate randomized output backpressure (~25% chance of stalling)
            ready_out = ($urandom % 4 != 0);  // 75% chance ready

            // Drive input if allowed and not done
            if (ready_in && send_index < NUM_INPUTS) begin
                input_row = {WIDTH{send_index[0]}} ^ 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
                valid_in = 1;
                send_index++;
            end else begin
                valid_in = 0;
            end

            // Log output
            $fwrite(csv_file, "%0d,%b,%b,%h,%b,%b,%h\n",
                cycle_counter, valid_in, ready_in, input_row,
                valid_out, ready_out, output_spikes
            );
        end

        $fclose(csv_file);
        $display("Streaming test with faults complete. Output written to bsnn_stream_faulty_results.csv.");
        $finish;
    end

endmodule

