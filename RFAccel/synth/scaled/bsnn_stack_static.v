
module bsnn_stack_static #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter NUM_LAYERS = 24,
    parameter THRESHOLD = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic valid,
    input  logic load,
    input  logic [$clog2(NUM_LAYERS)-1:0] layer_idx,
    input  logic [$clog2(N_NEURONS)-1:0] load_idx,
    input  logic [WIDTH-1:0] weight_input,
    input  logic [WIDTH-1:0] input_vector,
    output logic [N_NEURONS-1:0] final_spike_vector
);

    logic [N_NEURONS-1:0] spike_vectors [0:NUM_LAYERS-1];
    logic [WIDTH-1:0] layer_inputs [0:NUM_LAYERS-1];

    assign layer_inputs[0] = input_vector;

    genvar i;
    generate
        for (i = 0; i < NUM_LAYERS; i++) begin : layer
            wire sel = (layer_idx == i);
            bsnn_layer #(
                .WIDTH(WIDTH),
                .N_NEURONS(N_NEURONS),
                .THRESHOLD(THRESHOLD)
            ) layer_inst (
                .clk(clk),
                .rst(rst),
                .valid(valid),
                .load(load && sel),
                .load_idx(load_idx),
                .weight_input(weight_input),
                .input_bits(layer_inputs[i]),
                .spikes(spike_vectors[i])
            );

            if (i > 0)
                assign layer_inputs[i] = spike_vectors[i-1];
        end
    endgenerate

    assign final_spike_vector = spike_vectors[NUM_LAYERS-1];

endmodule

