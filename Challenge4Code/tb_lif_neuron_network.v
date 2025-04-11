
`timescale 1ns / 1ps

module tb_lif_neuron_network();

    parameter WIDTH = 8;
    parameter ADDR_WIDTH = 8;
    parameter NUM_FIRST_LAYER = 4;
    parameter NUM_SECOND_LAYER = 4;
    parameter NUM_OUTPUTS = 4;

    reg clk = 0;
    reg reset = 1;

    // SPI signals
    reg spi_sck = 0;
    reg spi_mosi = 0;
    reg spi_cs = 1;
    wire spi_miso;

    reg [WIDTH-1:0] input_spikes [0:NUM_FIRST_LAYER-1];
    wire [NUM_OUTPUTS-1:0] output_spikes;

    // Instantiate the network
    lif_neuron_network #(
        .WIDTH(WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_FIRST_LAYER(NUM_FIRST_LAYER),
        .NUM_SECOND_LAYER(NUM_SECOND_LAYER),
        .NUM_OUTPUTS(NUM_OUTPUTS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_cs(spi_cs),
        .spi_miso(spi_miso),
        .input_spikes(input_spikes),
        .output_spikes(output_spikes)
    );

    // Clock generator
    always #5 clk = ~clk;

    // SPI bit-banging task
    task spi_write;
        input [ADDR_WIDTH-1:0] addr;
        input [WIDTH-1:0] data;
        integer i;
        reg [ADDR_WIDTH+WIDTH-1:0] packet;
        begin
            packet = {addr, data};
            spi_cs = 0;
            for (i = ADDR_WIDTH+WIDTH-1; i >= 0; i = i - 1) begin
                spi_mosi = packet[i];
                #5 spi_sck = 1;
                #5 spi_sck = 0;
            end
            spi_cs = 1;
        end
    endtask

    initial begin
        // Initialize
        #10 reset = 0;

        // Write to shared_weights[0][0] = 8'hAA (addr = 16)
        spi_write(8'd16, 8'hAA);

        // Wait a bit and finish
        #100;

        $finish;
    end
endmodule
