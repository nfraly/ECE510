module bsnn_addmm_top #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter THRESHOLD = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic valid,
    input  logic load,
    input  logic [$clog2(N_NEURONS)-1:0] load_idx,
    input  logic [WIDTH-1:0] weight_input,
    input  logic [WIDTH-1:0] input_row,
    output logic [N_NEURONS-1:0] spike_vector
);

    bsnn_layer #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) core (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .load(load),
        .load_idx(load_idx),
        .weight_input(weight_input),
        .input_bits(input_row),
        .spikes(spike_vector)
    );

endmodule

