module tt_pfd ( // Phase frequency detector
	input logic i_clk,
	input logic i_rst_n,
	input logic i_clk_ref,
	input logic i_clk_fb,
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
	logic clk_fb_ff1;
	logic clk_fb_ff2;

	logic ref_edge; // Reference signal rising edge
	logic fb_edge;  // Feedback signal rising edge

	// Capture rising edge of either signal
	always_ff @(posedge i_clk, negedge i_rst_n)begin
		if (!i_rst_n) begin
			clk_ref_ff1 <= 1'b0;
			clk_ref_ff2 <= 1'b0;
			clk_fb_ff1 <= 1'b0;
			clk_fb_ff2 <= 1'b0;
		end else if (i_scan_en) begin // Scan chain operation when i_scan_en is asserted
			clk_ref_ff1 <= i_scan_in;
			clk_ref_ff2 <= clk_ref_ff1;
			clk_fb_ff1 <= clk_ref_ff2;
			clk_fb_ff2 <= clk_fb_ff1;
		end else begin
			clk_ref_ff1 <= i_clk_ref;
			clk_ref_ff2 <= clk_ref_ff1;
			clk_fb_ff1 <= clk_fb;
			clk_fb_ff2 <= clk_fb_ff1;
		end
	end

	assign ref_edge = !clk_ref_ff2 && clk_ref_ff1;
	assign fb_edge  = !clk_fb_ff2  && clk_fb_ff1;

	assign o_scan_out = clk_fb_ff2;

	always_comb begin
		if (!i_rst_n) begin
			o_up <= 1'b0;
			o_down <= 1'b0;
		end else if (ref_edge && !fb_edge) begin
			o_up <= 1'b1;
			o_down <= 1'b0;
		end else if (fb_edge && !ref_edge) begin
			o_up <= 1'b0;
			o_down <= 1'b1;
		end else begin
			o_up <= 1'b0;
			o_down <= 1'b0;
		end
	end

endmodule
