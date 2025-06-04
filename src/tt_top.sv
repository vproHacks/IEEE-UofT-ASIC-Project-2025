`default_nettype none

// The module name should start with tt_um_
// And we need to keep the module port definitions same as TinyTapeout top module template
module tt_um_dpll (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset - active-low reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[7:6]  = 2'b0;
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;


  tt_dpll dpll (
    .i_clk_ref(clk),
    .i_rst_n(rst_n),
    .o_clk_gen(uo_out[0]),
    .o_locked (uo_out[1]),
    .o_up     (uo_out[2]),
    .o_down   (uo_out[3]),

    .o_clk_div(uo_out[5]),

    // Scan chain
    .i_scan_en_top(ui_in[0]),
	  .i_scan_in_top(ui_in[1]),
    .o_scan_out_top(uo_out[4])
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:2], uio_in, 1'b0};

endmodule
