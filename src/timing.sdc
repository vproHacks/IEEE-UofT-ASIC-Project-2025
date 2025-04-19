#SDC Timing constraint

#reference clock(10M)
create_clock -name clk_ref -period 100 [get_ports {clk_ref}]

#clock from DCO(100MHz)
create_generated_clock -name pll_out -source [get_ports clk_ref] -multiply_by 10 [get_cells DCO_inst/clk_out]

#10MHz feedback clock
create_generated_clock -name clk_fb -source [get_cells DCO_inst/clk_out] -divide_by 10 [get_pins u4/clk_fb]

derive_clock_uncertainty

set_clock_groups -exclusive \
    -group [get_clocks clk_ref] \
    -group [get_clocks clk_fb]
	
set_false_path -from [get_ports rst_n]

set_input_delay -clock [get_clocks clk_ref] 5 [get_ports clk_ref]

set_output_delay -clock [get_clocks pll_out] 2 [get_ports pll_out]