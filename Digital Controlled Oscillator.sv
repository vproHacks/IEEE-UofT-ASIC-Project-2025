//Self-oscillating Ring oscillator
//no need for external clock signal
//use inverter chain loop
//only for asic implementation, not synthesizable 

module DCO(						
  	input logic enable,
  input logic signed [15:0] control,		//PI controller output
  	output logic clk_out
);
  
  logic [4:0] stage;
  
  assign stage[0] = enable;
  
  genvar i;
  
  generate                          //use 5 inverter stages
    for(i = 0; i<4; i++)begin
      assign #((control + 32768)>>10) stage[i+1] = ~stage[i];    //adjusting delay here
    end
  endgenerate 
               
  assign clk_out = stage[4];
            
               
endmodule