//DUT
module PFD(     		//phase frequency detector
	input logic clk,
	input logic rst_n,
	input logic clk_ref,
	input logic clk_fb,
	input logic scan_en,
	input logic scan_in,
	output logic scan_out,
	output logic up,
	output logic down
);
	
	//sychronization flip-flops, avoid metastability
	//where clk should be at least 2x faster than clk_ref and clk_fb to sample reliably
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
		end else if(scan_en)begin				//scan chain operation when scan_en is asserted
			clk_ref_ff1 <= scan_in;
			clk_ref_ff2 <= clk_ref_ff1;
			clk_fb_ff1 <= clk_ref_ff2;
			clk_fb_ff2 <= clk_fb_ff1;
		end else begin
			clk_ref_ff1 <= clk_ref; //shift registers, store first sample in ff2, second in ff1
			clk_ref_ff2 <= clk_ref_ff1; 
			clk_fb_ff1 <= clk_fb;
			clk_fb_ff2 <= clk_fb_ff1;
		end
	end
	
	//if rising edge, assign 1
	assign ref_edge = (~clk_ref_ff2) & clk_ref_ff1; 
	assign fb_edge  = (~clk_fb_ff2)  & clk_fb_ff1; 
	
	assign scan_out = clk_fb_ff2;
	
	/*
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
	*/
	
	//compare feedback clock to reference clock
	//speed up if feedback clock slower
	//slow down if feedback clock faster
	always_comb begin
		if(!rst_n)begin
			up <= 1'b0;
			down <= 1'b0;
		end else if(ref_edge && !fb_edge)begin //if ref. clock leads feedback
			up <= 1'b1; //speed up
			down <= 1'b0; 
		end else if(fb_edge && !ref_edge)begin //if feedback clock leads ref.
			up <= 1'b0;
			down <= 1'b1; //slow down
		end else begin //ref and feedback clock align perfectly
			up <= 1'b0; 
			down <= 1'b0;
		end
	end
		
		
endmodule

//transaction class
class transaction;

    bit clk;
    bit rst_n; //active low reset
    bit up;
    bit down;
    rand bit clk_ref;
    rand bit clk_fb;

    //print contents of packet to track in log
    function void displayPacket();

        $display("clk = %0b, rst_n = %0b, up = %0b, down = %0b, clk_ref = %0b, clk_fb = %0b", clk, rst_n, up, down, clk_ref, clk_fb);

    endfunction

	//randomize reference and feedback clocks
	constraint clock_constraints {

		clk_ref dist { 0 := 50, 1 := 50};
		clk_fb dist { 0 := 50, 1 := 50};

	}

endclass

//generator
class generator;

    //declare transaction object
    transaction packet;

    //declare mailbox "pointer"
    mailbox #(transaction) mbx; 

	event next; //wait for a signal before generating the next transaction
  	event done; //Signals that the generator has completed generating all transactions

	//generator constructor
    function new(mailbox #(transaction) mbx_in);  
        this.mbx = mbx_in;
    endfunction

	task generate_stimuli;

		repeat(20) begin //create 20 transactions
			
			packet = new(); //create new transaction object
			assert(packet.randomize()) else $display("Randomization Failed!"); //randomize transaction object's variables
      		mbx.put(packet); //place transaction object in mailbox after randomizing
			@(next);

		end

		->done 

	endtask



endclass

//driver
//drives data in transaction to DUT
//gets transaction from mailbox, drives signals into interface
class driver;

    //declare virtual interface
    virtual PFD_INTERFACE vinf;

    //declare transaction object
    transaction packet;

    //declare mailbox "pointer"
    mailbox #(transaction) mbx; 

    //event doneDriving;

    //driver constructor
    function new(mailbox #(transaction) mbx_in);  
        this.mbx = mbx_in;
    endfunction

    //reset task
    task reset;

        vinf.rst_n = 0;
        vinf.up = 0;
        vinf.down = 0;

    endtask

    //drive signals to DUT
    task driveStimuli;

        forever begin

            mbx.get(packet);

            @(posedge vinf.clk); //drive signals every positive edge of clock
            vinf.clk_ref = packet.clk_ref;
			vinf.clk_fb = packet.clk_fb;
			$display("Drive with: clk_ref: %0b, clk_fb: %0b", packet.clk_ref, packet.clk_fb);

			//->doneDriving; //triffered doneDriving event to indicate transaction completion

        end

    endtask

endclass

//monitor

//scoreboard

//environment

//test

//interface
class PFD_INTERFACE;

    logic clk;
	logic rst_n;
	logic clk_fb, clk_ref;
	logic up, down;

endclass

//testbench top
module tb;

    //generate clock

    //instantiate interface

endmodule
