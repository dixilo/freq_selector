# FFT quad
set ip_name "axi_freq_selector"
create_project $ip_name "./ip_test" -force
source ./util.tcl

# file
set proj_fileset [get_filesets sources_1]
add_files -norecurse -scan_for_includes -fileset $proj_fileset [list \
"axi_freq_selector.v" \
"axi_freq_selector_core.v" \
"ring_rand.v" \
]

set_property "top" "axi_freq_selector" $proj_fileset

ipx::package_project -root_dir "./ip_test" -vendor kuhep -library user -taxonomy /kuhep
set_property name $ip_name [ipx::current_core]
set_property vendor_display_name {kuhep} [ipx::current_core]


# Block memory for the first frequency selector
create_ip -vlnv [latest_ip blk_mem_gen] -module_name bram_ring
set_property CONFIG.Memory_Type "Simple_Dual_Port_RAM" [get_ips bram_ring]
set_property CONFIG.Assume_Synchronous_Clk "true" [get_ips bram_ring]
set_property CONFIG.Write_Width_A 14 [get_ips bram_ring]
set_property CONFIG.Write_Depth_A 128 [get_ips bram_ring]
set_property CONFIG.Read_Width_A 14 [get_ips bram_ring]
set_property CONFIG.Operating_Mode_A "READ_FIRST" [get_ips bram_ring]
#set_property CONFIG.Port_B_Clock 250 [get_ips bram_ring]
#set_property CONFIG.Port_B_Enable_Rate 250 [get_ips bram_ring]

# file groups
ipx::add_file ./axi_freq_selector.srcs/sources_1/ip/bram_ring/bram_ring.xci \
[ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]

ipx::reorder_files -before ../axi_freq_selector_core.v \
./axi_freq_selector.srcs/sources_1/ip/bram_ring/bram_ring.xci \
[ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]

# Interface
ipx::infer_bus_interface dev_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::save_core [ipx::current_core]
