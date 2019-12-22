localparam SFO_CTR_LEN = 1024;
localparam SFO_CTR_LEN_LOG2 = 10;
localparam SFO_CTR_INCR = 1;
localparam JITTER_INCR = 10;
localparam JITTER_MIN = 100;
localparam MAX_CHIPS_PER_SYMBOL_LOG2 = 7;
localparam CORR_WAIT_LEN_LOG2 = 15;
localparam ASSIGNMENT_SKIRT_WIDTH = 30;
localparam SKIRT_WIDTH = 2;
localparam SKIRT_WIDTH_LOG2 = 1;
localparam RECHARGE_CYCLES = 85;
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
localparam SECONDARY_FFT_LEN = 1024;
localparam SECONDARY_FFT_LEN_LOG2 = 10;
localparam SECONDARY_FFT_MAX_LEN_LOG2 = 11;
localparam SECONDARY_FFT_MAX_LEN_LOG2_LOG2 = 4;
localparam FFT_HIST_LEN = 1048576;
localparam FFT_HIST_LEN_LOG2 = 20;
localparam FFT_HIST_LEN_DECIM = 65536;
localparam FFT_HIST_LEN_DECIM_LOG2 = 16;
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
localparam NUM_HARMONICS = 45;
localparam NUM_HARMONICS_LOG2 = 6;
localparam RESAMPLE_INT_WIDTH = 16;
localparam RESAMPLE_FRAC_WIDTH = 15;
localparam CORR_WIDTH = 32;
localparam CORR_EXPONENT_WIDTH = 6;
localparam CORR_MANTISSA_WIDTH = 26;
localparam CORR_METADATA_WIDTH = 64;
localparam FFT_SHIFT_WIDTH = 6;
localparam [255:0] SFO_INTS = {16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11,16'd11};
localparam [255:0] SFO_FRACS = {16'd14110,16'd13397,16'd12684,16'd11972,16'd11259,16'd10547,16'd9834,16'd9122,16'd8409,16'd7697,16'd6984,16'd6271,16'd5559,16'd4846,16'd4134,16'd3421};
localparam [255:0] N1S = {16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4,16'd4};
localparam [239:0] N2S = {15'd3392,15'd3523,15'd3654,15'd3785,15'd3916,15'd4047,15'd4179,15'd4311,15'd4443,15'd4576,15'd4709,15'd4842,15'd4975,15'd5109,15'd5243,15'd5377};
