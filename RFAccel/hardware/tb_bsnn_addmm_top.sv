`timescale 1ns/1ps

module tb_bsnn_addmm_top;

    parameter WIDTH = 8;
    parameter N_NEURONS = 4;
    parameter THRESHOLD = 5;

    logic clk;
    logic rst;
    logic valid;
    logic [WIDTH-1:0] input_row;
    logic [N_NEURONS-1:0][WIDTH-1:0] weight_matrix;
    logic [N_NEURONS-1:0] spike_vector;

    logic [N_NEURONS-1:0] expected_spikes;
    logic [WIDTH-1:0] xnor_result;
    int i, j, match_count;

    bsnn_addmm_top #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .input_row(input_row),
        .weight_matrix(weight_matrix),
        .spike_vector(spike_vector)
    );

    always #5 clk = ~clk;

    initial begin
        $display("Starting bsnn_addmm_top Test...");
        clk = 0;
        rst = 1;
        valid = 0;
        input_row = 8'b11010110;

        weight_matrix[0] = 8'b11010110;
        weight_matrix[1] = 8'b11010100;
        weight_matrix[2] = 8'b00000000;
        weight_matrix[3] = 8'b11111111;

        #10 rst = 0;
        #10 valid = 1;
        #10 valid = 0;
        #20;

        for (i = 0; i < N_NEURONS; i++) begin
            xnor_result = ~(input_row ^ weight_matrix[i]);
            match_count = 0;
            for (j = 0; j < WIDTH; j++) begin
                match_count += xnor_result[j];
            end
            expected_spikes[i] = (match_count >= THRESHOLD);
        end

        $display("Spikes     : %b", spike_vector);
        $display("Expected   : %b", expected_spikes);

        if (spike_vector !== expected_spikes) begin
            $display("❌ ERROR: Spike output mismatch.");
            $fatal;
        end else begin
            $display("✅ PASS: Spike output matches expected.");
        end

        $finish;
    end

endmodule

