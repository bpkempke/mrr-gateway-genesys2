localparam MAX_BITS = 256;
localparam MAX_BITS_LOG2 = 8;
localparam SFO_CTR_LEN = 1024;
localparam SFO_CTR_LEN_LOG2 = 10;
localparam SFO_CTR_INCR = 1;
localparam JITTER_INCR = 10;
localparam JITTER_MIN = 100;
localparam MAX_CHIPS_PER_SYMBOL_LOG2 = 6;
localparam CORR_WAIT_LEN_LOG2 = 15;
localparam ASSIGNMENT_SKIRT_WIDTH = 30;
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
localparam NUM_METADATA = 7;
localparam NUM_METADATA_LOG2 = 3;
localparam OVERSAMPLING_RATIO = 16;
localparam OVERSAMPLING_RATIO_LOG2 = 4;
localparam NUM_DECODE_PATHWAYS = 1;
localparam NUM_DECODE_PATHWAYS_LOG2 = 1;
localparam PN_SEQ_LEN = 15;
localparam PN_SEQ_LEN_LOG2 = 4;
localparam SFO_INT_WIDTH = 16;
localparam SFO_FRAC_WIDTH = 16;
localparam SFO_FRAC_RANGE = 65536;
localparam SFO_SEQ_LEN_LOG2 = 7;
localparam SFO_SEQ_LEN = 72;
localparam NUM_HARMONICS = 7;
localparam NUM_HARMONICS_LOG2 = 3;
localparam RESAMPLE_INT_WIDTH = 16;
localparam RESAMPLE_FRAC_WIDTH = 15;
localparam CORR_WIDTH = 32;
localparam CORR_EXPONENT_WIDTH = 6;
localparam CORR_MANTISSA_WIDTH = 26;
localparam CORR_METADATA_WIDTH = 64;
localparam FFT_SHIFT_WIDTH = 6;
localparam [255:0] SFO_INTS = {16'd16,16'd16,16'd16,16'd16,16'd16,16'd16,16'd16,16'd16,16'd16,16'd16,16'd16,16'd15,16'd15,16'd15,16'd15,16'd15};
localparam [255:0] SFO_FRACS = {16'd44686,16'd40537,16'd36388,16'd32239,16'd28090,16'd23941,16'd19792,16'd15643,16'd11494,16'd7345,16'd3196,16'd64583,16'd60434,16'd56285,16'd52136,16'd47987};
localparam [255:0] N1S = {16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd8,16'd8,16'd8,16'd8,16'd8};
localparam [239:0] N2S = {15'd22052,15'd23010,15'd23975,15'd24948,15'd25928,15'd26916,15'd27911,15'd28914,15'd29925,15'd30944,15'd31971,15'd238,15'd1281,15'd2333,15'd3393,15'd4461};
