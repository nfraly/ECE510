`timescale 1ns/1ps

module bsnn_top_tb;

  reg clk = 0;
  reg rst = 1;
  reg valid_in = 0;
  reg [31:0] data_in = 0;
  wire ready_out;
  wire valid_out;
  wire [31:0] data_out;

  // Instantiate DUT
  bsnn_top uut (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .data_in(data_in),
    .ready_in(1'b1),           // Fixed: added missing port
    .ready_out(ready_out),
    .valid_out(valid_out),
    .data_out(data_out)
  );

  // Clock generation
  always #5 clk = ~clk;

  integer cycle_count = 0;

  initial begin
    $dumpfile("bsnn_top_tb.vcd");
    $dumpvars(0, bsnn_top_tb);

    #20; rst = 0; #20;

    // Apply one input
    valid_in = 1;
    data_in = 32'hDEADBEEF;
    #10;
    valid_in = 0;
    data_in = 32'h0;

    // Wait for output with timeout
    while (!valid_out && cycle_count < 1000) begin
      @(posedge clk);
      cycle_count++;
      if (valid_out)
        $display("Output received: %h at cycle %0d", data_out, cycle_count);
    end

    if (!valid_out) begin
      $display("TIMEOUT: valid_out never went high.");
    end

    $finish;
  end

endmodule

