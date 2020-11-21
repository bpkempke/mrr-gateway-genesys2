localparam SFO_CTR_LEN = 1024;
localparam SFO_CTR_LEN_LOG2 = 10;
localparam SFO_CTR_INCR = 1;
localparam JITTER_INCR = 10;
localparam JITTER_MIN = 100;
localparam MAX_CHIPS_PER_SYMBOL_LOG2 = 6;
localparam CORR_WAIT_LEN_LOG2 = 15;
localparam SKIRT_WIDTH = 2;
localparam SKIRT_WIDTH_LOG2 = 1;
localparam RECHARGE_CYCLES = 4;
localparam SYMBOL_CYCLES = 4;
localparam ESAMP_WIDTH = 20;
localparam GLOBAL_SEARCH_LEN = 3;
localparam GLOBAL_SEARCH_LEN_LOG2 = 2;
localparam PULSE_SEPARATION_LOG2 = 1;
localparam PRIMARY_FFT_LEN = 1024;
localparam PRIMARY_FFT_LEN_LOG2 = 10;
localparam PRIMARY_FFT_LEN_DECIM_LOG2 = 6;
localparam PRIMARY_FFT_WIDTH = 16;
localparam PRIMARY_FFT_MAX_LEN = 1024;
localparam PRIMARY_FFT_MAX_LEN_LOG2 = 10;
localparam PRIMARY_FFT_MAX_LEN_LOG2_LOG2 = 4;
localparam PRIMARY_FFT_DECIM_LOG2 = 4;
localparam PRIMARY_FFT_DECIM = 16;
localparam PRIMARY_FFT_MAX_LEN_DECIM_LOG2 = 6;
localparam PRIMARY_FFT_MAX_LEN_DECIM_LOG2_LOG2 = 3;
localparam SEARCH_COUNTER_LEN_LOG2 = 3;
localparam SECONDARY_FFT_LEN = 256;
localparam SECONDARY_FFT_LEN_LOG2 = 8;
localparam SECONDARY_FFT_MAX_LEN_LOG2 = 9;
localparam SECONDARY_FFT_MAX_LEN_LOG2_LOG2 = 4;
localparam FFT_HIST_LEN = 262144;
localparam FFT_HIST_LEN_LOG2 = 18;
localparam FFT_HIST_LEN_DECIM = 16384;
localparam FFT_HIST_LEN_DECIM_LOG2 = 14;
localparam NUM_CORRELATORS = 16;
localparam NUM_CORRELATORS_LOG2 = 4;
localparam NUM_METADATA = 9;
localparam NUM_METADATA_LOG2 = 4;
localparam OVERSAMPLING_RATIO = 16;
localparam OVERSAMPLING_RATIO_LOG2 = 4;
localparam NUM_DECODE_PATHWAYS = 3;
localparam NUM_DECODE_PATHWAYS_LOG2 = 2;
localparam NUM_MUX_CHANNELS = 5;
localparam NUM_MUX_CHANNELS_LOG2 = 3;
localparam PN_SEQ_LEN = 15;
localparam PN_SEQ_LEN_LOG2 = 4;
localparam SFO_INT_WIDTH = 16;
localparam SFO_FRAC_WIDTH = 16;
localparam SFO_FRAC_RANGE = 65536;
localparam SFO_SEQ_LEN_LOG2 = 7;
localparam SFO_SEQ_LEN = 72;
localparam MAX_NUM_HARMONICS = 50;
localparam MAX_NUM_HARMONICS_LOG2 = 6;
localparam RESAMPLE_INT_WIDTH = 16;
localparam RESAMPLE_FRAC_WIDTH = 15;
localparam CORR_WIDTH = 32;
localparam CORR_EXPONENT_WIDTH = 6;
localparam CORR_MANTISSA_WIDTH = 26;
localparam CORR_METADATA_WIDTH = 91;
localparam FFT_SHIFT_WIDTH = 6;
localparam [255:0] SFO_INTS = {16'd14,16'd14,16'd14,16'd14,16'd14,16'd14,16'd14,16'd14,16'd13,16'd13,16'd13,16'd13,16'd13,16'd13,16'd13,16'd13};
localparam [255:0] SFO_FRACS = {16'd27008,16'd23424,16'd19839,16'd16255,16'd12670,16'd9086,16'd5501,16'd1917,16'd63868,16'd60284,16'd56699,16'd53115,16'd49530,16'd45946,16'd42361,16'd38777};
localparam [255:0] N1S = {16'd8,16'd8,16'd8,16'd8,16'd9,16'd9,16'd9,16'd9,16'd9,16'd9,16'd9,16'd9,16'd9,16'd9,16'd9,16'd9};
localparam [239:0] N2S = {15'd28882,15'd29990,15'd31107,15'd32233,15'd600,15'd1743,15'd2895,15'd4056,15'd5226,15'd6405,15'd7594,15'd8792,15'd10000,15'd11217,15'd12444,15'd13681};
