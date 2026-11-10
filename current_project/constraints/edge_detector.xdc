## 12 MHz Clock Signal
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { clk12 }]; #IO_L12P_T1_MRCC_14 Sch=gclk
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {clk12}];

## VGA Pmod wiring from course lab_f.xdc (2-bit RGB)
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { vga_r[0] }]; #IO_L5N_T0_D07_14 Sch=ja[1]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { vga_r[1] }]; #IO_L5P_T0_D06_14 Sch=ja[7]
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports { vga_g[0] }]; #IO_L4N_T0_D05_14 Sch=ja[2]
set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports { vga_g[1] }]; #IO_L4P_T0_D04_14 Sch=ja[8]
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { vga_b[0] }]; #IO_L9P_T1_DQS_14 Sch=ja[3]
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports { vga_b[1] }]; #IO_L6N_T0_D08_VREF_14 Sch=ja[9]
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { vga_hsync }]; #IO_L8N_T1_D12_14 Sch=ja[10]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { vga_vsync }]; #IO_L8P_T1_D11_14 Sch=ja[4]


# User camera GPIO pins (unchanged).
# OV7670, DIP GPIO numbers are printed as pio[01] etc. on Cmod board.
set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports {cam_data[0]}]  ;# DIP 1
set_property -dict {PACKAGE_PIN L3 IOSTANDARD LVCMOS33} [get_ports {cam_data[1]}]  ;# DIP 2
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {cam_data[2]}] ;# DIP 3
set_property -dict {PACKAGE_PIN K3 IOSTANDARD LVCMOS33} [get_ports {cam_data[3]}]  ;# DIP 4
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {cam_data[4]}] ;# DIP 5
set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS33} [get_ports {cam_data[5]}]  ;# DIP 6
set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS33} [get_ports {cam_data[6]}] ;# DIP 7
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports {cam_data[7]}] ;# DIP 8
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports cam_href]    ;# DIP 9
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports cam_vsync]   ;# DIP 10
set_property -dict {PACKAGE_PIN N3 IOSTANDARD LVCMOS33} [get_ports cam_pclk]    ;# DIP 18 (clock capable)
set_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports cam_xclk]    ;# DIP 19
set_property -dict {PACKAGE_PIN M2 IOSTANDARD LVCMOS33} [get_ports cam_sioc]    ;# DIP 20
set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVCMOS33} [get_ports cam_siod]    ;# DIP 21
# Note: camera PCLK is asynchronous to VGA clock. Timing/CDC constraints must
# be reviewed after implementation. Do not blanket false-path the whole design.


# Test button and status LEDs
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports btn_test]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports led_ready]
set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVCMOS33} [get_ports led_frame]

set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports uart_txd]

create_clock -name cam_pclk -period 40.0 [get_ports cam_pclk]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks sys_clk_pin] -group [get_clocks cam_pclk]

# SCCB open-drain lines must have pullups to a voltage compatible with sensor I/O.
# FPGA internal pullups target its VCCO (3.3V here); DO NOT enable internal
# pullups unless the breakout is verified 3.3V tolerant on SCCB pins.
# set_property PULLUP true [get_ports cam_sioc]
# set_property PULLUP true [get_ports cam_siod]
