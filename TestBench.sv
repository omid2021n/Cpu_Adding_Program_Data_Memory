`timescale 1ns / 1ps

module tb_top;

  // Inputs
  reg clk;
  reg sys_rst;
  reg [15:0] din;

  // Output
  wire [15:0] dout;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk),
    .sys_rst(sys_rst),
    .din(din),
    .dout(dout)
  );

  // Clock Generation: 10ns period
  always #5 clk = ~clk;

  initial begin
    // Initialize Inputs
    clk = 0;
    sys_rst = 1;
    din = 16'd1;

    // Apply reset for a few cycles
    #20;
    sys_rst = 0;

    // Run for enough time to execute instructions
    #500;

    $finish;
  end

  // Optional: Monitor dout and GPR during simulation
  initial begin
    $monitor("Time = %0t | dout = %h", $time, dout);
  end

  initial begin
  $dumpfile("wave.vcd");
  $dumpvars(0, tb_top);
end
  
endmodule


