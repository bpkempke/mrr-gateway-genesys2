
# constraints

########    GOOD   ########
set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports { sys_rst }]; #IO_0_14 Sch=cpu_resetn

# clocks

########    GOOD   ########
set_property -dict  {PACKAGE_PIN  AD12  IOSTANDARD  DIFF_SSTL15} [get_ports sys_clk_p]
set_property -dict  {PACKAGE_PIN  AD11  IOSTANDARD  DIFF_SSTL15} [get_ports sys_clk_n]

# ddr

######## STILL TBD ########
#set_property -dict  {PACKAGE_PIN  AF11  IOSTANDARD SSTL15} [get_ports {ddr3_1_p[0]}]
#set_property -dict  {PACKAGE_PIN  AE8   IOSTANDARD SSTL15} [get_ports {ddr3_1_p[1]}]
#set_property -dict  {PACKAGE_PIN  AE11  IOSTANDARD SSTL15} [get_ports {ddr3_1_n[0]}]
#set_property -dict  {PACKAGE_PIN  AE10  IOSTANDARD SSTL15} [get_ports {ddr3_1_n[1]}]
#set_property -dict  {PACKAGE_PIN  AC10  IOSTANDARD SSTL15} [get_ports {ddr3_1_n[2]}]
#
#set_property slave_banks {32 34} [get_iobanks 33]

# ethernet

########    GOOD   ########
#set_property -dict { PACKAGE_PIN AK16  IOSTANDARD LVCMOS18 } [get_ports { eth_int_b }]; #IO_L1P_T0_32 Sch=eth_intb
set_property -dict { PACKAGE_PIN AF12  IOSTANDARD LVCMOS15 } [get_ports { mdio_mdc }]; #IO_L23P_T3_33 Sch=eth_mdc
set_property -dict { PACKAGE_PIN AG12  IOSTANDARD LVCMOS15 } [get_ports { mdio_mdio }]; #IO_L23N_T3_33 Sch=eth_mdio
set_property -dict { PACKAGE_PIN AH24  IOSTANDARD LVCMOS33 } [get_ports { phy_rst_n }]; #IO_L14N_T2_SRCC_12 Sch=eth_phyrst_n
#set_property -dict { PACKAGE_PIN AK15  IOSTANDARD LVCMOS18 } [get_ports { eth_pme_b }]; #IO_L1N_T0_32 Sch=eth_pmeb
set_property -dict { PACKAGE_PIN AG10  IOSTANDARD LVCMOS15 } [get_ports { rgmii_rxc }]; #IO_L13P_T2_MRCC_33 Sch=eth_rx_clk
set_property -dict { PACKAGE_PIN AH11  IOSTANDARD LVCMOS15 } [get_ports { rgmii_rx_ctl }]; #IO_L18P_T2_33 Sch=eth_rx_ctl
set_property -dict { PACKAGE_PIN AJ14  IOSTANDARD LVCMOS15 } [get_ports { rgmii_rd[0] }]; #IO_L21N_T3_DQS_33 Sch=eth_rx_d[0]
set_property -dict { PACKAGE_PIN AH14  IOSTANDARD LVCMOS15 } [get_ports { rgmii_rd[1] }]; #IO_L21P_T3_DQS_33 Sch=eth_rx_d[1]
set_property -dict { PACKAGE_PIN AK13  IOSTANDARD LVCMOS15 } [get_ports { rgmii_rd[2] }]; #IO_L20N_T3_33 Sch=eth_rx_d[2]
set_property -dict { PACKAGE_PIN AJ13  IOSTANDARD LVCMOS15 } [get_ports { rgmii_rd[3] }]; #IO_L22P_T3_33 Sch=eth_rx_d[3]
set_property -dict { PACKAGE_PIN AE10  IOSTANDARD LVCMOS15 } [get_ports { rgmii_txc }]; #IO_L14P_T2_SRCC_33 Sch=eth_tx_clk
set_property -dict { PACKAGE_PIN AJ12  IOSTANDARD LVCMOS15 } [get_ports { rgmii_td[0] }]; #IO_L22N_T3_33 Sch=eth_tx_d[0]
set_property -dict { PACKAGE_PIN AK11  IOSTANDARD LVCMOS15 } [get_ports { rgmii_td[1] }]; #IO_L17P_T2_33 Sch=eth_tx_d[1]
set_property -dict { PACKAGE_PIN AJ11  IOSTANDARD LVCMOS15 } [get_ports { rgmii_td[2] }]; #IO_L18N_T2_33 Sch=eth_tx_d[2]
set_property -dict { PACKAGE_PIN AK10  IOSTANDARD LVCMOS15 } [get_ports { rgmii_td[3] }]; #IO_L17N_T2_33 Sch=eth_tx_d[3]
set_property -dict { PACKAGE_PIN AK14  IOSTANDARD LVCMOS15 } [get_ports { rgmii_tx_ctl }]; #IO_L20P_T3_33 Sch=eth_tx_en

# uart

set_property -dict { PACKAGE_PIN Y23   IOSTANDARD LVCMOS33 } [get_ports { uart_sout }]; #IO_L1P_T0_12 Sch=uart_rx_out
set_property -dict { PACKAGE_PIN Y20   IOSTANDARD LVCMOS33 } [get_ports { uart_sin }]; #IO_0_12 Sch=uart_tx_in

# fan

set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { fan_pwm }]; #IO_25_14 Sch=fan_pwm

# sw & led

#switches (DIP)
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[0] }]; #IO_0_17 Sch=sw[0]
set_property -dict { PACKAGE_PIN G25   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[1] }]; #IO_25_16 Sch=sw[1]
set_property -dict { PACKAGE_PIN H24   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[2] }]; #IO_L19P_T3_16 Sch=sw[2]
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[3] }]; #IO_L6P_T0_17 Sch=sw[3]

#PB North
set_property -dict { PACKAGE_PIN B19   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[4] }]; #IO_L24N_T3_17 Sch=btnu

#PB East
set_property -dict { PACKAGE_PIN C19   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[5] }]; #IO_L24P_T3_17 Sch=btnr

#PB South
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[6] }]; #IO_0_15 Sch=btnd

#PB West
set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[7] }]; #IO_L6P_T0_15 Sch=btnl

#PB Center
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS25 } [get_ports { gpio_bd[8] }]; #IO_25_17 Sch=btnc

#LED[7:0]
set_property -dict { PACKAGE_PIN T28   IOSTANDARD LVCMOS33 } [get_ports { gpio_bd[9] }]; #IO_L11N_T1_SRCC_14 Sch=led[0]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports { gpio_bd[10] }]; #IO_L19P_T3_A10_D26_14 Sch=led[1]
set_property -dict { PACKAGE_PIN U30   IOSTANDARD LVCMOS33 } [get_ports { gpio_bd[11] }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=led[2]
set_property -dict { PACKAGE_PIN U29   IOSTANDARD LVCMOS33 } [get_ports { gpio_bd[12] }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=led[3]
set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33 } [get_ports { gpio_bd[13] }]; #IO_L19N_T3_A09_D25_VREF_14 Sch=led[4]
set_property -dict { PACKAGE_PIN V26   IOSTANDARD LVCMOS33 } [get_ports { gpio_bd[14] }]; #IO_L16P_T2_CSI_B_14 Sch=led[5]
set_property -dict { PACKAGE_PIN W24   IOSTANDARD LVCMOS33 } [get_ports { gpio_bd[15] }]; #IO_L20N_T3_A07_D23_14 Sch=led[6]
set_property -dict { PACKAGE_PIN W23   IOSTANDARD LVCMOS33 } [get_ports { gpio_bd[16] }]; #IO_L20P_T3_A08_D24_14 Sch=led[7]

# iic

######## STILL TBD ########
#set_property -dict  {PACKAGE_PIN  P23   IOSTANDARD  LVCMOS25} [get_ports iic_rstn]

########    GOOD   ########
set_property -dict { PACKAGE_PIN AE30  IOSTANDARD LVCMOS33 } [get_ports { iic_scl }]; #IO_L16P_T2_13 Sch=sys_scl
set_property -dict { PACKAGE_PIN AF30  IOSTANDARD LVCMOS33 } [get_ports { iic_sda }]; #IO_L16N_T2_13 Sch=sys_sda

#Setting the Configuration Bank Voltage Select
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
