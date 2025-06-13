`timescale 1ns/1ps
module tb_bsnn_mac;

    parameter WIDTH = 8;
    parameter THRESHOLD = 3;

    logic clk = 0;
    always #5 clk = ~clk;

    logic rst, valid, load;
    logic [WIDTH-1:0] weight_input, input_bits;
    logic spike;

    logic [WIDTH-1:0] w, x;

    bsnn_mac #(.WIDTH(WIDTH), .THRESHOLD(THRESHOLD)) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .load(load),
        .weight_input(weight_input),
        .input_bits(input_bits),
        .spike(spike)
    );

    int total = 0, passed = 0, failed = 0;

    function automatic int popcount(input logic [WIDTH-1:0] bits);
        int count = 0;
        for (int i = 0; i < WIDTH; i++) begin
            if (bits[i])
                count++;
        end
        return count;
    endfunction

    task apply_and_check(input [WIDTH-1:0] w, input [WIDTH-1:0] x);
        int match_count;
        logic expected_spike;
        begin
            @(posedge clk);
            weight_input <= w;
            load <= 1;
            @(posedge clk);
            load <= 0;

            @(posedge clk);
            input_bits <= x;
            valid <= 1;
            @(posedge clk);
            valid <= 0;

            @(posedge clk); // allow spike to update

            match_count = popcount(~(w ^ x));  // bitwise XNOR
            expected_spike = (match_count >= THRESHOLD);

            total++;
            if (spike === expected_spike)
                passed++;
            else begin
                failed++;
                $display("FAIL @ time %0t | W=%b X=%b => Matches=%0d | spike=%b expected=%b",
                         $time, w, x, match_count, spike, expected_spike);
            end
        end
    endtask

    initial begin
        rst = 1; valid = 0; load = 0; input_bits = 0; weight_input = 0;
        repeat (2) @(posedge clk);
        rst = 0;

        for (int i = 0; i < 256; i++) begin
            w = $random;
            x = $random;
            apply_and_check(w, x);
        end

        $display("\nSUMMARY:");
        $display("Total tests  : %0d", total);
        $display("Passed       : %0d", passed);
        $display("Failed       : %0d", failed);
        $finish;
    end

endmodule

