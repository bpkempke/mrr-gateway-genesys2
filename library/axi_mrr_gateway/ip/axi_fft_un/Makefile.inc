
include $(TOOLS_DIR)/make/viv_ip_builder.mak

LIB_IP_AXI_FFT_UN_SRCS = $(IP_BUILD_DIR)/axi_fft_un/axi_fft_un.xci

LIB_IP_AXI_FFT_UN_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_fft_un/, \
axi_fft_un.xci.out \
synth/axi_fft_un.vhd \
) 

$(LIB_IP_AXI_FFT_UN_SRCS) $(LIB_IP_AXI_FFT_UN_OUTS) : $(LIB_IP_DIR)/axi_fft_un/axi_fft_un.xci
	$(call BUILD_VIVADO_IP,axi_fft_un,$(ARCH),$(PART_ID),$(LIB_IP_DIR),$(IP_BUILD_DIR),0)
