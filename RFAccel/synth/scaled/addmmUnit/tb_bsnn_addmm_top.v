`timescale 1ns/1ps

module tb_bsnn_addmm_top;

    parameter WIDTH = 256;
    parameter N_NEURONS = 256;
    parameter THRESHOLD = 8;

    reg clk, rst, valid, load;
    reg [$clog2(N_NEURONS)-1:0] load_idx;
    reg [WIDTH-1:0] weight_input, input_row;
    wire [N_NEURONS-1:0] spike_vector;

    bsnn_addmm_top #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .load(load),
        .load_idx(load_idx),
        .weight_input(weight_input),
        .input_row(input_row),
        .spike_vector(spike_vector)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i;

    initial begin
        $display("Time | Spike Count | Spike Vector");
        $display("--------------------------------------------");

        clk = 0;
        rst = 1;
        valid = 0;
        load = 0;
        load_idx = 0;
        input_row = 0;
        weight_input = 0;
        #10;

        rst = 0;

        // Set input pattern (last 8 bits = 1s)
        input_row = {248'b0, 8'b11111111};

        // Load each neuron with same pattern (last 8 bits = 1s)
        for (i = 0; i < N_NEURONS; i = i + 1) begin
            load_idx = i;
            weight_input = {248'b0, 8'b11111111};
            load = 1;
            @(negedge clk);
            load = 0;
            @(negedge clk);
        end

        // Delay 1 cycle before asserting valid
        @(negedge clk);

        // Trigger computation
        valid = 1;
        @(negedge clk);
        valid = 0;

        // Observe spike output and internal signals for several cycles
        repeat (5) begin
            @(negedge clk);
            $display("%4t | %3d         | %b", $time, $countones(spike_vector), spike_vector);

            // Debug one MAC unit (e.g., MAC 0)
            $display("MAC[0] input_bits:     %b", dut.core.neuron[0].mac.input_bits);
            $display("MAC[0] weight_reg:     %b", dut.core.neuron[0].mac.weight_reg);
            $display("MAC[0] xnor_result[7:0]: %b", dut.core.neuron[0].mac.xnor_result[7:0]);
            $display("MAC[0] count:          %0d", dut.core.neuron[0].mac.count);
            $display("MAC[0] spike:          %b",  dut.core.neuron[0].mac.spike);
        end

        $finish;
    end

endmodule

