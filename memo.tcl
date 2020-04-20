
# Block memory for data
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_data -dir c:/Users/kucmb/jsuzuki/fpga_projects/freq_selector/data_transfer_test/data_transfer_test.srcs/sources_1/ip
set_property -dict [list CONFIG.Component_Name {blk_mem_data} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {64} CONFIG.Write_Depth_A {4096} CONFIG.Read_Width_A {64} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {64} CONFIG.Read_Width_B {64} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_data]
set_property -dict [list CONFIG.Operating_Mode_A {READ_FIRST}] [get_ips blk_mem_data]

# Block memory for counter
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_counter -dir c:/Users/kucmb/jsuzuki/fpga_projects/freq_selector/data_transfer_test/data_transfer_test.srcs/sources_1/ip
set_property -dict [list CONFIG.Component_Name {blk_mem_counter} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {5} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {5} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {5} CONFIG.Read_Width_B {5} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_counter]
set_property -dict [list CONFIG.Operating_Mode_A {READ_FIRST}] [get_ips blk_mem_counter]

# FIFO for assert
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_assert -dir c:/Users/kucmb/jsuzuki/fpga_projects/freq_selector/data_transfer_test/data_transfer_test.srcs/sources_1/ip
set_property -dict [list CONFIG.Component_Name {fifo_assert} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {8} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {8} CONFIG.Output_Depth {512} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {511} CONFIG.Full_Threshold_Negate_Value {510} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips fifo_assert]

# FIFO for fft_second
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_second_index -dir c:/Users/kucmb/jsuzuki/fpga_projects/freq_selector/second_fft_test/second_fft_test.srcs/sources_1/ip
set_property -dict [list CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {4} CONFIG.Input_Depth {512} CONFIG.Output_Data_Width {4} CONFIG.Output_Depth {512} CONFIG.Data_Count_Width {9} CONFIG.Write_Data_Count_Width {9} CONFIG.Read_Data_Count_Width {9} CONFIG.Full_Threshold_Assert_Value {511} CONFIG.Full_Threshold_Negate_Value {510} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips fifo_second_index]

# Block memory for ring rand second
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name bram_ring_second -dir c:/Users/kucmb/jsuzuki/fpga_projects/freq_selector/second_fft_test/second_fft_test.srcs/sources_1/ip
set_property -dict [list CONFIG.Component_Name {bram_ring_second} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {4} CONFIG.Write_Depth_A {128} CONFIG.Read_Width_A {4} CONFIG.Operating_Mode_A {READ_FIRST} CONFIG.Write_Width_B {4} CONFIG.Read_Width_B {4} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips bram_ring_second]
