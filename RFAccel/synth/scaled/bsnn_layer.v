
module bsnn_layer #(
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
    input  logic [WIDTH-1:0] input_bits,
    output logic [N_NEURONS-1:0] spikes
);

    genvar i;
    generate
        for (i = 0; i < N_NEURONS; i++) begin : neuron
            logic sel = (load_idx == i);

            bsnn_mac #(
                .WIDTH(WIDTH),
                .THRESHOLD(THRESHOLD)
            ) mac (
                .clk(clk),
                .rst(rst),
                .valid(valid),
                .load(load && sel),
                .weight_input(weight_input),
                .input_bits(input_bits),
                .spike(spikes[i])
            );
        end
    endgenerate

endmodule

