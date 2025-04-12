module N_divide(
  input logic clk_out,    //30MHz  
  input logic rst_n,    
  output logic clk_fb   //10MHz feedback clock with 50% duty cycle
);

  logic [1:0] cnt_pos, cnt_neg; 
  logic clk_pos, clk_neg;

  always_ff @(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
      cnt_pos <= 2'b00;
    end else if(cnt_pos == 2'b10) begin
      cnt_pos <= 2'b00;
     end else begin 
       cnt_pos <= cnt_pos + 1;
    end
  end

  always_ff @(negedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
      cnt_neg <= 2'b00;
    end else if (cnt_neg == 2'b10)begin
      cnt_neg <= 2'b00; 
    end else begin
      cnt_neg <= cnt_neg + 1;
    end
  end

  assign clk_fb = cnt_pos == 2'b00 | cnt_neg == 2'b00;

endmodule
