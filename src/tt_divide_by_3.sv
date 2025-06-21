module tt_divide_by_3 (
  input logic i_clk_gen,  // 30MHz
  input logic i_rst_n,
  output logic o_clk_div, // 10MHz feedback clock with 50% duty cycle

  // Scan chain
  input logic i_scan_en,
  input logic i_scan_in,
  output logic o_scan_out
);

  logic [1:0] cnt_pos, cnt_neg;

  logic scan_chain_connection; // Continuous scan chain

  always_ff @(posedge i_clk_gen, negedge i_rst_n) begin
    if (!i_rst_n) begin
      cnt_pos <= 2'b0;
	  end else if (i_scan_en) begin
      cnt_pos[0] <= i_scan_in;
      cnt_pos[1] <= cnt_pos[0];
	  end else if (cnt_pos == 2'b10) begin
      cnt_pos <= 2'b0;
    end else begin
      cnt_pos <= cnt_pos + 2'b1;
    end
  end

  always_ff @(negedge i_clk_gen, negedge i_rst_n) begin
    if (!i_rst_n) begin
      cnt_neg <= 2'b0;
    end else if (i_scan_en) begin
      cnt_neg[0] <= scan_chain_connection;
      cnt_neg[1] <= cnt_neg[0];
    end else if (cnt_neg == 2'b10) begin
      cnt_neg <= 2'b0;
    end else begin
      cnt_neg <= cnt_neg + 2'b1;
    end
  end

  assign o_clk_div = cnt_pos == 2'b0 || cnt_neg == 2'b0;

  // Scan chain
  assign scan_chain_connection = cnt_pos[1];
  assign o_scan_out = cnt_neg[1];

endmodule
