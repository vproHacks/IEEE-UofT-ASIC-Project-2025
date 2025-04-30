//testbench for module N-divide 
//run on EDAPlayground
//B.Chen    Last Updated: 30/04/2025

`timescale 1ns / 1ps

module N_divide_tb;
  reg clk;
  reg rst_n;
  wire clk_fb;
  
  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    #40;
    rst_n = 1'b1;
  end
  
  always #16.5 clk = ~clk;
 
  N_divide dut(
    .clk(clk),
    .rst_n(rst_n),
    .clk_fb(clk_fb)
  );
  
  initial begin
    #300;
    $finish;
  end
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
  end
 
endmodule