`timescale 1ns/1ps

module tb_bsnn_stream_wrapper_fifo;

    parameter WIDTH = 256;
    parameter N_NEURONS = 256;
    parameter THRESHOLD = 128;
    parameter NUM_LAYERS = 24;
    parameter NUM_INPUTS = 8;

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
    int cycle_counter;
    int input_times[NUM_INPUTS];
    int output_times[NUM_INPUTS];
    int output_index = 0;
    int send_index = 0;

    bsnn_stream_wrapper_fifo #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD),
        .NUM_LAYERS(NUM_LAYERS),
        .FIFO_DEPTH(16)
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
        $display("Starting BSNN FIFO test with complete-output condition...");
        clk = 0;
        rst = 1;
        valid_in = 0;
        ready_out = 1;
        cycle_counter = 0;

        csv_file = $fopen("bsnn_stream_fifo_latency.csv", "w");
        $fwrite(csv_file, "cycle,valid_in,ready_in,input_row,valid_out,ready_out,output_spikes,processing,count,head,tail,valid_pipeline_end\n");

        for (i = 0; i < NUM_LAYERS; i++) begin
            for (j = 0; j < N_NEURONS; j++) begin
                for (k = 0; k < WIDTH; k++) begin
                    weight_matrix_flat_array[
                        (i*WIDTH*N_NEURONS) + (j*WIDTH) + k
                    ] = (i + j + k) % 2;
                end
            end
        end

        for (i = 0; i < NUM_INPUTS; i++) begin
            input_times[i] = -1;
            output_times[i] = -1;
        end

        #10 rst = 0;
        #10;

        while (output_index < NUM_INPUTS) begin
            if (cycle_counter > 10000) begin
                $display("ERROR: Simulation timeout. Not all outputs completed.");
                $display("Final Latency Results:");
        for (i = 0; i < NUM_INPUTS; i++) begin
            if (input_times[i] >= 0 && output_times[i] >= 0) begin
                $display("Input %0d: latency = %0d cycles", i, output_times[i] - input_times[i]);
            end else begin
                $display("Input %0d: incomplete", i);
            end
        end
        $finish;
            end
            @(posedge clk);
            cycle_counter++;

            // Random 25% backpressure
            ready_out = ($urandom % 4 != 0);

            // Send inputs if ready
            if (ready_in && send_index < NUM_INPUTS) begin
                input_row = {WIDTH{send_index[0]}} ^ 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
                valid_in = 1;
                input_times[send_index] = cycle_counter;
                send_index++;
            end else begin
                valid_in = 0;
            end

            // Track output latency
            if (valid_out && output_index < NUM_INPUTS) begin
                output_times[output_index] = cycle_counter;
                output_index++;
            end

            // Log signals
            $fwrite(csv_file, "%0d,%b,%b,%h,%b,%b,%h,%b,%0d,%0d,%0d,%b\n", cycle_counter, valid_in, ready_in, input_row, valid_out, ready_out, output_spikes, dut.processing, dut.count, dut.head, dut.tail, dut.valid_pipeline[NUM_LAYERS-1]);
        end

        $fclose(csv_file);

        $display("Final Latency Results:");
        for (i = 0; i < NUM_INPUTS; i++) begin
            if (input_times[i] >= 0 && output_times[i] >= 0) begin
                $display("Input %0d: latency = %0d cycles", i, output_times[i] - input_times[i]);
            end else begin
                $display("Input %0d: incomplete", i);
            end
        end

        $display("Final Latency Results:");
        for (i = 0; i < NUM_INPUTS; i++) begin
            if (input_times[i] >= 0 && output_times[i] >= 0) begin
                $display("Input %0d: latency = %0d cycles", i, output_times[i] - input_times[i]);
            end else begin
                $display("Input %0d: incomplete", i);
            end
        end
        $finish;
    end

endmodule

