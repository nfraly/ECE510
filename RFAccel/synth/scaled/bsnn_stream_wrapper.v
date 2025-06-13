
module bsnn_stream_wrapper_fifo #(
    parameter WIDTH = 256,
    parameter N_NEURONS = 256,
    parameter NUM_LAYERS = 24,
    parameter THRESHOLD = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic [31:0] data_in,
    input  logic        valid_in,
    output logic        ready_out,
    output logic [31:0] data_out,
    output logic        valid_out,
    input  logic        ready_in
);

    typedef enum logic [1:0] {
        LOAD_WEIGHTS,
        WAIT_INPUT,
        RUN_INFER,
        STREAM_OUTPUT
    } state_t;

    state_t state, next_state;

    logic [WIDTH-1:0] weight_input, input_vector, spike_vector;
    logic [$clog2(WIDTH/32)-1:0] byte_count;
    logic [$clog2(N_NEURONS)-1:0] load_idx;
    logic [$clog2(NUM_LAYERS)-1:0] layer_idx;

    logic [WIDTH-1:0] input_buffer;
    logic [WIDTH-1:0] output_buffer;
    logic [2:0] out_word_idx;
    logic load, inference_valid;

    logic [NUM_LAYERS-1:0] valid_pipeline;

    // State transition
    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= LOAD_WEIGHTS;
        else     state <= next_state;
    end

    // Next state logic
    always_comb begin
        case (state)
            LOAD_WEIGHTS:
                next_state = (layer_idx == NUM_LAYERS-1 && load_idx == N_NEURONS-1 && byte_count == 7 && valid_in) ? WAIT_INPUT : LOAD_WEIGHTS;
            WAIT_INPUT:
                next_state = (valid_in) ? RUN_INFER : WAIT_INPUT;
            RUN_INFER:
                next_state = STREAM_OUTPUT;
            STREAM_OUTPUT:
                next_state = (out_word_idx == 7 && ready_in) ? WAIT_INPUT : STREAM_OUTPUT;
        endcase
    end

    // Counter logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_count <= 0;
            load_idx <= 0;
            layer_idx <= 0;
            out_word_idx <= 0;
        end else begin
            if (state == LOAD_WEIGHTS && valid_in) begin
                byte_count <= byte_count + 1;
                if (byte_count == 7) begin
                    byte_count <= 0;
                    load_idx <= load_idx + 1;
                    if (load_idx == N_NEURONS-1) begin
                        load_idx <= 0;
                        layer_idx <= layer_idx + 1;
                    end
                end
            end
            if (state == STREAM_OUTPUT && ready_in)
                out_word_idx <= out_word_idx + 1;
            else if (state != STREAM_OUTPUT)
                out_word_idx <= 0;
        end
    end

    // Assemble input for weight or inference
    always_ff @(posedge clk) begin
        if (valid_in) begin
            if (state == LOAD_WEIGHTS)
                weight_input <= {weight_input[WIDTH-33:0], data_in};
            else if (state == WAIT_INPUT)
                input_vector <= {input_vector[WIDTH-33:0], data_in};
        end
    end

    assign load = (state == LOAD_WEIGHTS && byte_count == 7 && valid_in);
    assign inference_valid = (state == RUN_INFER);

    // Valid pipeline logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            valid_pipeline <= '0;
        else if (inference_valid)
            valid_pipeline <= {valid_pipeline[NUM_LAYERS-2:0], 1'b1};
        else
            valid_pipeline <= {valid_pipeline[NUM_LAYERS-2:0], 1'b0};
    end

    bsnn_stack_static #(
        .WIDTH(WIDTH),
        .N_NEURONS(N_NEURONS),
        .NUM_LAYERS(NUM_LAYERS),
        .THRESHOLD(THRESHOLD)
    ) stack_inst (
        .clk(clk),
        .rst(rst),
        .valid(inference_valid),
        .load(load),
        .layer_idx(layer_idx),
        .load_idx(load_idx),
        .weight_input(weight_input),
        .input_vector(input_vector),
        .final_spike_vector(spike_vector)
    );

    assign output_buffer = spike_vector;
    assign data_out = output_buffer[255 - out_word_idx*32 -: 32];
    assign valid_out = (state == STREAM_OUTPUT) && valid_pipeline[NUM_LAYERS-1];
    assign ready_out = (state == LOAD_WEIGHTS || state == WAIT_INPUT);

endmodule

