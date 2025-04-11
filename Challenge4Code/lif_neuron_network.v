
// Top-level LIF Neuron Network with SPI and programmable parameters

module lif_neuron_network #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter NUM_FIRST_LAYER = 4,
    parameter NUM_SECOND_LAYER = 4,
    parameter NUM_OUTPUTS = 4
)(
    input wire clk,
    input wire reset,
    // SPI signals
    input wire spi_sck,
    input wire spi_mosi,
    input wire spi_cs,
    output wire spi_miso,
    input wire [WIDTH-1:0] input_spikes [0:NUM_FIRST_LAYER-1],
    output wire [NUM_OUTPUTS-1:0] output_spikes
);

    // SPI to Register File Control Signals
    wire [ADDR_WIDTH-1:0] addr;
    wire [WIDTH-1:0] data_in;
    wire [WIDTH-1:0] data_out;
    wire write_en;

    // Network Parameters from Register File
    wire [WIDTH-1:0] threshold;
    wire [WIDTH-1:0] leak;
    wire [WIDTH-1:0] refractory;
    wire [WIDTH-1:0] shared_weights [0:NUM_FIRST_LAYER-1][0:NUM_SECOND_LAYER-1];

    // SPI Interface
    spi_interface #(
        .WIDTH(WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) spi_ctrl (
        .clk(clk),
        .reset(reset),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_cs(spi_cs),
        .spi_miso(spi_miso),
        .write_en(write_en),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Register File for Parameters and Weights
    lif_register_file #(
        .WIDTH(WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_FIRST_LAYER(NUM_FIRST_LAYER),
        .NUM_SECOND_LAYER(NUM_SECOND_LAYER),
        .NUM_OUTPUTS(NUM_OUTPUTS)
    ) config_regfile (
        .clk(clk),
        .reset(reset),
        .write_en(write_en),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out),
        .threshold(threshold),
        .leak(leak),
        .refractory(refractory),
        .shared_weights(shared_weights)
    );

    // Signals between layers
    wire [WIDTH-1:0] first_layer_inputs [0:NUM_SECOND_LAYER-1];
    wire [0:NUM_SECOND_LAYER-1] first_layer_spikes;
    wire [WIDTH-1:0] output_inputs [0:NUM_OUTPUTS-1];

    genvar i, j;

    // Weighted sums for first layer neurons
    generate
        for (j = 0; j < NUM_SECOND_LAYER; j = j + 1) begin : first_layer_sum
            reg [WIDTH-1:0] sum = 0;
            always @(*) begin
                sum = 0;
                for (i = 0; i < NUM_FIRST_LAYER; i = i + 1)
                    sum = sum + (input_spikes[i] * shared_weights[i][j]);
            end
            assign first_layer_inputs[j] = sum;
        end
    endgenerate

    // Instantiate first layer LIF neurons
    generate
        for (j = 0; j < NUM_SECOND_LAYER; j = j + 1) begin : first_layer_neurons
            lif_neuron #(.WIDTH(WIDTH)) first_layer_neuron_inst (
                .clk(clk),
                .reset(reset),
                .input_current(first_layer_inputs[j]),
                .spike(first_layer_spikes[j])
            );

            defparam first_layer_neuron_inst.THRESHOLD = threshold;
            defparam first_layer_neuron_inst.LEAK = leak;
            defparam first_layer_neuron_inst.REFRACTORY = refractory;
        end
    endgenerate

    // Weighted sums for second layer neurons
    generate
        for (j = 0; j < NUM_OUTPUTS; j = j + 1) begin : output_layer_sum
            reg [WIDTH-1:0] sum = 0;
            always @(*) begin
                sum = 0;
                for (i = 0; i < NUM_SECOND_LAYER; i = i + 1)
                    sum = sum + (first_layer_spikes[i] * shared_weights[i][j]);
            end
            assign output_inputs[j] = sum;
        end
    endgenerate

    // Instantiate second layer LIF neurons
    generate
        for (j = 0; j < NUM_OUTPUTS; j = j + 1) begin : output_layer_neurons
            lif_neuron #(.WIDTH(WIDTH)) output_neuron_inst (
                .clk(clk),
                .reset(reset),
                .input_current(output_inputs[j]),
                .spike(output_spikes[j])
            );

            defparam output_neuron_inst.THRESHOLD = threshold;
            defparam output_neuron_inst.LEAK = leak;
            defparam output_neuron_inst.REFRACTORY = refractory;
        end
    endgenerate

endmodule
