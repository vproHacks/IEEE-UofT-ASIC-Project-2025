#SDC Timing constraint

#reference clock(10M)
create_clock -name clk_ref -period 100 [get_ports i_clk]

#clock from DCO(100MHz)
create_generated_clock -name clk_gen -source [get_ports i_clk] -multiply_by 10 [get_ports o_clk]

#10MHz feedback clock
create_generated_clock -name clk_fb -source [get_cells DCO_inst/clk_out] -divide_by 10 [get_ports divide_by_n/o_clk]

derive_clock_uncertainty

set_clock_groups -exclusive \
    -group [get_clocks clk_ref] \
    -group [get_clocks clk_fb]
	
set_false_path -from [get_ports i_rst_n]

set_input_delay -clock [get_clocks i_clk] 5 [get_ports i_clk]

set_output_delay -clock [get_clocks o_clk] 2 [get_ports o_clk]
