module PFD(     		//phase frequency detector
	input logic clk,
	input logic rst_n,
	input logic clk_ref,
	input logic clk_fb,
	output logic up,
	output logic down
);
	
	//sychronization flip-flops, avoid metastability
	logic clk_ref_ff1;
	logic clk_ref_ff2;
	logic clk_fb_ff1;
	logic clk_fb_ff2;
	
	logic ref_edge;			//reference signal rising edge
	logic fb_edge; 			//feedback signal rising edge
	
	//capture rising edge of both signals
	always_ff@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			clk_ref_ff1 <= 1'b0;
			clk_ref_ff2 <= 1'b0;
			clk_fb_ff1 <= 1'b0;
			clk_fb_ff2 <= 1'b0;
		end else begin
			clk_ref_ff1 <= clk_ref;
			clk_ref_ff2 <= clk_ref_ff1;
			clk_fb_ff1 <= clk_fb;
			clk_fb_ff2 <= clk_fb_ff1;
		end
	end
	
	assign ref_edge = (~clk_ref_ff2) & clk_ref_ff1;
	assign fb_edge  = (~clk_fb_ff2)  & clk_fb_ff1;
	
	
	//State Parameters
	typedef enum logic [1:0]{
		IDLE = 2'b00,
		UP = 2'b01,
		DOWN = 2'b10
	}state_t;
	
	state_t current_state, next_state;
	
	//State Transition
	always_ff@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			current_state <= IDLE;
		end else begin
			current_state <= next_state;
		end
	end
	
	//State Transition Logic
	always_comb begin
		case(current_state)
				IDLE: begin
					if(ref_edge && !fb_edge)begin
						next_state = UP;
					end else if(fb_edge && !ref_edge)begin
						next_state = DOWN;
					end else begin
						next_state = IDLE;
					end
				end
				UP: begin
					if(fb_edge)begin
						next_state = IDLE;
					end else begin
						next_state = current_state;
					end
				end
				DOWN: begin
					if(ref_edge)begin
						next_state = IDLE;
					end else begin
						next_state = current_state;
					end
				end
				default: begin
					next_state = IDLE;
				end
		endcase
	end
	
	
	//output stage
	always_comb begin
		case(current_state)
				IDLE: begin
					up <= 1'b0;
					down <= 1'b0;
				end
				UP: begin
					up <= 1'b1;
					down <= 1'b0;
				end
				DOWN: begin
					up <= 1'b0;
					down <= 1'b1;
				end
				default:begin
					up <= 1'b0;
					down <= 1'b0;
				end
		endcase
	end
	
	
endmodule
