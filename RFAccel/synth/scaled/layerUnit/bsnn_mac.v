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
    logic [$clog2(WIDTH+1)-1:0] acc_comb;
    logic [$clog2(WIDTH+1)-1:0] acc_reg;

    // Combinational block using if-based accumulation
    always_comb begin
        acc_comb = '0;
        for (int i = 0; i < WIDTH; i++) begin
            if (input_bits[i] == weight_reg[i])
                acc_comb = acc_comb + 1;
        end
    end

    // Sequential block for register updates and spike evaluation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            weight_reg <= '0;
            acc_reg <= '0;
            spike <= 0;
        end else begin
            if (load)
                weight_reg <= weight_input;

            acc_reg <= acc_comb;
            spike <= (valid && acc_reg >= THRESHOLD);
        end
    end

endmodule

