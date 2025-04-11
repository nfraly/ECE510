
module lif_register_file #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter NUM_FIRST_LAYER = 4,
    parameter NUM_SECOND_LAYER = 4,
    parameter NUM_OUTPUTS = 4
)(
    input wire clk,
    input wire reset,
    input wire write_en,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out,

    output reg [WIDTH-1:0] threshold,
    output reg [WIDTH-1:0] leak,
    output reg [WIDTH-1:0] refractory,
    output reg [WIDTH-1:0] shared_weights [0:NUM_FIRST_LAYER-1][0:NUM_SECOND_LAYER-1]
);

    integer i, j;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            threshold <= 8'd100;
            leak <= 8'd1;
            refractory <= 8'd5;
            for (i = 0; i < NUM_FIRST_LAYER; i = i + 1)
                for (j = 0; j < NUM_SECOND_LAYER; j = j + 1)
                    shared_weights[i][j] <= 0;
        end else if (write_en) begin
            case (addr)
                8'd0: threshold <= data_in;
                8'd1: leak <= data_in;
                8'd2: refractory <= data_in;
                default: begin
                    if (addr >= 8'd16 && addr < 8'd16 + NUM_FIRST_LAYER*NUM_SECOND_LAYER) begin
                        i = (addr - 16) / NUM_SECOND_LAYER;
                        j = (addr - 16) % NUM_SECOND_LAYER;
                        shared_weights[i][j] <= data_in;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (addr)
            8'd0: data_out = threshold;
            8'd1: data_out = leak;
            8'd2: data_out = refractory;
            default: begin
                data_out = 0;
                if (addr >= 8'd16 && addr < 8'd16 + NUM_FIRST_LAYER*NUM_SECOND_LAYER) begin
                    i = (addr - 16) / NUM_SECOND_LAYER;
                    j = (addr - 16) % NUM_SECOND_LAYER;
                    data_out = shared_weights[i][j];
                end
            end
        endcase
    end
endmodule
