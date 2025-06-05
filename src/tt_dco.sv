// Self-oscillating Ring Oscillator
// No need for external clock signal
// Use inverter chain loop
// Only for ASIC implementation, not synthesizable

module tt_dco (
  input logic               i_enable,
  input logic signed [15:0] i_control, // PI controller output
  output logic              o_clk_gen
);
  localparam NUM_INV_STAGES = 5;
  logic [NUM_INV_STAGES-1:0] stages;

  assign stages[0] = i_enable;
  
  generate
    for (genvar i = 0; i < NUM_INV_STAGES - 1; i++) begin : gen_inverter_stage
      assign #((i_control + 16'h8000) >> 16'd10)
        stages[i+1] = !stages[i]; // Adjusting delay here
    end
  endgenerate

  assign o_clk_gen = stages[NUM_INV_STAGES-1];

endmodule
