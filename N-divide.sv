module N_divide(
	input logic clk_out,		//100MHz output clock
	input logic rst_n,
	output logic clk_fb			//10M feedback
);
	
	reg [2:0] cnt;
	
	always_ff@(posedge clk_out or negedge rst_n)begin
		if(!rst_n)begin
			cnt <= 3'b0;
		end else if(cnt == 3'b100)begin
			cnt <= 3'b0;
		end else begin
			cnt <= cnt + 1;
		end
	end
	
	always_ff@(posedge clk_out or negedge rst_n)begin
		if(!rst_n)begin
			clk_fb <= 1'b0;
		end else if(cnt == 3'b100)begin
			clk_fb <= ~clk_fb;
		end else begin
			clk_fb <= clk_fb;
		end
	end
	
endmodule