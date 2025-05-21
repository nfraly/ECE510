
`timescale 1ns/1ps

module bsnn_layer_tb;

    localparam WIDTH = 8;
    localparam N_NEURONS = 4;
    localparam THRESHOLD = 5;

    logic clk;
    logic rst;
    logic valid;
    logic [WIDTH-1:0] input_bits;
    logic [N_NEURONS-1:0][WIDTH-1:0] weights;
    logic [N_NEURONS-1:0] spikes;

    bsnn_layer #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .input_bits(input_bits),
        .weights(weights),
        .spikes(spikes)
    );

    always #5 clk = ~clk;

    initial begin
        $display("Starting BSNN Layer Test...");
        clk = 0;
        rst = 1;
        valid = 0;
        input_bits = 8'b11010110;

        weights[0] = 8'b11010110;
        weights[1] = 8'b11010100;
        weights[2] = 8'b00000000;
        weights[3] = 8'b11111111;

        #10 rst = 0;
        #10 valid = 1;
        #10 valid = 0;

        #20;

        $display("Spikes: %b", spikes);

        if (spikes[0] !== 1) $error("Neuron 0 failed");
        if (spikes[1] !== 1) $error("Neuron 1 failed");
        if (spikes[2] !== 0) $error("Neuron 2 failed");
        if (spikes[3] !== 1) $error("Neuron 3 failed");

        $display("BSNN Layer Test completed.");
        $finish;
    end

endmodule
