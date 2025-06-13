module bsnn_mac #(
    parameter WIDTH = 256,
    parameter THRESHOLD = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic valid,
    input  logic load,
    input  logic [WIDTH-1:0] weight_input,
    input  logic [WIDTH-1:0] input_bits,
    output logic spike
);

    logic [WIDTH-1:0] weight_reg;
    logic [WIDTH-1:0] xnor_result;
    logic [$clog2(WIDTH+1)-1:0] count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            weight_reg <= '0;
        else if (load)
            weight_reg <= weight_input;
    end

    always_comb begin
        xnor_result = ~(input_bits ^ weight_reg);
        count = '0;
        for (int i = 0; i < WIDTH; i++) begin
            count = count + xnor_result[i];
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            spike <= 0;
        else
            spike <= (valid && !load && count >= THRESHOLD);
    end

endmodule

