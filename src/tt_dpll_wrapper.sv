`default_nettype none

module tt_dpll_wrapper (
  input logic i_clk_ref, // Reference clock
  input logic i_rst_n,   // Active-low reset

  input  logic [7:0] i_ui_in,  // Dedicated inputs
  output logic [7:0] o_uo_out, // Dedicated outputs
  inout  logic [7:0] inout_uio // IOs
);

  tt_dpll dpll (
    .i_clk_ref(i_clk_ref),
    .i_rst_n(i_rst_n),
    .o_clk_gen(o_uo_out[0]),
    .o_locked (o_uo_out[1]),
    .o_up     (o_uo_out[2]),
    .o_down   (o_uo_out[3]),

    .o_clk_div(o_uo_out[5]),

    // Scan chain
    .i_scan_en_top(ui_in[0]),
	  .i_scan_in_top(ui_in[1]),
    .o_scan_out_top(uo_out[4])
  );

  // Tie unused outputs to zerp
  assign o_uo_out[6:7] = 2'b0;
  assign inout_uio = 8'b0;

endmodule
