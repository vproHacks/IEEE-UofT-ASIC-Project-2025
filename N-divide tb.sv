`timescale 1ns/1ps

module tb_N_divide();

    logic clk_out;
    logic rst_n;
    logic clk_fb;

    N_divide dut (
        .clk_out(clk_out),
        .rst_n(rst_n),
        .clk_fb(clk_fb)
    );

    always #5 clk_out = ~clk_out;
 

    initial begin

        clk_out = 0;
        rst_n = 0;

        #20;
        rst_n = 1;
    end
	
  	 initial begin          
        $dumpfile("dump.vcd");
        $dumpvars;
    end

  	initial begin
      #1000;
      $finish();
    end

endmodule