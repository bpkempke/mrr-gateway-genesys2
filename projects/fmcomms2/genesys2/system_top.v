// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module system_top (

  //output phy_rst_n,
  inout qspi_flash_io0_io,
  inout qspi_flash_io1_io,
  inout qspi_flash_io2_io,
  inout qspi_flash_io3_io,
  inout qspi_flash_ss_io,
  //input [3:0]rgmii_rd,
  //input rgmii_rx_ctl,
  //input rgmii_rxc,
  //output [3:0]rgmii_td,
  //output rgmii_tx_ctl,
  //output rgmii_txc,

  inout [7:0] PROG_D,
  input PROG_CLKO,
  output PROG_OEN,
  output PROG_RDN,
  input PROG_RXFN,
  output PROG_SIWUN,
  output PROG_SPIEN,
  input PROG_TXEN,
  output PROG_WRN,

  input                   sys_rst,
  input                   sys_clk_p,
  input                   sys_clk_n,

  input                   uart_sin,
  output                  uart_sout,

  //output      [ 2:0]      ddr3_1_n,
  //output      [ 1:0]      ddr3_1_p,
  output                  ddr3_reset_n,
  output      [14:0]      ddr3_addr,
  output      [ 2:0]      ddr3_ba,
  output                  ddr3_cas_n,
  output                  ddr3_ras_n,
  output                  ddr3_we_n,
  output      [ 0:0]      ddr3_ck_n,
  output      [ 0:0]      ddr3_ck_p,
  output      [ 0:0]      ddr3_cke,
  output      [ 0:0]      ddr3_cs_n,
  output      [ 3:0]      ddr3_dm,
  inout       [31:0]      ddr3_dq,
  inout       [ 3:0]      ddr3_dqs_n,
  inout       [ 3:0]      ddr3_dqs_p,
  output      [ 0:0]      ddr3_odt,

  //output                  mdio_mdc,
  //inout                   mdio_mdio,

  output                  fan_pwm,

  inout       [16:0]      gpio_bd,

  //output                  iic_rstn,
  inout                   iic_scl,
  inout                   iic_sda,

  input                   rx_clk_in_p,
  input                   rx_clk_in_n,
  input                   rx_frame_in_p,
  input                   rx_frame_in_n,
  input       [ 5:0]      rx_data_in_p,
  input       [ 5:0]      rx_data_in_n,

  output                  tx_clk_out_p,
  output                  tx_clk_out_n,
  output                  tx_frame_out_p,
  output                  tx_frame_out_n,
  output      [ 5:0]      tx_data_out_p,
  output      [ 5:0]      tx_data_out_n,

  output                  txnrx,
  output                  enable,

  inout                   gpio_resetb,
  inout                   gpio_sync,
  inout                   gpio_en_agc,
  inout       [ 3:0]      gpio_ctl,
  inout       [ 7:0]      gpio_status,

  output                  spi_csn_0,
  output                  spi_clk,
  output                  spi_mosi,
  input                   spi_miso,

  output      [15:0]      debug);

  // internal signals

  wire    [63:0]  gpio_i;
  wire    [63:0]  gpio_o;
  wire    [63:0]  gpio_t;
  wire    [ 7:0]  spi_csn;
  wire            tdd_sync_t;
  wire            tdd_sync_o;
  wire            tdd_sync_i;

  // default logic

  //assign ddr3_1_p = 2'b11;
  //assign ddr3_1_n = 3'b000;
  assign fan_pwm  = 1'b1;
  //assign iic_rstn = 1'b1;
  assign spi_csn_0 = spi_csn[0];

  wire peripheral_aresetn;
  assign gpio_resetb = peripheral_aresetn;

  // instantiations

  ad_iobuf #(.DATA_WIDTH(15)) i_iobuf (
    .dio_t (gpio_t[46:32]),
    .dio_i (gpio_o[46:32]),
    .dio_o (gpio_i[46:32]),
    .dio_p ({// gpio_resetb,
              gpio_sync,
              gpio_en_agc,
              gpio_ctl,
              gpio_status}));

  ad_iobuf #(.DATA_WIDTH(17)) i_iobuf_bd (
    .dio_t (gpio_t[16:0]),
    .dio_i (gpio_o[16:0]),
    .dio_o (gpio_i[16:0]),
    .dio_p (gpio_bd));

  assign gpio_i[63:47] = gpio_o[63:47];
  assign gpio_i[31:17] = gpio_o[31:17];

  system_wrapper i_system_wrapper (
    //.phy_rst_n (phy_rst_n),

    //TODO: PUT BACK IN
    .qspi_flash_io0_io (qspi_flash_io0_io),
    .qspi_flash_io1_io (qspi_flash_io1_io),
    .qspi_flash_io2_io (qspi_flash_io2_io),
    .qspi_flash_io3_io (qspi_flash_io3_io),
    .qspi_flash_ss_io (qspi_flash_ss_io),

    //.rgmii_rd (rgmii_rd),
    //.rgmii_rx_ctl (rgmii_rx_ctl),
    //.rgmii_rxc (rgmii_rxc),
    //.rgmii_td (rgmii_td),
    //.rgmii_tx_ctl (rgmii_tx_ctl),
    //.rgmii_txc (rgmii_txc),

    .ddr3_addr (ddr3_addr),
    .ddr3_ba (ddr3_ba),
    .ddr3_cas_n (ddr3_cas_n),
    .ddr3_ck_n (ddr3_ck_n),
    .ddr3_ck_p (ddr3_ck_p),
    .ddr3_cke (ddr3_cke),
    .ddr3_cs_n (ddr3_cs_n),
    .ddr3_dm (ddr3_dm),
    .ddr3_dq (ddr3_dq),
    .ddr3_dqs_n (ddr3_dqs_n),
    .ddr3_dqs_p (ddr3_dqs_p),
    .ddr3_odt (ddr3_odt),
    .ddr3_ras_n (ddr3_ras_n),
    .ddr3_reset_n (ddr3_reset_n),
    .ddr3_we_n (ddr3_we_n),
    .iic_main_scl_io (iic_scl),
    .iic_main_sda_io (iic_sda),
    .gpio0_o (gpio_o[31:0]),
    .gpio0_t (gpio_t[31:0]),
    .gpio0_i (gpio_i[31:0]),
    .gpio1_o (gpio_o[63:32]),
    .gpio1_t (gpio_t[63:32]),
    .gpio1_i (gpio_i[63:32]),
    //.mdio_mdc (mdio_mdc),
    //.mdio_mdio_io (mdio_mdio),
    .sys_clk_n (sys_clk_n),
    .sys_clk_p (sys_clk_p),
    .sys_rst (~sys_rst),
    .spi_clk_i (spi_clk),
    .spi_clk_o (spi_clk),
    .spi_csn_i (spi_csn),
    .spi_csn_o (spi_csn),
    .spi_sdi_i (spi_miso),
    .spi_sdo_i (spi_mosi),
    .spi_sdo_o (spi_mosi),
    .rx_clk_in_n (rx_clk_in_n),
    .rx_clk_in_p (rx_clk_in_p),
    .rx_data_in_n (rx_data_in_n),
    .rx_data_in_p (rx_data_in_p),
    .rx_frame_in_n (rx_frame_in_n),
    .rx_frame_in_p (rx_frame_in_p),
    .tx_clk_out_n (tx_clk_out_n),
    .tx_clk_out_p (tx_clk_out_p),
    .tx_data_out_n (tx_data_out_n),
    .tx_data_out_p (tx_data_out_p),
    .tx_frame_out_n (tx_frame_out_n),
    .tx_frame_out_p (tx_frame_out_p),
    .tdd_sync_i (1'b0),
    .tdd_sync_o (),
    .tdd_sync_t (),
    .uart_sin (uart_sin),
    .uart_sout (uart_sout),
    .enable (enable),
    .txnrx (txnrx),
    .gateway_enable (gpio_o[31]),
    .gateway_soft_reset (gpio_o[30]),
    .gateway_debug (debug),
    .PROG_D(PROG_D),
    .PROG_CLKO(PROG_CLKO),
    .PROG_OEN(PROG_OEN),
    .PROG_RDN(PROG_RDN),
    .PROG_RXFN(PROG_RXFN),
    .PROG_SIWUN(PROG_SIWUN),
    .PROG_SPIEN(PROG_SPIEN),
    .PROG_TXEN(PROG_TXEN),
    .PROG_WRN(PROG_WRN),
    .peripheral_aresetn(peripheral_aresetn),
    .up_enable (gpio_o[47]),
    .up_txnrx (gpio_o[48]));

endmodule

// ***************************************************************************
// ***************************************************************************
