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
    int launches = 0;
    int completions = 0;

    integer io_trace_file;
    initial begin
        io_trace_file = $fopen("io_trace_log.csv", "w");
        $fwrite(io_trace_file, "time,valid_in,ready_in,valid_out,ready_out\n");
    end
    int completed_id;
    int latency;
    
    

    // Testbench-side ID FIFO (depth = NUM_INPUTS)
    int id_fifo [NUM_INPUTS-1:0];
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
        $display("Starting BSNN FIFO test with pipeline trace...");
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
            if (dut.valid_pipeline[NUM_LAYERS-1]) completions++;

            $fwrite(csv_file, "%0d,%b,%b,%h,%b,%b,%h,%b,%0d,%0d,%0d,%b,%b\n",
                cycle_counter, valid_in, ready_in, input_row,
                valid_out, ready_out, output_spikes,
                dut.processing, dut.count, dut.head, dut.tail,
                dut.valid_pipeline[0], dut.valid_pipeline[NUM_LAYERS-1]
            );
        end

        $fclose(csv_file);

        $display("Final Launch and Completion Summary:");
        $display("  Launches:     %0d", launches);
        $display("  Completions:  %0d", completions);
        $display("  Inputs Sent:  %0d", send_index);
        $display("  Outputs Seen: %0d", output_index);

        $finish;
    end



    always @(posedge clk) begin
        $fwrite(io_trace_file, "%0t,%0b,%0b,%0b,%0b\n", $time, valid_in, ready_in, valid_out, ready_out);

        $display("[ %0t ns ] valid_in=%0b, ready_in=%0b | valid_out=%0b, ready_out=%0b", 
                 $time, valid_in, ready_in, valid_out, ready_out);

        if (!rst) begin
            if (valid_in && ready_in) begin
                input_times[send_index] = $time;
                
                id_fifo[fifo_tail] = send_index;
                fifo_tail++;

                $display("Input %0d sent at %0t", send_index, $time);
                send_index++;
                launches++;
            end

            if (valid_out && ready_out) begin
                
                completed_id = id_fifo[fifo_head];
                fifo_head++;
                
        $display("[ %0t ns ] valid_out=%0b, ready_out=%0b", $time, valid_out, ready_out);
        if (valid_out && ready_out) begin
            $display("[ %0t ns ] --> OUTPUT accepted, ID from FIFO: %0d", $time, completed_id);
        end
        latency = $time - input_times[completed_id];
                $fwrite(csv_file, "%0d,%0t,%0t,%0d\n",
                        completed_id,
                        input_times[completed_id],
                        $time,
                        latency);
                $display("Completed input ID %0d at time %0t", completed_id, $time);
                $display("Output %0d received at %0t (latency = %0d)", 
                         completed_id, $time, latency);

                completions++;

                
            end
        end
    end
endmodule
