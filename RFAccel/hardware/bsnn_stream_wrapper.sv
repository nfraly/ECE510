module bsnn_stream_wrapper #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter THRESHOLD = 128,
    parameter NUM_LAYERS = 24
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

    logic processing;
    logic [NUM_LAYERS-1:0] valid_pipeline;
    logic [N_NEURONS-1:0] final_spike_vector;

    // Ready when not processing
    assign ready_in = !processing;
    assign output_spikes = final_spike_vector;
    assign valid_out = valid_pipeline[NUM_LAYERS-1];

    // Valid delay chain
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            processing <= 0;
            valid_pipeline <= '0;
        end else begin
            if (valid_in && ready_in) begin
                processing <= 1;
                valid_pipeline[0] <= 1;
            end else begin
                valid_pipeline[0] <= 0;
            end

            for (int i = 1; i < NUM_LAYERS; i++) begin
                valid_pipeline[i] <= valid_pipeline[i-1];
            end

            if (valid_out && ready_out) begin
                processing <= 0;
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
        .input_row(input_row),
        .weight_matrix_flat_array(weight_matrix_flat_array),
        .final_spike_vector(final_spike_vector)
    );

endmodule

