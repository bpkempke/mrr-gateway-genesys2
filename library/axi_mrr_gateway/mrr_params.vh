localparam LOOPBACK_QUEUE_COUNTER_LEN_LOG2 = 20;
localparam LOOPBACK_QUEUE_LEN_LOG2 = 10;
localparam LOOPBACK_MESSAGE_LEN = 32;
localparam CHIP_ID_LEN = 16;
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
localparam PRIMARY_FFT_LEN = 64;
localparam PRIMARY_FFT_LEN_LOG2 = 6;
localparam PRIMARY_FFT_LEN_DECIM_LOG2 = 6;
localparam PRIMARY_FFT_WIDTH = 16;
localparam PRIMARY_FFT_MAX_LEN = 1024;
localparam PRIMARY_FFT_MAX_LEN_LOG2 = 10;
localparam PRIMARY_FFT_MAX_LEN_LOG2_LOG2 = 4;
localparam PRIMARY_FFT_DECIM_LOG2 = 0;
localparam PRIMARY_FFT_DECIM = 1;
localparam PRIMARY_FFT_MAX_LEN_DECIM_LOG2 = 6;
localparam PRIMARY_FFT_MAX_LEN_DECIM_LOG2_LOG2 = 3;
localparam SEARCH_COUNTER_LEN_LOG2 = 3;
localparam SECONDARY_FFT_LEN = 256;
localparam SECONDARY_FFT_LEN_LOG2 = 8;
localparam SECONDARY_FFT_MAX_LEN_LOG2 = 9;
localparam SECONDARY_FFT_MAX_LEN_LOG2_LOG2 = 4;
localparam FFT_HIST_LEN = 16384;
localparam FFT_HIST_LEN_LOG2 = 14;
localparam FFT_HIST_LEN_DECIM = 16384;
localparam FFT_HIST_LEN_DECIM_LOG2 = 14;
localparam NUM_CORRELATORS = 16;
localparam NUM_CORRELATORS_LOG2 = 4;
localparam NUM_METADATA = 7;
localparam NUM_METADATA_LOG2 = 3;
localparam OVERSAMPLING_RATIO = 16;
localparam OVERSAMPLING_RATIO_LOG2 = 4;
localparam NUM_DECODE_PATHWAYS = 5;
localparam NUM_DECODE_PATHWAYS_LOG2 = 3;
localparam PN_SEQ_LEN = 15;
localparam PN_SEQ_LEN_LOG2 = 4;
localparam SFO_INT_WIDTH = 16;
localparam SFO_FRAC_WIDTH = 16;
localparam SFO_FRAC_RANGE = 65536;
localparam SFO_SEQ_LEN_LOG2 = 7;
localparam SFO_SEQ_LEN = 72;
localparam NUM_HARMONICS = 5;
localparam NUM_HARMONICS_LOG2 = 3;
localparam RESAMPLE_INT_WIDTH = 16;
localparam RESAMPLE_FRAC_WIDTH = 15;
localparam CORR_WIDTH = 32;
localparam CORR_EXPONENT_WIDTH = 6;
localparam CORR_MANTISSA_WIDTH = 26;
localparam CORR_METADATA_WIDTH = 64;
localparam FFT_SHIFT_WIDTH = 6;
localparam [255:0] SFO_INTS = {16'd25,16'd25,16'd25,16'd25,16'd25,16'd25,16'd25,16'd25,16'd25,16'd25,16'd24,16'd24,16'd24,16'd24,16'd24,16'd24};
localparam [255:0] SFO_FRACS = {16'd58771,16'd52330,16'd45889,16'd39448,16'd33007,16'd26566,16'd20126,16'd13685,16'd7244,16'd803,16'd59898,16'd53457,16'd47016,16'd40575,16'd34135,16'd27694};
localparam [255:0] N1S = {16'd4,16'd4,16'd4,16'd4,16'd5,16'd5,16'd5,16'd5,16'd5,16'd5,16'd5,16'd5,16'd5,16'd5,16'd5,16'd5};
localparam [239:0] N2S = {15'd30890,15'd31507,15'd32129,15'd32755,15'd618,15'd1255,15'd1896,15'd2542,15'd3193,15'd3849,15'd4511,15'd5178,15'd5850,15'd6527,15'd7210,15'd7898};
