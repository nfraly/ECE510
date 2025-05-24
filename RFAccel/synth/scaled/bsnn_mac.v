
module bsnn_mac #(
    parameter WIDTH = 256,
    parameter COUNT_WIDTH = $clog2(WIDTH+1),
    parameter THRESHOLD = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic valid,
    input  logic [WIDTH-1:0] input_bits,
    input  logic [WIDTH-1:0] weight_bits,
    output logic spike
);

    logic [7:0] match_count;
    logic [WIDTH-1:0] xor_result;
    logic [WIDTH-1:0] xnor_result;

    assign xor_result  = input_bits ^ weight_bits;
    assign xnor_result = ~xor_result;


// Synthesis-safe popcount function
function [COUNT_WIDTH-1:0] popcount(input [WIDTH-1:0] value);
    integer i;
    popcount = 0;
    for (i = 0; i < WIDTH; i = i + 1)
        popcount = popcount + value[i];
endfunction


    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            match_count <= 0;
            spike <= 0;
        end else if (valid) begin
            match_count <= popcount(xnor_result);
            spike <= (popcount(xnor_result) >= THRESHOLD);
        end
    end

endmodule
