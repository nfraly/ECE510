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

    logic [N_NEURONS-1:0] spike_raw;

    genvar i;
    generate
        for (i = 0; i < N_NEURONS; i++) begin : neuron
            bsnn_mac #(
                .WIDTH(WIDTH),
                .THRESHOLD(THRESHOLD)
            ) mac (
                .clk(clk),
                .rst(rst),
                .valid(valid),
                .load(load && (load_idx == i)),
                .weight_input(weight_input),
                .input_bits(input_bits),
                .spike(spike_raw[i])
            );
        end
    endgenerate


    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            spikes <= '0;
        else if (valid)
            spikes <= spike_raw;
    end

endmodule


