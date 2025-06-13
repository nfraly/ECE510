`timescale 1ns/1ps

module bsnn_top_tb;

  // Clock and reset
  logic clk;
  logic rst;

  // DUT IO signals
  logic valid_in, ready_out;
  logic [31:0] data_in;
  logic valid_out, ready_in;
  logic [31:0] data_out;

  integer logfile;

  // Clock generation
  always #5 clk = ~clk;

  // DUT instantiation
  bsnn_top dut (
    .clk        (clk),
    .rst        (rst),
    .valid_in   (valid_in),
    .ready_out  (ready_out),
    .data_in    (data_in),
    .valid_out  (valid_out),
    .ready_in   (ready_in),
    .data_out   (data_out)
  );

  // Main test sequence
  initial begin
    logfile = $fopen("bsnn_tb_output.txt", "w");
    $fdisplay(logfile, ">>> Simulation started at %0t", $time);

    clk = 0;
    rst = 1;
    valid_in = 0;
    data_in = 0;
    ready_in = 1;  // downstream always ready

    #20;
    rst = 0;
    $fdisplay(logfile, ">>> Reset deasserted at %0t", $time);

    // Wait a few cycles before sending input
    repeat (5) @(posedge clk);

    valid_in = 1;
    data_in = 32'hCAFEBABE;
    $fdisplay(logfile, "[TB] Sending input data: %h at %0t", data_in, $time);
    @(posedge clk);

    valid_in = 0;

    // Wait for output or timeout
    repeat (100) @(posedge clk);
    $fdisplay(logfile, ">>> Simulation ending at %0t", $time);
    $fclose(logfile);
    $finish;
  end

  // Monitor output
  always_ff @(posedge clk) begin
    if (!rst && valid_out && ready_in) begin
      $fdisplay(logfile, "[TB] Output data received: %h at %0t", data_out, $time);
    end
  end

  // Optional: internal signal tracing
  always_ff @(posedge clk) begin
    if (!rst) begin
      $fdisplay(logfile,
        "[TRACE] layer_idx=%0d byte_count=%0d load_idx=%0d valid_pipeline=%b @ %0t",
        dut.wrapper.layer_idx,
        dut.wrapper.byte_count,
        dut.wrapper.load_idx,
        dut.wrapper.valid_pipeline,
        $time);
    end
  end

endmodule

