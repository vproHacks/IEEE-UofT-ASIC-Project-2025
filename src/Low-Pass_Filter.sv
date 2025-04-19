module LPF(  					//low pass filter
	input logic clk,
	input logic rst_n,
	input logic up,
	input logic down,
	output logic signed [15:0] filtered_control_signal
);

	//use PI controller for first order filter transfer function
	parameter logic signed [15:0] Kp = 7;      //proportional gain
	parameter logic signed [15:0] Ki = 4;	  //integral gain
	
	logic signed [15:0] error;
	logic signed [31:0] phase_accumulator;
	
	//phase error decode
	always_comb begin
		if(!rst_n)
			error = 16'd0;
		else
			case({up, down})
				2'b10: error = 16'd1;
				2'b01: error = -16'd1;
				2'b00: error = 16'd0;
				default: error = 16'd0;
			endcase
	end	
	
	//Compute Ki/s integral
	always_ff@(posedge clk or negedge rst_n)begin				
		if(!rst_n)begin
			phase_accumulator <= 32'd0;
		end else begin
			phase_accumulator <= phase_accumulator + Ki * error;
		end
	end
	
	//Compute Kp+Ki/s
	assign filtered_control_signal = phase_accumulator + Kp * error;
	
endmodule