module tt_pfd ( // Phase frequency detector
	input logic i_clk_gen,
	input logic i_rst_n,
	input logic i_clk_ref,
	input logic i_clk_div,
	output logic o_up,
	output logic o_down,

  // Scan chain
	input logic i_scan_en,
	input logic i_scan_in,
	output logic o_scan_out
);

	// Sychronization flip-flops for avoiding metastability.
	logic clk_ref_ff1;
	logic clk_ref_ff2;
	logic clk_div_ff1;
	logic clk_div_ff2;

	logic clk_ref_edge; // Reference signal rising edge
	logic clk_div_edge;  // Feedback signal rising edge

	// Capture rising edge of either signal
	always_ff @(posedge i_clk_gen, negedge i_rst_n)begin
		if (!i_rst_n) begin
			clk_ref_ff1 <= 1'b0;
			clk_ref_ff2 <= 1'b0;
			clk_div_ff1 <= 1'b0;
			clk_div_ff2 <= 1'b0;
		end else if (i_scan_en) begin // Scan chain operation when i_scan_en is asserted
			clk_ref_ff1 <= i_scan_in;
			clk_ref_ff2 <= clk_ref_ff1;
			clk_div_ff1 <= clk_ref_ff2;
			clk_div_ff2 <= clk_div_ff1;
		end else begin
			clk_ref_ff1 <= i_clk_ref;
			clk_ref_ff2 <= clk_ref_ff1;
			clk_div_ff1 <= i_clk_div;
			clk_div_ff2 <= clk_div_ff1;
		end
	end

	assign clk_ref_edge = !clk_ref_ff2 && clk_ref_ff1;
	assign clk_div_edge = !clk_div_ff2 && clk_div_ff1;

	assign o_scan_out = clk_div_ff2;

	always_comb begin
		if (!i_rst_n) begin
			o_up = 1'b0;
			o_down = 1'b0;
		end else if (clk_ref_edge && !clk_div_edge) begin
			o_up = 1'b1;
			o_down = 1'b0;
		end else if (clk_div_edge && !clk_ref_edge) begin
			o_up = 1'b0;
			o_down = 1'b1;
		end else begin
			o_up = 1'b0;
			o_down = 1'b0;
		end
	end

endmodule
