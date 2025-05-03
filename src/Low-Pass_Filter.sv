module LPF(  					//low pass filter
	input logic clk,
	input logic rst_n,
	input logic up,
	input logic down,
	output logic signed [15:0] filtered_control_signal,
	input logic scan_in,
	input logic scan_en,
	output logic scan_out
);

	//use PI controller for first order filter transfer function
	parameter logic signed [15:0] Kp = 7;      //proportional gain
	parameter logic signed [15:0] Ki = 4;	  //integral gain
	
	logic signed [15:0] error;
	logic signed [31:0] phase_accumulator;
	
	integer i;
	
	//phase error decode
	always_comb begin
		if(!rst_n)
			error = 16'd0;
		else
			case({up, down})
				2'b10: error = -16'd1;
				2'b01: error = 16'd1;
				2'b00: error = 16'd0;
				default: error = 16'd0;
			endcase
	end	
	
	//Compute Ki/s integral
	always_ff@(posedge clk or negedge rst_n)begin				
		if(!rst_n)begin
			phase_accumulator <= 32'd0;
		end else if(scan_en)begin							//scan chain operation when scan_en is asserted
			phase_accumulator[0] <= scan_in;
			for(i = 1; i < 32; i++)begin
				phase_accumulator[i] <= phase_accumulator[i-1];
			end
		end else begin
			phase_accumulator <= phase_accumulator + Ki * error;
		end
	end
	
	//Compute Kp+Ki/s
	assign filtered_control_signal = phase_accumulator + Kp * error;
	
	assign scan_out = phase_accumulator[31];
endmodule


