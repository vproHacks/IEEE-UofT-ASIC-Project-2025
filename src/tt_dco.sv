// Self-oscillating Ring Oscillator
// No need for external clock signal
// Use inverter chain loop
// Only for ASIC implementation, not synthesizable

module tt_dco(
  input logic               i_enable,
  input logic signed [15:0] i_control, // PI controller output
  output logic              o_clk
);

  logic [4:0] stages;

  assign stages[0] = i_enable;

  generate // Use 5 inverter stages
    for (int i = 0; i < 4; i++) begin : gen_inverter_stage
      assign #((i_control + 16'h8000) >> 16'd10)
        stages[i+1] = !stages[i]; // Adjusting delay here
    end
  endgenerate

  assign o_clk = stages[4];

endmodule
