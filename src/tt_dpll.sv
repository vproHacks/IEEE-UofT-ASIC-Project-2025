module tt_dpll (
	input logic  i_clk, // Reference clock (10MHz)
	input logic  i_rst_n,   // Active-low reset
	output logic o_clk, // PLL output clock (100MHz)
	output logic o_locked,  // Lock indicator
	output logic o_up,
	output logic o_down,

  // Scan chain
	input logic i_scan_en,
	input logic i_scan_in,
	output logic o_scan_out
);

	// Internal wiring
	logic clk_fb;
	logic signed [15:0] control;

	logic scan_chain_pfd_to_lpf, scan_chain_lpf_to_divide_by_n, scan_chain_divide_by_n_to_lock_indicator;	//continuous scan chain

	// Phase Frequency Detector
	tt_pfd pfd (
		.i_clk(o_clk),
		.i_rst_n(i_rst_n),
		.i_clk_ref(i_clk_ref),
		.i_clk_fb(clk_fb),
		.o_up(up),
		.o_down(down),

    // Scan chain
		.scan_en(i_scan_en),
		.scan_in(i_scan_in),
		.scan_out(scan_chain_pfd_to_lpf)
	);

	// Low Pass Filter
	tt_lpf lpf (
		.clk(o_clk),
		.i_rst_n(i_rst_n),
		.up(up),
		.down(down),
		.filtered_control_signal(control),

    // Scan chain
		.i_scan_en(i_scan_en),
		.i_scan_in(scan_chain_pfd_to_lpf),
		.o_scan_out(scan_chain_lpf_to_divide_by_n)
	);

	// N-Divide for Feedback Clock
	  tt_divide_by_n divide_by_n (
		.i_clk(o_clk),
		.i_rst_n(i_rst_n),
		.o_clk(clk_fb),

    // Scan chain
		.i_scan_en(i_scan_en),
		.i_scan_in(scan_chain_lpf_to_divide_by_n),
		.o_scan_out(scan_chain_divide_by_n_to_lock_indicator)
	);

	// Lock indicator
	always_ff @(posedge o_clk, negedge i_rst_n) begin
		if (!i_rst_n) begin
			o_locked <= 1'b0;
		end else if (i_scan_en)begin
			o_locked <= scan_chain_divide_by_n_to_lock_indicator;
		end else if (!up && !down) begin
			o_locked <= 1'b1;
		end else begin
			o_locked <= 1'b0;
		end
	end

  // Scan chain
	assign scan_out = o_locked;

endmodule
