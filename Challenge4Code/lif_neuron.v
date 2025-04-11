
module lif_neuron #(
    parameter WIDTH = 8,
    parameter THRESHOLD = 100,
    parameter LEAK = 1,
    parameter REFRACTORY = 5
)(
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] input_current,
    output reg spike
);

    reg [WIDTH+1:0] membrane_potential = 0;
    reg [$clog2(REFRACTORY+1)-1:0] refractory_counter = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            membrane_potential <= 0;
            spike <= 0;
            refractory_counter <= 0;
        end else begin
            if (refractory_counter > 0) begin
                refractory_counter <= refractory_counter - 1;
                spike <= 0;
            end else begin
                membrane_potential <= membrane_potential + input_current - LEAK;
                if (membrane_potential >= THRESHOLD) begin
                    spike <= 1;
                    membrane_potential <= 0;
                    refractory_counter <= REFRACTORY;
                end else begin
                    spike <= 0;
                end
            end
        end
    end
endmodule
