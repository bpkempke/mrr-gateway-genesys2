#!/usr/bin/python3

import numpy as np

#IDEAL_SFO_FREQ = 200e3
#IDEAL_SFO_FREQ = 213e3
#IDEAL_SFO_FREQ = 216.96e3

#SRR Testing
#Files from Li:
#IDEAL_SFO_FREQ = 247.3e3
#Encapsulated stack:
IDEAL_SFO_FREQ = 245.7e3

SAMPLING_RATE = 20e6

#4us: PULSE_LEN_CYCLES = 1
#52us: PULSE_LEN_CYCLES = 13
#100us: PULSE_LEN_CYCLES = 25
PULSE_LEN_CYCLES = 13

#4us: PRIMARY_FFT_LEN_LOG2 = 6
#8us: PRIMARY_FFT_LEN_LOG2 = 7
#16us: PRIMARY_FFT_LEN_LOG2 = 8
#32us: PRIMARY_FFT_LEN_LOG2 = 9
#52us: PRIMARY_FFT_LEN_LOG2 = 10
#64us: PRIMARY_FFT_LEN_LOG2 = 10
#100us: PRIMARY_FFT_LEN_LOG2 = 10
PRIMARY_FFT_LEN_LOG2 = 10

PRIMARY_FFT_MAX_LEN_LOG2 = 10
PRIMARY_FFT_MAX_LEN_DECIM_LOG2 = 6
#4us, 100us: SECONDARY_FFT_LEN_LOG2 = 8
#52us: SECONDARY_FFT_LEN_LOG2 = 10
SECONDARY_FFT_LEN_LOG2 = 10
SECONDARY_FFT_MAX_LEN_LOG2 = 11

#Gateway requirement: 
# RECHARGE_CYCLES and SYMBOL_CYCLES are expressed in multiples of PULSE_LEN_CYCLES
RECHARGE_CYCLES = 85#4#32
SYMBOL_CYCLES = 4

SFO_CTR_LEN_LOG2 = 10
SFO_CTR_INCR = 1
JITTER_INCR = 10
JITTER_MIN = 100
SKIRT_WIDTH_LOG2 = 1
ASSIGNMENT_SKIRT_WIDTH = 30;
CORR_WAIT_LEN_LOG2 = 15
PULSE_SEPARATION_LOG2 = 1
PRIMARY_FFT_WIDTH = 16
PRIMARY_FFT_DECIM_LOG2 = PRIMARY_FFT_LEN_LOG2 - 6
PRIMARY_FFT_LEN_DECIM_LOG2 = PRIMARY_FFT_LEN_LOG2 - PRIMARY_FFT_DECIM_LOG2
SEARCH_COUNTER_LEN_LOG2 = 3
NUM_CORRELATORS_LOG2 = 4
OVERSAMPLING_RATIO_LOG2 = 4
NUM_DECODE_PATHWAYS = 1
PN_SEQ_LEN = 15
ESAMP_WIDTH = 20
CORR_WIDTH = 32
FFT_SHIFT_WIDTH = 6
CORR_EXPONENT_WIDTH = FFT_SHIFT_WIDTH
CORR_MANTISSA_WIDTH = CORR_WIDTH-CORR_EXPONENT_WIDTH
CORR_METADATA_WIDTH = CORR_WIDTH*2
SFO_FRAC_WIDTH = 16
SFO_INT_WIDTH = 16
SFO_SEQ_LEN = 72
RESAMPLE_INT_WIDTH = 16
RESAMPLE_FRAC_WIDTH = 15
NUM_METADATA = 7;
GLOBAL_SEARCH_LEN = 3
MAX_CHIPS_PER_SYMBOL_LOG2 = 7
FFT_HIST_LEN_LOG2 = PRIMARY_FFT_LEN_LOG2 + SECONDARY_FFT_LEN_LOG2
FFT_HIST_LEN_DECIM_LOG2 = PRIMARY_FFT_LEN_DECIM_LOG2 + SECONDARY_FFT_LEN_LOG2

if SECONDARY_FFT_LEN_LOG2 < 8:
    print("ERROR: Secondary FFT length must by 2^8 or greater to ensure adequate correlation output offload time")

SFO_CTR_LEN = 2**SFO_CTR_LEN_LOG2
SKIRT_WIDTH = 2**SKIRT_WIDTH_LOG2
OVERSAMPLING_RATIO = 2**OVERSAMPLING_RATIO_LOG2
PRIMARY_FFT_LEN = 2**PRIMARY_FFT_LEN_LOG2
PRIMARY_FFT_MAX_LEN = 2**PRIMARY_FFT_MAX_LEN_LOG2
SECONDARY_FFT_LEN = 2**SECONDARY_FFT_LEN_LOG2
FFT_HIST_LEN = 2**FFT_HIST_LEN_LOG2
FFT_HIST_LEN_DECIM = 2**FFT_HIST_LEN_DECIM_LOG2
SFO_FRAC_RANGE = 2**SFO_FRAC_WIDTH
RESAMPLE_FRAC_RANGE = 2**RESAMPLE_FRAC_WIDTH
NUM_CORRELATORS = 2**NUM_CORRELATORS_LOG2
PRIMARY_FFT_DECIM = 2**PRIMARY_FFT_DECIM_LOG2
SECONDARY_FFT_IDEAL_REP_FREQ  = IDEAL_SFO_FREQ/(RECHARGE_CYCLES+SYMBOL_CYCLES)/PULSE_LEN_CYCLES*(PRIMARY_FFT_LEN*SECONDARY_FFT_LEN/SAMPLING_RATE)
NUM_HARMONICS = int(SECONDARY_FFT_LEN/SECONDARY_FFT_IDEAL_REP_FREQ/2)

PRIMARY_FFT_MAX_LEN_LOG2_LOG2 = int(np.ceil(np.log2(PRIMARY_FFT_MAX_LEN_LOG2+1)))
SECONDARY_FFT_MAX_LEN_LOG2_LOG2 = int(np.ceil(np.log2(SECONDARY_FFT_MAX_LEN_LOG2+1)))
PRIMARY_FFT_MAX_LEN_DECIM_LOG2_LOG2 = int(np.ceil(np.log2(PRIMARY_FFT_MAX_LEN_DECIM_LOG2+1)))
GLOBAL_SEARCH_LEN_LOG2 = int(np.ceil(np.log2(GLOBAL_SEARCH_LEN+1)))
NUM_DECODE_PATHWAYS_LOG2 = int(np.ceil(np.log2(NUM_DECODE_PATHWAYS+1)))
NUM_METADATA_LOG2 = int(np.ceil(np.log2(NUM_METADATA+1)))
NUM_HARMONICS_LOG2 = int(np.ceil(np.log2(NUM_HARMONICS+1)))
SFO_SEQ_LEN_LOG2 = int(np.ceil(np.log2(SFO_SEQ_LEN+1)))
PN_SEQ_LEN_LOG2 = int(np.ceil(np.log2(PN_SEQ_LEN)))

print("SECONDARY_FFT_IDEAL_REP_FREQ = {}".format(SECONDARY_FFT_IDEAL_REP_FREQ))

#Generate sfo_vals
sfo_vals = []
resampling_vals = []
num_harmonics = []
for correlator_idx in range(NUM_CORRELATORS):
    sfo_val = SECONDARY_FFT_IDEAL_REP_FREQ*(SECONDARY_FFT_LEN+(correlator_idx+0.5-NUM_CORRELATORS/2))/SECONDARY_FFT_LEN
    sfo_vals.append(sfo_val)
    resampling_vals.append((FFT_HIST_LEN/(2**PRIMARY_FFT_DECIM_LOG2)/(RECHARGE_CYCLES+SYMBOL_CYCLES))/OVERSAMPLING_RATIO/sfo_val)

with open('loopback_params.hpp','w') as f:
    f.write('double secondary_fft_ideal_rep_freq;\n')
    f.write('secondary_fft_ideal_rep_freq = sfo_freq/{}/{}*{};\n'.format(RECHARGE_CYCLES+SYMBOL_CYCLES,PULSE_LEN_CYCLES,PRIMARY_FFT_LEN*SECONDARY_FFT_LEN/SAMPLING_RATE))
    f.write('double sfo_val;\n')
    f.write('double resample_val;\n')
    f.write('uint32_t sfo_val_int;\n')
    f.write('uint32_t sfo_val_frac;\n')
    f.write('uint32_t resample_int;\n')
    f.write('uint32_t resample_frac;\n')
    f.write('for(int ii=0; ii < {}; ii++){{\n'.format(NUM_CORRELATORS))
    f.write('    sfo_val = secondary_fft_ideal_rep_freq*({}+(ii+0.5-{}/2))/{};\n'.format(SECONDARY_FFT_LEN,NUM_CORRELATORS,SECONDARY_FFT_LEN))
    f.write('    sfo_val_int = (uint32_t)sfo_val;\n')
    f.write('    sfo_val_frac = (sfo_val - sfo_val_int)*{};\n'.format(SFO_FRAC_RANGE))
    f.write('    mrr_gateway_ctrl->sr_write("SR_SFO_INT", sfo_val_int);\n')
    f.write('    mrr_gateway_ctrl->sr_write("SR_SFO_FRAC", sfo_val_frac);\n')
    f.write('    resample_val = (double)({})/{}/{}/{}/sfo_val;\n'.format(FFT_HIST_LEN,2**PRIMARY_FFT_DECIM_LOG2,RECHARGE_CYCLES+SYMBOL_CYCLES,OVERSAMPLING_RATIO))
    f.write('    resample_int = (uint32_t)resample_val;\n')
    f.write('    resample_frac = (resample_val - resample_int)*{};\n'.format(RESAMPLE_FRAC_RANGE))
    f.write('    mrr_gateway_ctrl->sr_write("SR_RESAMPLE_INT", resample_int);\n')
    f.write('    mrr_gateway_ctrl->sr_write("SR_RESAMPLE_FRAC", resample_frac);\n')
    f.write('}')

with open('mrr_params.vh','w') as f:
    f.write('localparam SFO_CTR_LEN = {};\n'.format(SFO_CTR_LEN))
    f.write('localparam SFO_CTR_LEN_LOG2 = {};\n'.format(SFO_CTR_LEN_LOG2))
    f.write('localparam SFO_CTR_INCR = {};\n'.format(SFO_CTR_INCR))
    f.write('localparam JITTER_INCR = {};\n'.format(JITTER_INCR))
    f.write('localparam JITTER_MIN = {};\n'.format(JITTER_MIN))
    f.write('localparam MAX_CHIPS_PER_SYMBOL_LOG2 = {};\n'.format(MAX_CHIPS_PER_SYMBOL_LOG2))
    f.write('localparam CORR_WAIT_LEN_LOG2 = {};\n'.format(CORR_WAIT_LEN_LOG2))
    f.write('localparam ASSIGNMENT_SKIRT_WIDTH = {};\n'.format(ASSIGNMENT_SKIRT_WIDTH))
    f.write('localparam SKIRT_WIDTH = {};\n'.format(SKIRT_WIDTH))
    f.write('localparam SKIRT_WIDTH_LOG2 = {};\n'.format(SKIRT_WIDTH_LOG2))
    f.write('localparam RECHARGE_CYCLES = {};\n'.format(RECHARGE_CYCLES))
    f.write('localparam SYMBOL_CYCLES = {};\n'.format(SYMBOL_CYCLES))
    f.write('localparam ESAMP_WIDTH = {};\n'.format(ESAMP_WIDTH))
    f.write('localparam GLOBAL_SEARCH_LEN = {};\n'.format(GLOBAL_SEARCH_LEN))
    f.write('localparam GLOBAL_SEARCH_LEN_LOG2 = {};\n'.format(GLOBAL_SEARCH_LEN_LOG2))
    f.write('localparam PULSE_SEPARATION_LOG2 = {};\n'.format(PULSE_SEPARATION_LOG2))
    f.write('localparam PRIMARY_FFT_LEN = {};\n'.format(PRIMARY_FFT_LEN))
    f.write('localparam PRIMARY_FFT_LEN_LOG2 = {};\n'.format(PRIMARY_FFT_LEN_LOG2))
    f.write('localparam PRIMARY_FFT_LEN_DECIM_LOG2 = {};\n'.format(PRIMARY_FFT_LEN_DECIM_LOG2))
    f.write('localparam PRIMARY_FFT_WIDTH = {};\n'.format(PRIMARY_FFT_WIDTH))
    f.write('localparam PRIMARY_FFT_MAX_LEN = {};\n'.format(PRIMARY_FFT_MAX_LEN))
    f.write('localparam PRIMARY_FFT_MAX_LEN_LOG2 = {};\n'.format(PRIMARY_FFT_MAX_LEN_LOG2))
    f.write('localparam PRIMARY_FFT_MAX_LEN_LOG2_LOG2 = {};\n'.format(PRIMARY_FFT_MAX_LEN_LOG2_LOG2))
    f.write('localparam PRIMARY_FFT_DECIM_LOG2 = {};\n'.format(PRIMARY_FFT_DECIM_LOG2))
    f.write('localparam PRIMARY_FFT_DECIM = {};\n'.format(PRIMARY_FFT_DECIM))
    f.write('localparam PRIMARY_FFT_MAX_LEN_DECIM_LOG2 = {};\n'.format(PRIMARY_FFT_MAX_LEN_DECIM_LOG2))
    f.write('localparam PRIMARY_FFT_MAX_LEN_DECIM_LOG2_LOG2 = {};\n'.format(PRIMARY_FFT_MAX_LEN_DECIM_LOG2_LOG2))
    f.write('localparam SEARCH_COUNTER_LEN_LOG2 = {};\n'.format(SEARCH_COUNTER_LEN_LOG2))
    f.write('localparam SECONDARY_FFT_LEN = {};\n'.format(SECONDARY_FFT_LEN))
    f.write('localparam SECONDARY_FFT_LEN_LOG2 = {};\n'.format(SECONDARY_FFT_LEN_LOG2))
    f.write('localparam SECONDARY_FFT_MAX_LEN_LOG2 = {};\n'.format(SECONDARY_FFT_MAX_LEN_LOG2))
    f.write('localparam SECONDARY_FFT_MAX_LEN_LOG2_LOG2 = {};\n'.format(SECONDARY_FFT_MAX_LEN_LOG2_LOG2))
    f.write('localparam FFT_HIST_LEN = {};\n'.format(FFT_HIST_LEN))
    f.write('localparam FFT_HIST_LEN_LOG2 = {};\n'.format(FFT_HIST_LEN_LOG2))
    f.write('localparam FFT_HIST_LEN_DECIM = {};\n'.format(FFT_HIST_LEN_DECIM))
    f.write('localparam FFT_HIST_LEN_DECIM_LOG2 = {};\n'.format(FFT_HIST_LEN_DECIM_LOG2))
    f.write('localparam NUM_CORRELATORS = {};\n'.format(NUM_CORRELATORS))
    f.write('localparam NUM_CORRELATORS_LOG2 = {};\n'.format(NUM_CORRELATORS_LOG2))
    f.write('localparam NUM_METADATA = {};\n'.format(NUM_METADATA))
    f.write('localparam NUM_METADATA_LOG2 = {};\n'.format(NUM_METADATA_LOG2))
    f.write('localparam OVERSAMPLING_RATIO = {};\n'.format(OVERSAMPLING_RATIO))
    f.write('localparam OVERSAMPLING_RATIO_LOG2 = {};\n'.format(OVERSAMPLING_RATIO_LOG2))
    f.write('localparam NUM_DECODE_PATHWAYS = {};\n'.format(NUM_DECODE_PATHWAYS))
    f.write('localparam NUM_DECODE_PATHWAYS_LOG2 = {};\n'.format(NUM_DECODE_PATHWAYS_LOG2))
    f.write('localparam PN_SEQ_LEN = {};\n'.format(PN_SEQ_LEN))
    f.write('localparam PN_SEQ_LEN_LOG2 = {};\n'.format(PN_SEQ_LEN_LOG2))
    f.write('localparam SFO_INT_WIDTH = {};\n'.format(SFO_INT_WIDTH))
    f.write('localparam SFO_FRAC_WIDTH = {};\n'.format(SFO_FRAC_WIDTH))
    f.write('localparam SFO_FRAC_RANGE = {};\n'.format(SFO_FRAC_RANGE))
    f.write('localparam SFO_SEQ_LEN_LOG2 = {};\n'.format(SFO_SEQ_LEN_LOG2))
    f.write('localparam SFO_SEQ_LEN = {};\n'.format(SFO_SEQ_LEN))
    f.write('localparam NUM_HARMONICS = {};\n'.format(NUM_HARMONICS))
    f.write('localparam NUM_HARMONICS_LOG2 = {};\n'.format(NUM_HARMONICS_LOG2))
    f.write('localparam RESAMPLE_INT_WIDTH = {};\n'.format(RESAMPLE_INT_WIDTH))
    f.write('localparam RESAMPLE_FRAC_WIDTH = {};\n'.format(RESAMPLE_FRAC_WIDTH))
    f.write('localparam CORR_WIDTH = {};\n'.format(CORR_WIDTH))
    f.write('localparam CORR_EXPONENT_WIDTH = {};\n'.format(CORR_EXPONENT_WIDTH))
    f.write('localparam CORR_MANTISSA_WIDTH = {};\n'.format(CORR_MANTISSA_WIDTH))
    f.write('localparam CORR_METADATA_WIDTH = {};\n'.format(CORR_METADATA_WIDTH))
    f.write('localparam FFT_SHIFT_WIDTH = {};\n'.format(FFT_SHIFT_WIDTH))
    f.write('localparam [{}:0] SFO_INTS = {{{}}};\n'.format(NUM_CORRELATORS*SFO_INT_WIDTH-1,",".join(["16'd{}".format(int(sfo_vals[NUM_CORRELATORS-sfo_idx-1])) for sfo_idx in range(len(sfo_vals))])))
    f.write('localparam [{}:0] SFO_FRACS = {{{}}};\n'.format(NUM_CORRELATORS*SFO_FRAC_WIDTH-1,",".join(["16'd{}".format(int((sfo_vals[NUM_CORRELATORS-sfo_idx-1]*SFO_FRAC_RANGE) % SFO_FRAC_RANGE)) for sfo_idx in range(len(sfo_vals))])))
    f.write('localparam [{}:0] N1S = {{{}}};\n'.format(NUM_CORRELATORS*RESAMPLE_INT_WIDTH-1,",".join(["{}'d{}".format(RESAMPLE_INT_WIDTH,int(resampling_vals[NUM_CORRELATORS-rs_idx-1])) for rs_idx in range(len(resampling_vals))])))
    f.write('localparam [{}:0] N2S = {{{}}};\n'.format(NUM_CORRELATORS*RESAMPLE_FRAC_WIDTH-1,",".join(["{}'d{}".format(RESAMPLE_FRAC_WIDTH,int((resampling_vals[NUM_CORRELATORS-rs_idx-1]*RESAMPLE_FRAC_RANGE) % RESAMPLE_FRAC_RANGE)) for rs_idx in range(len(resampling_vals))])))

