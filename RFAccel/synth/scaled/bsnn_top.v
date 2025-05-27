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

    bsnn_stream_wrapper_fifo dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .data_out(data_out),
        .valid_out(valid_out),
        .ready_in(ready_in)
    );

endmodule
