# operating conditions and boundary conditions #

current_design LCD_CTRL

set cycle 100;		#clock period defined by designer
set t_in  50;		#input delay defined by designer
set t_out 1;		#output delay defined by designer

create_clock -period $cycle [get_ports clk]
set_dont_touch_network [get_clocks clk]
set_clock_uncertainty -setup 0.1 [get_clocks clk]
set_clock_latency 0.5 [get_clocks clk]

set_input_delay  $t_in  -clock clk [all_inputs]
set_output_delay $t_out -clock clk [all_outputs]
 
set_load -pin_load 1 [all_outputs]    
set_drive 1          [all_inputs]
                       
set_operating_conditions -min_library fast -min fast  -max_library slow -max slow
set_wire_load_model -name tsmc13_wl10 -library slow 
                        

