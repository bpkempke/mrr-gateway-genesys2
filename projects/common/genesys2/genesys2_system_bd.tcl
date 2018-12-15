
# create board design
# interface ports

create_bd_port -dir I -type rst sys_rst
create_bd_port -dir I sys_clk_p
create_bd_port -dir I sys_clk_n

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr3

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 mdio
#create_bd_intf_port -mode Master -vlnv xilinx.com:interface:rgmii_rtl:1.0 rgmii

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main

create_bd_port -dir I uart_sin
create_bd_port -dir O uart_sout

#TODO: Put back in
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 qspi_flash

create_bd_port -dir O -type rst phy_rst_n

create_bd_port -dir O -from 7 -to 0 spi_csn_o
create_bd_port -dir I -from 7 -to 0 spi_csn_i
create_bd_port -dir I spi_clk_i
create_bd_port -dir O spi_clk_o
create_bd_port -dir I spi_sdo_i
create_bd_port -dir O spi_sdo_o
create_bd_port -dir I spi_sdi_i

create_bd_port -dir I -from 31 -to 0 gpio0_i
create_bd_port -dir O -from 31 -to 0 gpio0_o
create_bd_port -dir O -from 31 -to 0 gpio0_t
create_bd_port -dir I -from 31 -to 0 gpio1_i
create_bd_port -dir O -from 31 -to 0 gpio1_o
create_bd_port -dir O -from 31 -to 0 gpio1_t

# io settings

set_property -dict [list CONFIG.POLARITY {ACTIVE_HIGH}] [get_bd_ports sys_rst]

# instance: microblaze - processor

ad_ip_instance microblaze sys_mb
ad_ip_parameter sys_mb CONFIG.G_TEMPLATE_LIST 4
ad_ip_parameter sys_mb CONFIG.C_DCACHE_FORCE_TAG_LUTRAM 1

# instance: microblaze - local memory & bus

ad_ip_instance lmb_v10 sys_dlmb
ad_ip_instance lmb_v10 sys_ilmb

ad_ip_instance lmb_bram_if_cntlr sys_dlmb_cntlr
ad_ip_parameter sys_dlmb_cntlr CONFIG.C_ECC 0

ad_ip_instance lmb_bram_if_cntlr sys_ilmb_cntlr
ad_ip_parameter sys_ilmb_cntlr CONFIG.C_ECC 0

ad_ip_instance blk_mem_gen sys_lmb_bram
ad_ip_parameter sys_lmb_bram CONFIG.Memory_Type True_Dual_Port_RAM
ad_ip_parameter sys_lmb_bram CONFIG.use_bram_block BRAM_Controller

# instance: microblaze- mdm

ad_ip_instance mdm sys_mb_debug
ad_ip_parameter sys_mb_debug CONFIG.C_USE_UART 1

# instance: system reset/clocks

ad_ip_instance proc_sys_reset sys_rstgen

# instance: ddr (mig)

ad_ip_instance mig_7series axi_ddr_cntrl
set axi_ddr_cntrl_dir [get_property IP_DIR [get_ips [get_property CONFIG.Component_Name [get_bd_cells axi_ddr_cntrl]]]]
file copy -force $ad_hdl_dir/projects/common/genesys2/genesys2_system_mig.prj "$axi_ddr_cntrl_dir/"
ad_ip_parameter axi_ddr_cntrl CONFIG.XML_INPUT_FILE genesys2_system_mig.prj

# instance: default peripherals

#ad_ip_instance clk_wiz sys_ethernet_clkgen
#ad_ip_parameter sys_ethernet_clkgen CONFIG.PRIM_IN_FREQ 100.000
#ad_ip_parameter sys_ethernet_clkgen CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 125.000
#
#ad_ip_instance axi_ethernet axi_ethernet
#ad_ip_parameter axi_ethernet CONFIG.PHY_TYPE RGMII
#
#ad_ip_instance axi_dma axi_ethernet_dma
#ad_ip_parameter axi_ethernet_dma CONFIG.C_INCLUDE_MM2S_DRE 1
#ad_ip_parameter axi_ethernet_dma CONFIG.C_SG_USE_STSAPP_LENGTH 1
#ad_ip_parameter axi_ethernet_dma CONFIG.C_INCLUDE_S2MM_DRE 1

ad_ip_instance axi_iic axi_iic_main

ad_ip_instance axi_uartlite axi_uart
ad_ip_parameter axi_uart CONFIG.C_BAUDRATE 115200

ad_ip_instance axi_timer axi_timer

#TODO: Put back in
ad_ip_instance axi_quad_spi axi_spi
ad_ip_parameter axi_spi CONFIG.C_USE_STARTUP 0
ad_ip_parameter axi_spi CONFIG.C_NUM_SS_BITS 8
ad_ip_parameter axi_spi CONFIG.C_SCK_RATIO 8

ad_ip_instance axi_gpio axi_gpio
ad_ip_parameter axi_gpio CONFIG.C_IS_DUAL 1
ad_ip_parameter axi_gpio CONFIG.C_GPIO_WIDTH 32
ad_ip_parameter axi_gpio CONFIG.C_GPIO2_WIDTH 32
ad_ip_parameter axi_gpio CONFIG.C_INTERRUPT_PRESENT 1

# instance: interrupt

ad_ip_instance axi_intc axi_intc
ad_ip_parameter axi_intc CONFIG.C_HAS_FAST 0

ad_ip_instance xlconcat sys_concat_intc
ad_ip_parameter sys_concat_intc CONFIG.NUM_PORTS 16

# linear flash

#TODO: Put back in
ad_ip_instance axi_quad_spi axi_qspi_flash
ad_ip_parameter axi_qspi_flash CONFIG.USE_BOARD_FLOW true
ad_ip_parameter axi_qspi_flash CONFIG.QSPI_BOARD_INTERFACE qspi_flash
ad_ip_parameter axi_qspi_flash CONFIG.C_TYPE_OF_AXI4_INTERFACE 1
ad_ip_parameter axi_qspi_flash CONFIG.C_SPI_MEM_ADDR_BITS 32
ad_ip_parameter axi_qspi_flash CONFIG.C_S_AXI4_ID_WIDTH 0

####TODO
#ad_ip_parameter axi_qspi_flash CONFIG.C_MEM0_TYPE 2
#ad_ip_parameter axi_qspi_flash CONFIG.C_S_AXI_MEM_ID_WIDTH 0
#ad_ip_parameter axi_qspi_flash CONFIG.C_THZCE_PS_MEM_0 20000
#ad_ip_parameter axi_qspi_flash CONFIG.C_TLZWE_PS_MEM_0 0
#ad_ip_parameter axi_qspi_flash CONFIG.C_TWC_PS_MEM_0 19000
#ad_ip_parameter axi_qspi_flash CONFIG.C_WR_REC_TIME_MEM_0 0
#ad_ip_parameter axi_qspi_flash CONFIG.C_TWP_PS_MEM_0 50000
#ad_ip_parameter axi_qspi_flash CONFIG.C_TWPH_PS_MEM_0 20000
#ad_ip_parameter axi_qspi_flash CONFIG.C_TPACC_PS_FLASH_0 25000
#ad_ip_parameter axi_qspi_flash CONFIG.C_TCEDV_PS_MEM_0 100000
#ad_ip_parameter axi_qspi_flash CONFIG.C_TAVDV_PS_MEM_0 100000
#ad_ip_parameter axi_qspi_flash CONFIG.C_THZOE_PS_MEM_0 15000

# connections

ad_connect  sys_mb_debug/Debug_SYS_Rst sys_rstgen/mb_debug_sys_rst
ad_connect  sys_rstgen/mb_reset sys_mb/Reset
ad_connect  sys_rstgen/bus_struct_reset sys_dlmb/SYS_Rst
ad_connect  sys_rstgen/bus_struct_reset sys_ilmb/SYS_Rst
ad_connect  sys_rstgen/bus_struct_reset sys_dlmb_cntlr/LMB_Rst
ad_connect  sys_rstgen/bus_struct_reset sys_ilmb_cntlr/LMB_Rst

# microblaze local memory

ad_connect  sys_dlmb/LMB_Sl_0   sys_dlmb_cntlr/SLMB
ad_connect  sys_ilmb/LMB_Sl_0   sys_ilmb_cntlr/SLMB
ad_connect  sys_dlmb_cntlr/BRAM_PORT  sys_lmb_bram/BRAM_PORTA
ad_connect  sys_ilmb_cntlr/BRAM_PORT  sys_lmb_bram/BRAM_PORTB
ad_connect  sys_mb/DLMB   sys_dlmb/LMB_M
ad_connect  sys_mb/ILMB   sys_ilmb/LMB_M

# microblaze debug & interrupt

ad_connect sys_mb_debug/MBDEBUG_0   sys_mb/DEBUG
ad_connect axi_intc/interrupt   sys_mb/INTERRUPT
ad_connect sys_concat_intc/dout   axi_intc/intr

# defaults (peripherals)

ad_connect axi_ddr_cntrl/mmcm_locked   sys_rstgen/dcm_locked

ad_connect sys_cpu_clk    axi_ddr_cntrl/ui_addn_clk_0
ad_connect sys_200m_clk   axi_ddr_cntrl/ui_clk
ad_connect sys_cpu_resetn axi_ddr_cntrl/aresetn
ad_connect sys_cpu_reset  sys_rstgen/peripheral_reset
ad_connect sys_cpu_resetn sys_rstgen/peripheral_aresetn

ad_connect sys_cpu_clk  sys_rstgen/slowest_sync_clk
ad_connect sys_cpu_clk  sys_mb/Clk
ad_connect sys_cpu_clk  sys_dlmb/LMB_Clk
ad_connect sys_cpu_clk  sys_ilmb/LMB_Clk
ad_connect sys_cpu_clk  sys_dlmb_cntlr/LMB_Clk
ad_connect sys_cpu_clk  sys_ilmb_cntlr/LMB_Clk

#TODO: Put back in
ad_connect sys_cpu_clk  axi_spi/ext_spi_clk

# defaults (interrupts)

ad_connect sys_concat_intc/In0    axi_timer/interrupt
ad_connect sys_concat_intc/In1    GND
ad_connect sys_concat_intc/In2    GND
ad_connect sys_concat_intc/In3    GND
ad_connect sys_concat_intc/In4    axi_uart/interrupt
ad_connect sys_concat_intc/In5    GND
ad_connect sys_concat_intc/In6    GND
ad_connect sys_concat_intc/In7    GND
ad_connect sys_concat_intc/In8    GND
ad_connect sys_concat_intc/In9    axi_iic_main/iic2intc_irpt
ad_connect sys_concat_intc/In10   axi_spi/ip2intc_irpt
ad_connect sys_concat_intc/In11   axi_gpio/ip2intc_irpt
ad_connect sys_concat_intc/In12   GND
ad_connect sys_concat_intc/In13   GND
ad_connect sys_concat_intc/In14   GND
ad_connect sys_concat_intc/In15   GND

# defaults (external interface)

ad_connect  sys_rst sys_rstgen/ext_reset_in
ad_connect  sys_rst axi_ddr_cntrl/sys_rst
ad_connect  sys_clk_p axi_ddr_cntrl/sys_clk_p
ad_connect  sys_clk_n axi_ddr_cntrl/sys_clk_n
ad_connect  ddr3 axi_ddr_cntrl/DDR3
#ad_connect  mdio axi_ethernet/mdio
#ad_connect  rgmii axi_ethernet/rgmii
ad_connect  uart_sin axi_uart/rx
ad_connect  uart_sout axi_uart/tx
ad_connect  iic_main axi_iic_main/iic

#TODO: Put back in
ad_connect  spi_csn_i axi_spi/ss_i
ad_connect  spi_csn_o axi_spi/ss_o
ad_connect  spi_clk_i axi_spi/sck_i
ad_connect  spi_clk_o axi_spi/sck_o
ad_connect  spi_sdo_i axi_spi/io0_i
ad_connect  spi_sdo_o axi_spi/io0_o
ad_connect  spi_sdi_i axi_spi/io1_i

ad_connect  gpio0_i axi_gpio/gpio_io_i
ad_connect  gpio0_o axi_gpio/gpio_io_o
ad_connect  gpio0_t axi_gpio/gpio_io_t
ad_connect  gpio1_i axi_gpio/gpio2_io_i
ad_connect  gpio1_o axi_gpio/gpio2_io_o
ad_connect  gpio1_t axi_gpio/gpio2_io_t

# qspi_flash

#TODO: Put back in
ad_connect axi_qspi_flash/SPI_0 qspi_flash

ad_connect sys_cpu_resetn axi_qspi_flash/s_axi4_aresetn
ad_connect sys_cpu_clk axi_qspi_flash/s_axi4_aclk
ad_connect sys_cpu_clk axi_qspi_flash/ext_spi_clk

# ethernet & ethernet dma

#ad_connect  sys_cpu_clk axi_ethernet/axis_clk
#ad_connect  sys_200m_clk axi_ethernet/ref_clk
#ad_connect  sys_200m_clk sys_ethernet_clkgen/clk_in1
#ad_connect  sys_ethernet_clkgen/clk_out1 axi_ethernet/gtx_clk
#ad_connect  axi_ethernet/phy_rst_n phy_rst_n
#
#ad_connect  axi_ethernet/axi_txd_arstn axi_ethernet_dma/mm2s_prmry_reset_out_n
#ad_connect  axi_ethernet/axi_txc_arstn axi_ethernet_dma/mm2s_cntrl_reset_out_n
#ad_connect  axi_ethernet/axi_rxd_arstn axi_ethernet_dma/s2mm_prmry_reset_out_n
#ad_connect  axi_ethernet/axi_rxs_arstn axi_ethernet_dma/s2mm_sts_reset_out_n
#
#ad_connect  axi_ethernet/s_axis_txd axi_ethernet_dma/M_AXIS_MM2S
#ad_connect  axi_ethernet/s_axis_txc axi_ethernet_dma/M_AXIS_CNTRL
#ad_connect  axi_ethernet/m_axis_rxd axi_ethernet_dma/S_AXIS_S2MM
#ad_connect  axi_ethernet/m_axis_rxs axi_ethernet_dma/S_AXIS_STS


# address map

ad_cpu_interconnect 0x41400000 sys_mb_debug
#ad_cpu_interconnect 0x40E00000 axi_ethernet
#ad_cpu_interconnect 0x41E10000 axi_ethernet_dma
ad_cpu_interconnect 0x41200000 axi_intc
ad_cpu_interconnect 0x41C00000 axi_timer
ad_cpu_interconnect 0x40600000 axi_uart
ad_cpu_interconnect 0x41600000 axi_iic_main
ad_cpu_interconnect 0x40000000 axi_gpio

#TODO: Put back in
ad_cpu_interconnect 0x44A70000 axi_spi
ad_cpu_interconnect 0x60000000 axi_qspi_flash

ad_mem_hp0_interconnect sys_200m_clk axi_ddr_cntrl/S_AXI
ad_mem_hp0_interconnect sys_cpu_clk sys_mb/M_AXI_DC
ad_mem_hp0_interconnect sys_cpu_clk sys_mb/M_AXI_IC
#ad_mem_hp0_interconnect sys_cpu_clk axi_ethernet_dma/M_AXI_SG
#ad_mem_hp0_interconnect sys_cpu_clk axi_ethernet_dma/M_AXI_MM2S
#ad_mem_hp0_interconnect sys_cpu_clk axi_ethernet_dma/M_AXI_S2MM

create_bd_addr_seg -range 0x20000 -offset 0x0 [get_bd_addr_spaces sys_mb/Data] \
  [get_bd_addr_segs sys_dlmb_cntlr/SLMB/Mem] SEG_dlmb_cntlr
create_bd_addr_seg -range 0x20000 -offset 0x0 [get_bd_addr_spaces sys_mb/Instruction] \
  [get_bd_addr_segs sys_ilmb_cntlr/SLMB/Mem] SEG_ilmb_cntlr

#TODO: Put back in
set_property range 0x2000000 [get_bd_addr_segs {sys_mb/Data/SEG_data_axi_qspi_flash}]

#set_property range 0x2000    [get_bd_addr_segs {sys_mb/Data/SEG_data_axi_ethernet}]

ad_connect axi_ddr_cntrl/device_temp_i GND


