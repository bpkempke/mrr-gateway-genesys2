
`timescale 1ns/1ps

module sim_top;

  reg sys_clk;
  reg sys_rst;

  reg rx_clk;
  reg rx_frame;
  reg [5:0] rx_data;

  wire ddr3_reset_n;
  wire [14:0] ddr3_addr;
  wire [ 2:0] ddr3_ba;
  wire ddr3_cas_n;
  wire ddr3_ras_n;
  wire ddr3_we_n;
  wire [ 0:0] ddr3_ck_n;
  wire [ 0:0] ddr3_ck_p;
  wire [ 0:0] ddr3_cke;
  wire [ 0:0] ddr3_cs_n;
  wire [ 3:0] ddr3_dm;
  wire [31:0] ddr3_dq;
  wire [ 3:0] ddr3_dqs_n;
  wire [ 3:0] ddr3_dqs_p;
  wire [ 0:0] ddr3_odt;

  ddr3_model #(
    .MEM_BITS(18),
    .DEBUG(0)
  ) dr3_1 (
    .rst_n(ddr3_reset_n),
    .ck(ddr3_ck_p),
    .ck_n(ddr3_ck_n),
    .cke(ddr3_cke),
    .cs_n(ddr3_cs_n),
    .ras_n(ddr3_ras_n),
    .cas_n(ddr3_cas_n),
    .we_n(ddr3_we_n),
    .dm_tdqs(ddr3_dm[1:0]),
    .ba(ddr3_ba),
    .addr(ddr3_addr),
    .dq(ddr3_dq[15:0]),
    .dqs(ddr3_dqs_p[1:0]),
    .dqs_n(ddr3_dqs_n[1:0]),
    .tdqs_n(),
    .odt(ddr3_odt)
  );

  ddr3_model #(
    .MEM_BITS(18),
    .DEBUG(0)
  ) dr3_2 (
    .rst_n(ddr3_reset_n),
    .ck(ddr3_ck_p),
    .ck_n(ddr3_ck_n),
    .cke(ddr3_cke),
    .cs_n(ddr3_cs_n),
    .ras_n(ddr3_ras_n),
    .cas_n(ddr3_cas_n),
    .we_n(ddr3_we_n),
    .dm_tdqs(ddr3_dm[3:2]),
    .ba(ddr3_ba),
    .addr(ddr3_addr),
    .dq(ddr3_dq[31:16]),
    .dqs(ddr3_dqs_p[3:2]),
    .dqs_n(ddr3_dqs_n[3:2]),
    .tdqs_n(),
    .odt(ddr3_odt)
  );

  system_top st1 (
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_addr(ddr3_addr),
    .ddr3_ba(ddr3_ba),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_cke(ddr3_cke),
    .ddr3_cs_n(ddr3_cs_n),
    .ddr3_dm(ddr3_dm),
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_odt(ddr3_odt),
    .qspi_flash_io0_io(),
    .qspi_flash_io1_io(),
    .qspi_flash_io2_io(),
    .qspi_flash_io3_io(),
    .qspi_flash_ss_io(),
    .sys_rst(~sys_rst),
    .sys_clk_p(sys_clk),
    .sys_clk_n(~sys_clk),
    .uart_sin(),
    .uart_sout(),
    .fan_pwm(),
    .gpio_bd(),
    .iic_scl(),
    .iic_sda(),
    .rx_clk_in_p(rx_clk),
    .rx_clk_in_n(~rx_clk),
    .rx_frame_in_p(rx_frame),
    .rx_frame_in_n(~rx_frame),
    .rx_data_in_p(rx_data),
    .rx_data_in_n(~rx_data),
    .tx_clk_out_p(),
    .tx_clk_out_n(),
    .tx_frame_out_p(),
    .tx_frame_out_n(),
    .tx_data_out_p(),
    .tx_data_out_n(),
    .txnrx(),
    .enable(),
    .gpio_resetb(),
    .gpio_sync(),
    .gpio_en_agc(),
    .gpio_ctl(),
    .gpio_status(),
    .spi_csn_0(),
    .spi_clk(),
    .spi_mosi(),
    .spi_miso()
  );

  initial begin : tb_main
    sys_rst = 1'b1;
    sys_clk = 1'b0;
    rx_frame = 1'b1;
    rx_data = 6'd0;
    rx_clk = 1'b0;
    #500 @(posedge sys_clk);
    sys_rst = 1'b0;
    #500 @(posedge sys_clk);
    force st1.i_system_wrapper.system_i.axi_ad9361.inst.i_rx.i_up_adc_common.up_core_preset = 1'b0;
    force st1.i_system_wrapper.system_i.axi_ad9361.inst.i_rx.adc_enable_i0 = 1'b1;
    force st1.i_system_wrapper.system_i.axi_ad9361.inst.i_rx.adc_enable_q0 = 1'b1;
    force st1.i_system_wrapper.system_i.axi_ad9361.inst.i_rx.adc_r1_mode = 1'b1;
    #5000000 @(posedge sys_clk);
  end

  always @(posedge rx_frame) begin
    rx_data <= rx_data + 1;
  end

  always @(posedge rx_clk) begin
    rx_frame <= ~rx_frame;
  end

  always begin
    sys_clk = 1'b1;
    #2.5 sys_clk = 1'b0;
    #2.5;
  end

  always begin
    rx_clk = 1'b1;
    #12.5 rx_clk = 1'b0;
    #12.5;
  end

endmodule
