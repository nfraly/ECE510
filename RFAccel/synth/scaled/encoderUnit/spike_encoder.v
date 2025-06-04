`timescale 1ns/1ps

module spike_encoder #(
    parameter WIDTH = 8,
    parameter signed [WIDTH-1:0] THRESHOLD = 0
) (
    input  wire signed [WIDTH-1:0] in_value,
    output wire spike
);
    assign spike = (in_value >= THRESHOLD) ? 1'b1 : 1'b0;
endmodule
