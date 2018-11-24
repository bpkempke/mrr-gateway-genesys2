source ../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create axi_mrr_gateway
adi_ip_files axi_mrr_gateway [list \
  "ip/axi_fft_un/axi_fft_un.xci" \
  "ip/fifo_short_2clk/fifo_short_2clk.xci" \
  "ip/divide_uint32/divide_uint32.xci" \
  "ettus/axi_dma_master.v" \
  "ettus/axi_pipe_join.v" \
  "ettus/complex_to_magsq.v" \
  "ettus/mult.v" \
  "ettus/synchronizer_impl.v" \
  "ettus/axi_fifo_bram.v" \
  "ettus/axi_fifo_short.v" \
  "ettus/axi_pipe_mac.v" \
  "ettus/fft_shift.v" \
  "ettus/ram_2port.v" \
  "ettus/synchronizer.v" \
  "ettus/axi_fifo_flop2.v" \
  "ettus/axi_pipe.v" \
  "ettus/m_cordic_stage.v" \
  "ettus/setting_reg.v" \
  "ettus/axi_fifo.v" \
  "ettus/chdr_framer.v" \
  "ettus/m_cordic_z24.v" \
  "ettus/sign_extend.v" \
  "ettus/axi_join.v" \
  "ettus/complex_to_mag_approx.v" \
  "ettus/mult_add.v" \
  "ettus/split_complex.v" \
  "m_resample.v" \
  "mrr_cfo_mf_es.v" \
  "mrr_log2_expand.v" \
  "mrr_sfo_fft_normalization.v" \
  "mrr_basic_header.v" \
  "mrr_correlation.v" \
  "mrr_loopback_bpk.v" \
  "axi_mrr_gateway.v" \
  "mrr_cfo_fft_interpreter.v" \
  "mrr_dram_fft_buffer.v" \
  "mrr_prio_encoder.v" \
  "sfo_fft_correlator.v" ]

generate_target {all} [get_files ip/axi_fft_un/axi_fft_un.xci]
generate_target {all} [get_files ip/fifo_short_2clk/fifo_short_2clk.xci]
generate_target {all} [get_files ip/divide_uint32/divide_uint32.xci]

adi_ip_properties axi_mrr_gateway

ipx::infer_bus_interface ce_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface ce_rst xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

ipx::save_core [ipx::current_core]


