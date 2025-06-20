module bsnn_stream_wrapper_fifo #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter THRESHOLD = 128,
    parameter NUM_LAYERS = 24,
    parameter FIFO_DEPTH = 16
)(
    input  logic clk,
    input  logic rst,

    // Streaming input
    input  logic valid_in,
    output logic ready_in,
    input  logic [WIDTH-1:0] input_row,

    // Streaming output
    output logic valid_out,
    input  logic ready_out,
    output logic [N_NEURONS-1:0] output_spikes,

    // Preloaded weights
    input  logic [NUM_LAYERS*WIDTH*N_NEURONS-1:0] weight_matrix_flat_array
);

    logic [WIDTH-1:0] fifo [FIFO_DEPTH-1:0];
    logic [$clog2(FIFO_DEPTH)-1:0] head, tail;
    logic [FIFO_DEPTH:0] count;

    logic [WIDTH-1:0] current_input;
    logic processing;
    logic [NUM_LAYERS-1:0] valid_pipeline;
    logic [N_NEURONS-1:0] final_spike_vector;

    assign ready_in = (count < FIFO_DEPTH);
    assign valid_out = valid_pipeline[NUM_LAYERS-1];
    assign output_spikes = final_spike_vector;

    // FIFO control and pipeline shifting
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            processing <= 0;
            valid_pipeline <= 0;
        end else begin
            // Shift the pipeline
            valid_pipeline <= {valid_pipeline[NUM_LAYERS-2:0], 1'b0};

            // Output fully processed input
            if (valid_pipeline[NUM_LAYERS-1]) begin
                processing <= 0;
            end

            // Input accepted into FIFO
            if (valid_in && ready_in) begin
                fifo[tail] <= input_row;
                tail <= (tail + 1) % FIFO_DEPTH;
                count <= count + 1;
            end

            // Launch a new pipeline row
            if (!processing && head != tail) begin
                current_input <= fifo[head];
                head <= (head + 1) % FIFO_DEPTH;
                count <= count - 1;
                valid_pipeline[0] <= 1;
                processing <= 1;
            end
        end
    end

    bsnn_stack_parametric #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD),
        .NUM_LAYERS(NUM_LAYERS)
    ) core (
        .clk(clk),
        .rst(rst),
        .valid(valid_pipeline[0]),
        .input_row(current_input),
        .weight_matrix_flat_array(weight_matrix_flat_array),
        .final_spike_vector(final_spike_vector)
    );

endmodule

