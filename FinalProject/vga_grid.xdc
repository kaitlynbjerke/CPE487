## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Reset
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports {reset_n}];

## VGA Connector
set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { vga_r[0] }];
set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVCMOS33 } [get_ports { vga_r[1] }];
set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { vga_r[2] }];
set_property -dict { PACKAGE_PIN C6    IOSTANDARD LVCMOS33 } [get_ports { vga_g[0] }];
set_property -dict { PACKAGE_PIN A5    IOSTANDARD LVCMOS33 } [get_ports { vga_g[1] }];
set_property -dict { PACKAGE_PIN B6    IOSTANDARD LVCMOS33 } [get_ports { vga_g[2] }];
set_property -dict { PACKAGE_PIN B7    IOSTANDARD LVCMOS33 } [get_ports { vga_b[0] }];
set_property -dict { PACKAGE_PIN C7    IOSTANDARD LVCMOS33 } [get_ports { vga_b[1] }];
set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { vga_b[2] }];
set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { vga_hsync }];
set_property -dict { PACKAGE_PIN B12   IOSTANDARD LVCMOS33 } [get_ports { vga_vsync }];

## Buttons
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { btnc }]; # Center button (place plant)
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { btnu }]; # Up
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { btnl }]; # Left
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { btnr }]; # Right
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { btnd }]; # Down

## Switches (for edit mode)
#set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { sw_edit }]; # SW0 - Edit mode toggle

## Added this to fix timing violation (design was running too fast for FPGA to keep up)
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]

# Relax timing on non-critical paths
set_max_delay -from [get_pins -hierarchical -filter {NAME =~ *count_reg*/C}] 20.0
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { hard }]; #IO_L13N_T2_MRCC_14 Sch=sw[3]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { pass }]; #IO_L13N_T2_MRCC_14 Sch=sw[3]
