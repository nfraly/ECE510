`timescale 1ns/1ps

module bsnn_top_tb;

  // Clock and reset
  logic clk;
  logic rst;

  // Top-level DUT IO
  logic in_valid, in_ready;
  logic [31:0] in_data;
  logic out_valid, out_ready;
  logic [31:0] out_data;

  // Clock generation
  always #5 clk = ~clk;

  // DUT instantiation
  bsnn_top dut (
    .clk       (clk),
    .rst       (rst),
    .in_valid  (in_valid),
    .in_ready  (in_ready),
    .in_data   (in_data),
    .out_valid (out_valid),
    .out_ready (out_ready),
    .out_data  (out_data)
  );

  // File handle (optional)
  // integer fd;

  initial begin
    $display(">>> Simulation started at %0t", $time);

    clk = 0;
    rst = 1;
    in_valid = 0;
    in_data = 0;
    out_ready = 1;

    // fd = $fopen("bsnn_sim.log", "w");

    #20;
    rst = 0;
    $display(">>> Reset deasserted at %0t", $time);

    // Send input vector (example pattern)
    repeat (5) @(posedge clk); // wait a few cycles

    in_valid = 1;
    in_data = 32'hCAFEBABE;
    $display("[TB] Sending input data: %h at %0t", in_data, $time);
    @(posedge clk);

    in_valid = 0;

    // Wait and observe output
    repeat (100) @(posedge clk);
    $display(">>> Simulation ending at %0t", $time);
    // $fclose(fd);
    $finish;
  end

  // Monitor output
  always_ff @(posedge clk) begin
    if (!rst && out_valid && out_ready) begin
      $display("[TB] Output data received: %h at %0t", out_data, $time);
      // $fwrite(fd, "Output received: %h at %0t\n", out_data, $time);
    end
  end

  // Internal trace (via hierarchical access)
  always_ff @(posedge clk) begin
    if (!rst) begin
      $display("[TRACE] layer_idx=%0d byte_count=%0d load_idx=%0d valid_pipeline=%b time=%0t",
        dut.wrapper.layer_idx,
        dut.wrapper.byte_count,
        dut.wrapper.load_idx,
        dut.wrapper.valid_pipeline,
        $time);
    end
  end

endmodule

