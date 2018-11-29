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
localparam PRIMARY_FFT_WIDTH = 16;
localparam PRIMARY_FFT_MAX_LEN = 1024;
localparam PRIMARY_FFT_MAX_LEN_LOG2 = 10;
localparam PRIMARY_FFT_MAX_LEN_LOG2_LOG2 = 4;
localparam PRIMARY_FFT_DECIM_LOG2 = 4;
localparam PRIMARY_FFT_DECIM = 16;
localparam PRIMARY_FFT_MAX_LEN_DECIM_LOG2 = 6;
localparam PRIMARY_FFT_MAX_LEN_DECIM_LOG2_LOG2 = 3;
localparam SEARCH_COUNTER_LEN_LOG2 = 3;
localparam SECONDARY_FFT_LEN = 512;
localparam SECONDARY_FFT_LEN_LOG2 = 9;
localparam SECONDARY_FFT_MAX_LEN_LOG2 = 9;
localparam SECONDARY_FFT_MAX_LEN_LOG2_LOG2 = 4;
localparam FFT_HIST_LEN = 524288;
localparam FFT_HIST_LEN_LOG2 = 19;
localparam FFT_HIST_LEN_DECIM = 32768;
localparam FFT_HIST_LEN_DECIM_LOG2 = 15;
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
localparam [255:0] SFO_INTS = {16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd32,16'd31};
localparam [255:0] SFO_FRACS = {16'd58256,16'd54107,16'd49958,16'd45809,16'd41660,16'd37511,16'd33362,16'd29213,16'd25064,16'd20915,16'd16766,16'd12617,16'd8468,16'd4319,16'd170,16'd61557};
localparam [255:0] N1S = {16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd7,16'd8};
localparam [239:0] N2S = {15'd25682,15'd26174,15'd26668,15'd27164,15'd27661,15'd28161,15'd28663,15'd29166,15'd29671,15'd30179,15'd30688,15'd31200,15'd31713,15'd32229,15'd32746,15'd498};
