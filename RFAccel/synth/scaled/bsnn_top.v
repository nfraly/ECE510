
module bsnn_top (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] data_in,
    input  logic        valid_in,
    output logic        ready_out,
    output logic [31:0] data_out,
    output logic        valid_out,
    input  logic        ready_in
);

    // Internal spike vector
    logic [255:0] output_spikes;  // N_NEURONS assumed to be 256
    logic [255:0] unused_weights; // placeholder for completeness
    logic         internal_valid_out;

    // Stream wrapper with output spike vector exposed
    bsnn_stream_wrapper_fifo dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .output_spikes(output_spikes),
        .valid_out(valid_out),
        .ready_in(ready_in)
    );

    // Force output usage for synthesis (anchor spike vector)
    assign data_out = output_spikes[31:0];

endmodule

