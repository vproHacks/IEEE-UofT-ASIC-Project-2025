module tt_lpf (
  // Use PI controller for first order filter transfer function
  localparam int KP = 7, // Proportional gain
  localparam int KI = 4  // Integral gain
) ( // Low-pass filter
	input logic                i_clk_gen,
	input logic                i_rst_n,
	input logic                i_up,
	input logic                i_down,
	output logic signed [15:0] o_filtered_control_signal,

  // Scan chain
	input logic  i_scan_en,
	input logic  i_scan_in,
	output logic o_scan_out
);

	logic signed [15:0] error;
	logic signed [31:0] phase_accumulator;

	// Phase error decoding
	always_comb begin
    error = 16'b0;
		if (!i_rst_n) begin
			error = 16'b0;
    end else begin
			case ({i_up, i_down})
				2'b00: error = 16'b0;
				2'b01: error = 16'b1;
				2'b10: error = -16'b1;
				default: error = 16'b0;
			endcase
    end
	end

	// Compute Ki/s integral
	always_ff @(posedge i_clk_gen, negedge i_rst_n)begin
		if (!i_rst_n) begin
			phase_accumulator <= 32'd0;
		end else if (i_scan_en) begin //scan chain operation when scan_en is asserted
			phase_accumulator[0] <= i_scan_in;
			for (int i = 1; i < 32; i++) begin
				phase_accumulator[i] <= phase_accumulator[i-1];
			end
		end else begin
			phase_accumulator <= phase_accumulator + KI * error;
		end
	end

	// Compute Kp + Ki/s
	assign o_filtered_control_signal = phase_accumulator + KP * error;

	assign o_scan_out = phase_accumulator[31];

endmodule
