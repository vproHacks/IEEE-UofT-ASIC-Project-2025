module N_divide(
  input logic clk,     
  input logic rst_n,    
  output logic clk_fb   
);

  logic [1:0] cnt_pos, cnt_neg; 
  logic clk_pos, clk_neg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_pos <= 2'b00;
    end else if(cnt_pos == 2'b10) begin
      cnt_pos <= 2'b00;
     end else begin 
       cnt_pos <= cnt_pos + 1;
    end
  end

  assign clk_pos = (cnt_pos == 2'b00);

  always_ff @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_neg <= 2'b00;
    end else if (cnt_neg == 2'b10)begin
      cnt_neg <= 2'b00; 
    end else begin
      cnt_neg <= cnt_neg + 1;
    end
  end

  assign clk_neg = (cnt_neg == 2'b00);

  assign clk_fb = clk_pos | clk_neg;

endmodule
