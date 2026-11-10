# Run: vivado -mode batch -source create_project.tcl
set here [file dirname [file normalize [info script]]]
create_project ov7670_edge_detector [file join $here vivado_project] -part xc7a35tcpg236-1 -force
set_property target_language VHDL [current_project]
foreach f [glob [file join $here rtl *.vhd]] {add_files $f}
foreach f [get_files -of_objects [get_filesets sources_1]] {set_property file_type {VHDL 2008} $f}
add_files -fileset sim_1 [file join $here sim tb_sobel_stream.vhd]
set_property file_type {VHDL 2008} [get_files [file join $here sim tb_sobel_stream.vhd]]
set_property top tb_sobel_stream [get_filesets sim_1]
add_files -fileset constrs_1 [file join $here constraints edge_detector.xdc]
set_property top edge_detector_top [get_filesets sources_1]
update_compile_order -fileset sources_1
puts "Project created. First synthesize, then inspect timing and camera voltages."
