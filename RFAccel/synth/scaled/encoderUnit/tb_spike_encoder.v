`timescale 1ns/1ps

module tb_spike_encoder;

    parameter WIDTH = 8;
    parameter signed [WIDTH-1:0] THRESHOLD = 0;

    reg  signed [WIDTH-1:0] in_value;
    wire spike;

    spike_encoder #(
        .WIDTH(WIDTH),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .in_value(in_value),
        .spike(spike)
    );

    integer i;

    initial begin
        $display("Time | Input | Spike");
        $display("---------------------");

        for (i = -5; i <= 5; i = i + 1) begin
            in_value = i;
            #1;
            $display("%4t | %4d  |   %b", $time, in_value, spike);
        end

        $finish;
    end

endmodule
