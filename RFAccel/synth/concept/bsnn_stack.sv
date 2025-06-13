
module bsnn_stack #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter THRESHOLD = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic valid,
    input  logic [WIDTH-1:0] input_row,
    input  logic [WIDTH*N_NEURONS-1:0] weight_matrix_0,
    input  logic [WIDTH*N_NEURONS-1:0] weight_matrix_1,
    input  logic [WIDTH*N_NEURONS-1:0] weight_matrix_2,
    output logic [N_NEURONS-1:0] final_spike_vector
);

    logic [N_NEURONS-1:0] spike_vector_0;
    logic [N_NEURONS-1:0] spike_vector_1;

    bsnn_addmm_top #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) layer0 (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .input_row(input_row),
        .weight_matrix_flat(weight_matrix_0),
        .spike_vector(spike_vector_0)
    );

    bsnn_addmm_top #(
        .WIDTH(N_NEURONS),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) layer1 (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .input_row(spike_vector_0),
        .weight_matrix_flat(weight_matrix_1),
        .spike_vector(spike_vector_1)
    );

    bsnn_addmm_top #(
        .WIDTH(N_NEURONS),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) layer2 (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .input_row(spike_vector_1),
        .weight_matrix_flat(weight_matrix_2),
        .spike_vector(final_spike_vector)
    );

endmodule

