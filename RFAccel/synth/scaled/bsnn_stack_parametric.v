module bsnn_stack_parametric #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter THRESHOLD = 128,
    parameter NUM_LAYERS = 6
)(
    input  logic clk,
    input  logic rst,
    input  logic valid,
    input  logic [WIDTH-1:0] input_row,
    input  logic [(NUM_LAYERS)*(WIDTH*N_NEURONS)-1:0] weight_matrix_flat_array,
    output logic [N_NEURONS-1:0] final_spike_vector
);

    logic [(NUM_LAYERS)*(N_NEURONS)-1:0] spike_vectors_flat; // flattened from [NUM_LAYERS][N_NEURONS]
    logic [NUM_LAYERS-1:0] valid_pipeline;

    // Generate valid delay pipeline
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_pipeline <= '0;
        end else begin
            valid_pipeline[0] <= valid;
            for (int i = 1; i < NUM_LAYERS; i++) begin
                valid_pipeline[i] <= valid_pipeline[i-1];
            end
        end
    end

    genvar i;
    generate
        for (i = 0; i < NUM_LAYERS; i++) begin : LAYER

            bsnn_addmm_top #(
                .WIDTH(i == 0 ? WIDTH : N_NEURONS),
                .N_NEURONS(N_NEURONS),
                .THRESHOLD(THRESHOLD)
            ) layer_inst (
                .clk(clk),
                .rst(rst),
                .valid(valid_pipeline[i]),
                .input_row(i == 0 ? input_row : spike_vectors[i-1]),
                .weight_matrix_flat(weight_matrix_flat_array_flat[i]),
                .spike_vector(spike_vectors_flat[i])
            );
        end
    endgenerate

    assign final_spike_vector = spike_vectors[NUM_LAYERS-1];

endmodule

