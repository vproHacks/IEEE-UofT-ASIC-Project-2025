# SDC Timing Constraints

# Reference clock (10MHz)
create_clock -name clk_ref -period 100 [get_ports i_clk_ref]

# Genereated clock (100MHz)
create_generated_clock -name clk_gen -source [get_ports i_clk_ref] -multiply_by 10 [get_ports o_uo_out[0]]

# Divided clock (10MHz)
create_generated_clock -name clk_div -source [get_ports o_clk_gen] -divide_by 10 [get_ports o_uo_out[5]]

derive_clock_uncertainty

set_clock_groups -exclusive \
    -group [get_clocks clk_ref] \
    -group [get_clocks clk_div]
	
set_false_path -from [get_ports i_rst_n]

set_input_delay -clock [get_clocks clk_ref] 5 [get_ports i_clk_ref]

set_output_delay -clock [get_clocks clk_gen] 2 [get_ports o_clk_gen]
