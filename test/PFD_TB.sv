//Phase Frequency Detector TB
//By Joonseo Park

/*
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
*/


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

    //declare transaction object variable
    transaction packet;

    //declare mailbox "pointer"
    mailbox #(transaction) mbx; 

	event next; //wait for a signal before generating the next transaction
  	event done; //Signals that the generator has completed generating all transactions

	//generator constructor; take in a mailbox and bind object's mailbox "pointer" to input mbx
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
    virtual PFD_INTERFACE.TB vinf;

    //declare transaction object variable
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
		repeat(2) @(posedge vinf.clk); //wait two clock cycles
		vinf.rst_n = 1;

    endtask

    //drive signals to DUTa
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
//use virtual interface handle to monitor signal changes in interfaces
//captures information & initializes a packet to send to scoreboard
class monitor;

	//declare virtual interface
    virtual PFD_INTERFACE.DUT vinf;

    //declare transaction object variable
	transaction packet;

	//declare mailbox "pointer"
    mailbox #(transaction) mbx; 

	//monitor constructor
    function new(mailbox #(transaction) mbx_in);  
        this.mbx = mbx_in;
    endfunction

	task sample_interface();

		forever begin

			@(posedge vinf.clk);
			packet = new(); //create new transaction object
			packet.rst_n = vinf.rst_n;
			packet.up = vinf.up;
			packet.down = vinf.down;
			mbx.put(packet);
			$display("transaction object: up = %0b, down = %0b", packet.up, packet.down);

		end

	endtask

endclass

//scoreboard
//receive transaction sampled/initialized by monitor
//has reference model behaving the same way as DUT
//compare output of DUT to reference model
class scoreboard;

	bit fb_clk = 0;
	bit fb_clk2 = 0;
	bit ref_clk = 0;
	bit ref_clk2 = 0;
	bit ref_hasedge, fb_hasedge;
	bit initialized = 0;
	bit expected_up, expected_down;
	int error_count = 0;

    //declare transaction object variable
	transaction packet;

	//declare mailbox "pointer"
    mailbox #(transaction) mbx; 

	//indicates to generator that next transaction can be started
	event next;

	//scoreboard constructor
    function new(mailbox #(transaction) mbx_in);  
        this.mbx = mbx_in;
    endfunction

	task compare_golden_output;

		forever begin

			mbx.get(packet); //wait until new transaction available at mailbox then fetch
			$display("DUT outputs: up --> %0b, down --> %0b", packet.up, packet.down);

			//shift in the clock data from transactions
			fb_clk2 = fb_clk;
			fb_clk = packet.clk_fb;
			ref_clk2 = ref_clk;
			ref_clk = packet.clk_ref;

			//start checking when we have previous and current clock initialized (wait one clock cycle)
			if (!initialized) initialized = 1;

			else begin

				//determine if feedback/ref. clock has + edge
				//remember we cannot use continuous assignment inside procedural (alwyas/init) blocks
				ref_hasedge = (~ref_clk2) & ref_clk; 
				fb_hasedge  = (~fb_clk2)  & fb_clk; 

				//reference model:
				//NOTE: replace with expected output variable
				if(!packet.rst_n)begin
					expected_up = 1'b0;
					expected_down = 1'b0;
				end else if(ref_hasedge && !fb_hasedge)begin //if ref. clock leads feedback
					expected_up = 1'b1; //speed up
					expected_down = 1'b0; 
				end else if(fb_hasedge && !ref_hasedge)begin //if feedback clock leads ref.
					expected_up = 1'b0;
					expected_down <= 1'b1; //slow down
				end else begin //ref and feedback clock align perfectly
					expected_up = 1'b0; 
					expected_down = 1'b0;
				end

				$display("our up counter = %0b, our down counter = %0b", expected_up, expected_down);

				//the checker
				//make this into a function in the future
				if (packet.up == expected_up && packet.down == expected_down) $display("TEST PASSED");

				else begin
					$display("TEST FAILED! Expected output: up counter = %0b, down counter = %0b VS Current output: up counter = %0b, down counter = %0b", packet.up, packet.down, expected_up, expected_down);
					error_count++;
				end

			end

			->next; //trigger next event for generator to create more transactions

		end

	endtask

endclass

//environment
//declare test bench components
class env;

	generator g;
	driver d;
	scoreboard s;
	monitor m;

	//declare mailboxes for generator->driver and monitor->scoreboard
	mailbox #(transaction) generation;
	mailbox #(transaction) verification;
	virtual PFD_INTERFACE.TB vinf_TB;
	virtual PFD_INTERFACE.DUT vinf_DUT;


	function new(virtual PFD_INTERFACE interfaceIn);
		//pass corresponding mailbox to components
		g = new(generation);
		d = new(generation);
		s = new(verification);
		m = new(verification);

		//bind interface pointers to input interface 
		//consider interface modport from DUT and TB perspectives
		this.vinf_TB = interfaceIn.TB;
		this.vinf_DUT = interfaceIn.DUT;
		//bind virtual interface to driver and monitor
		d.vinf = vinf_TB;
		m.vinf = vinf_DUT;

		g.next = next;
		d.next = next;
	endfunction

	task start();

		fork
			g.generate_stimuli();
			d.driveStimuli();
			m.sample_interface();
			s.compare_golden_output();
		join_any

	endtask

	task main();

		d.reset(); //reset DUT using driver
		start(); //activate TB components
		wait(g.done.triggered); //wait until generator completes generation of packets
		if (s.error_count == 0) $display("ALL TESTS PASSED");
		else if (s.error_count > 0) $display("%0d tests failed!", s.error_count);

	endtask

endclass

//interface
interface PFD_INTERFACE;

    logic clk;
	logic rst_n;
	logic clk_fb, clk_ref;
	logic up, down;

	modport TB (output clk, rst_n, clk_fb, clk_ref, input up, down);

	modport DUT (output up, down, input clk, rst_n, clk_fb, clk_ref);

endinterface

//testbench top
module tb;

	//declare testbench components
	env e;

    //instantiate interface
	PFD_INTERFACE inf();

	//initialize clock
	initial begin
		inf.clk = 0;
	end

    //generate clock
	always #10 inf.clk = ~inf.clk; //generate 50Mhz clock

	//instantiate DUT
	PFD u0 (
		.clk(inf.clk), .rst_n(inf.rst_n), .clk_ref(inf.clk_ref), .clk_fb(inf.clk_fb), .up(inf.up), .down(inf.down)
	);

	/*
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
);*/

	initial begin
		e = new(inf);
		e.main();
	end

endmodule
