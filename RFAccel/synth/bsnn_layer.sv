
module bsnn_layer #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter THRESHOLD = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic valid,
    input  logic [WIDTH-1:0] input_bits,
    input  logic [WIDTH*N_NEURONS-1:0] weights_flat,
    output logic [N_NEURONS-1:0] spikes
);

    genvar i;
    generate
        for (i = 0; i < N_NEURONS; i++) begin : neurons
            bsnn_mac #(
                .WIDTH(WIDTH),
                .THRESHOLD(THRESHOLD)
            ) neuron (
                .clk(clk),
                .rst(rst),
                .valid(valid),
                .input_bits(input_bits),
                .weight_bits(weights_flat[i*WIDTH +: WIDTH]),
                .spike(spikes[i])
            );
        end
    endgenerate

endmodule

