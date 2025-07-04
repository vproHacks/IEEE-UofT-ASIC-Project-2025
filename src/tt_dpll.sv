module tt_dpll (
	input logic  i_clk_ref, // Reference clock (10MHz)
	input logic  i_rst_n,   // Active-low reset
	output logic o_clk_gen, // Generated clock (100MHz)
	output logic o_locked,  // Lock indicator
	output logic o_up,
	output logic o_down,

  output logic o_clk_div, // Divided clock (10MHz). For debug purposes only.

  // Scan chain
	input logic i_scan_en,
	input logic i_scan_in,
	output logic o_scan_out
);

	// Internal wiring
	logic signed [31:0] control;

  // Scan chain
	logic scan_chain_pfd_to_lpf;
  logic scan_chain_lpf_to_divide_by_n;
  logic scan_chain_divide_by_n_to_lock_indicator;

		/* Altera PLL IP for 100MHz
 	in case of actual asic implementation, replace it with DCO cell
  
	DCO_0002 u1(
		.refclk(i_clk_ref),
		.rst(!i_rst_n),
		.outclk_0(o_clk_gen),
		.locked(o_locked)
	);
 
 	This is only for FPGA validation!
 	*/

	tt_dco dco (
		.i_enable(1'b1),
  		.i_control(control),
  		.o_clk_gen(o_clk_gen)
	);

	// Phase Frequency Detector
	tt_pfd pfd (
		.i_clk_gen(o_clk_gen),
		.i_rst_n(i_rst_n),
		.i_clk_ref(i_clk_ref),
		.i_clk_div(o_clk_div),
		.o_up(o_up),
		.o_down(o_down),

    // Scan chain
		.i_scan_en(i_scan_en),
		.i_scan_in(i_scan_in),
		.o_scan_out(scan_chain_pfd_to_lpf)
	);

	// Low Pass Filter
	tt_lpf lpf (
		.i_clk_gen(o_clk_gen),
		.i_rst_n(i_rst_n),
		.i_up(o_up),
		.i_down(o_down),
		.o_filtered_control_signal(control), // Todo: What is this used for?

    // Scan chain
		.i_scan_en(i_scan_en),
		.i_scan_in(scan_chain_pfd_to_lpf),
		.o_scan_out(scan_chain_lpf_to_divide_by_n)
	);

	// N-Divide for Feedback Clock
  tt_divide_by_3 divide_by_3 (
		.i_clk_gen(o_clk_gen),
		.i_rst_n(i_rst_n),
		.o_clk_div(o_clk_div),

    // Scan chain
		.i_scan_en(i_scan_en),
		.i_scan_in(scan_chain_lpf_to_divide_by_n),
		.o_scan_out(scan_chain_divide_by_n_to_lock_indicator)
	);

	// Lock indicator
	always_ff @(posedge o_clk_gen, negedge i_rst_n) begin
		if (!i_rst_n) begin
			o_locked <= 1'b0;
		end else if (i_scan_en)begin
			o_locked <= scan_chain_divide_by_n_to_lock_indicator;
		end else if (!o_up && !o_down) begin
			o_locked <= 1'b1;
		end else begin
			o_locked <= 1'b0;
		end
	end

  // Scan chain
	assign o_scan_out = o_locked;

endmodule
