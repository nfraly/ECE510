`timescale 1ns/1ps

module tb_bsnn_stream_wrapper_fifo;

    parameter WIDTH = 256;
    parameter N_NEURONS = 256;
    parameter THRESHOLD = 128;
    parameter NUM_LAYERS = 24;
    parameter NUM_INPUTS = 256;

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
    int launches = 0;
    int completions = 0;
    int latency;
    int completed_id;

    int total_latency = 0;
    real avg_latency;
    real throughput;

    integer io_trace_file;
initial begin
    io_trace_file = $fopen("io_trace_log.csv", "w");
    $fwrite(io_trace_file, "time,valid_in,ready_in,valid_out,ready_out\n");
    wait (completions == NUM_INPUTS);
    $display("======== Throughput Report ========");
    $display("Launched %0d inputs", NUM_INPUTS);
    $display("Completed %0d outputs", completions);
    if (completions > 0) begin
        avg_latency = total_latency / completions;
        throughput = 1e9 / avg_latency;
        $display("Average latency: %0t ns", avg_latency);
        $display("Estimated throughput: %0.2f inferences/sec", throughput);
    end else begin
        $display("No completions observed; throughput not available.");
    end
    $finish;
end
    int fifo_head = 0;
    int fifo_tail = 0;

    initial begin
        csv_file = $fopen("bsnn_throughput_log.csv", "w");
        $fwrite(csv_file, "input_id,time_sent,time_received,latency\n");
    end
    bsnn_stream_wrapper_fifo #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD),
        .NUM_LAYERS(NUM_LAYERS),
        .FIFO_DEPTH(256)
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
        clk = 0;
        rst = 1;
        valid_in = 0;
        ready_out = 1;
        cycle_counter = 0;

        csv_file = $fopen("bsnn_stream_fifo_latency.csv", "w");
        $fwrite(csv_file, "cycle,valid_in,ready_in,input_row,valid_out,ready_out,output_spikes,processing,count,head,tail,valid_pipeline_0,valid_pipeline_end\n");

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

        while (output_index < NUM_INPUTS && cycle_counter < 10000) begin
            @(posedge clk);
            cycle_counter++;

            ready_out = ($urandom % 4 != 0);

            if (ready_in && send_index < NUM_INPUTS) begin
                input_row = {WIDTH{send_index[0]}} ^ 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
                valid_in = 1;
                input_times[send_index] = cycle_counter;
                send_index++;
            end else begin
                valid_in = 0;
            end

            if (valid_out && output_index < NUM_INPUTS) begin
                output_times[output_index] = cycle_counter;
                output_index++;
            end

            // Count launches and completions
            if (dut.valid_pipeline[0]) launches++;

            $fwrite(csv_file, "%0d,%b,%b,%h,%b,%b,%h,%b,%0d,%0d,%0d,%b,%b\n",
                cycle_counter, valid_in, ready_in, input_row,
                valid_out, ready_out, output_spikes,
                dut.processing, dut.count, dut.head, dut.tail,
                dut.valid_pipeline[0], dut.valid_pipeline[NUM_LAYERS-1]
            );
        end

        $fclose(csv_file);

    $display("======== Throughput Report ========");
    $display("Launched %0d inputs", NUM_INPUTS);
    $display("Completed %0d outputs", completions);
    if (completions > 0) begin
        avg_latency = total_latency / completions;
        throughput = 1e9 / avg_latency;
        $display("Average latency: %0t ns", avg_latency);
        $display("Estimated throughput: %0.2f inferences/sec", throughput);
    end else begin
        $display("No completions observed; throughput not available.");
    end
    end

    always @(posedge clk) begin
        $fwrite(io_trace_file, "%0t,%0b,%0b,%0b,%0b\n", $time, valid_in, ready_in, valid_out, ready_out);

        if (!rst) begin
            if (valid_in && ready_in) begin
                input_times[send_index] = $time;

                fifo_tail++;

                send_index++;
                launches++;
            end

            if (valid_out && ready_out) begin

            if (valid_out && ready_out) begin
        output_times[completed_id] = $time;
        total_latency += output_times[completed_id] - input_times[completed_id];
        completions++;
        if (completions == NUM_INPUTS) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (output_times[i] > input_times[i]) begin
                    total_latency += output_times[i] - input_times[i];
                end
            end
            avg_latency = total_latency / completions;
            throughput = 1e9 / avg_latency;
            $display("======== Throughput Report ========");
            $display("Launched %0d inputs", NUM_INPUTS);
            $display("Completed %0d outputs", completions);
            $display("Average latency: %0t ns", avg_latency);
            $display("Estimated throughput: %0.2f inferences/sec", throughput);
            $fclose(csv_file);
            $finish;
        end
                fifo_head++;

        if (valid_out && ready_out) begin
        end
            latency = $time - input_times[completed_id];
    $fwrite(csv_file, "%0d,%0t,%0t,%0d\n",
            completed_id,
            input_times[completed_id],
            $time,
            latency);

end
                $fwrite(csv_file, "%0d,%0t,%0t,%0d\n",
                        completed_id,
                        input_times[completed_id],
                        $time,
                        latency);

            end
        end
    end
initial begin
    wait (completions == NUM_INPUTS);
    for (int i = 0; i < NUM_INPUTS; i++) begin
        if (output_times[i] > input_times[i]) begin
            total_latency += output_times[i] - input_times[i];
        end
    end
    avg_latency = total_latency / completions;
    throughput = 1e9 / avg_latency;
    $display("======== Throughput Report ========");
    $display("Launched %0d inputs", NUM_INPUTS);
    $display("Completed %0d outputs", completions);
    $display("Average latency: %0t ns", avg_latency);
    $display("Estimated throughput: %0.2f inferences/sec", throughput);
    $fclose(csv_file);
end
reg [31:0] completion_count_prev = 0;
reg [31:0] completion_idle_cycles = 0;

always @(posedge clk) begin
    if (completion_count_prev == completions) begin
        completion_idle_cycles <= completion_idle_cycles + 1;
    end else begin
        completion_count_prev <= completions;
        completion_idle_cycles <= 0;
    end

    if (completion_idle_cycles > 100000) begin
        $display("Timeout reached: completions stalled.");
        $display("======== Throughput Report ========");
        $display("Launched %0d inputs", NUM_INPUTS);
        $display("Completed %0d outputs", completions);
        $display("Average latency: %0t ns", avg_latency);
        $display("Estimated throughput: %0.2f inferences/sec", throughput);
        $finish;
    end
end
endmodule
