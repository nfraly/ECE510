
module bsnn_addmm_top #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter THRESHOLD = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic valid,
    input  logic [WIDTH-1:0] input_row,
    input  logic [N_NEURONS-1:0][WIDTH-1:0] weight_matrix,
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
        .input_bits(input_row),
        .weights(weight_matrix),
        .spikes(spike_vector)
    );

endmodule
