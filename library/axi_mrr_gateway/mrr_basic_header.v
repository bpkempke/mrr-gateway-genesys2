/*************************** Overview ***************************
Main block, instantiating CFO, resample, correlation, findmax, loopback blocks
**************************End Overview *************************/
module mrr_basic_header 
#(
    parameter INDEX_WIDTH=23,
    parameter CORR_VAL_WIDTH=14,
    parameter FREQ_IDX_WIDTH=6,
    parameter CFO_WIDTH=8,
    parameter STEP_WIDTH=28,
    parameter PACKET_INDEX=10,
    parameter LOCAL_COUNTER_WIDTH=8
)(
clk,
rst,
threshold_in,
corr_threshold_in,
setting_num_harmonics,
setting_sfo_frac,
setting_sfo_int,
setting_resample_frac,
setting_resample_int,
setting_primary_fft_len,
setting_primary_fft_len_log2,
setting_primary_fft_len_mask,
setting_primary_fft_len_decim,
setting_primary_fft_len_decim_log2,
setting_primary_fft_len_decim_mask,
setting_secondary_fft_len_log2,
setting_secondary_fft_len_mask,
setting_secondary_fft_len_log2_changed,
i_tdata_i,
i_tdata_q,
i_tlast,
i_tvalid,
i_tready,
i_replay_tdata_i,
i_replay_tdata_q,
i_replay_tlast,
i_replay_empty,
i_replay_tvalid,
i_replay_tready,
i_tdata_fft_i,
i_tdata_fft_shift,
i_tdata_fft_shift_idx,
i_tdata_fft_shift_valid,
i_tlast_fft,
i_tvalid_fft,
i_tready_fft,
tx_word,
tx_en_out,
o_tkeep,
o_tdata,
o_tlast,
o_tvalid,
o_tready,
o_decoded_tdata,
o_decoded_tvalid,
o_decoded_tlast,
o_decoded_tready,
o_corr_tdata,
o_corr_tvalid,
o_corr_tlast,
o_corr_tready,
tx_disable,
num_payload_bits,
max_jitter,
recharge_len,
mf_num_accum,
mf_accum_len,
mf_settings_changed,
wait_step,
cur_time,
primary_fft_mask,
trigger_cfo_sfo_search,
iq_sync_req,
iq_sync_latest,
iq_sync_ack,
iq_flush_req,
iq_flush_done,
fft_sync_req,
fft_sync_latest,
fft_sync_ack,
corr_wait_len,
window_ram_write_en,
window_ram_write_data,
disable_sfo_it,
corr_div_ram_data,
corr_div_ram_write,
corr_div_ram_reset,
reset_diagnostic_counter,
readies,
valids,
cfo_search_debug_in,
cfo_search_debug
);

    `include "mrr_params.vh"

    input clk;
    input rst;
    input [CORR_VAL_WIDTH-1:0] threshold_in;
    input [CORR_VAL_WIDTH-1:0] corr_threshold_in;
    input [NUM_HARMONICS_LOG2-1:0] setting_num_harmonics;
    input [SFO_FRAC_WIDTH*NUM_CORRELATORS-1:0] setting_sfo_frac;
    input [SFO_INT_WIDTH*NUM_CORRELATORS-1:0] setting_sfo_int;
    input [RESAMPLE_FRAC_WIDTH*NUM_CORRELATORS-1:0] setting_resample_frac;
    input [RESAMPLE_INT_WIDTH*NUM_CORRELATORS-1:0] setting_resample_int;
    input [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_primary_fft_len;
    input [PRIMARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_primary_fft_len_log2;
    input [PRIMARY_FFT_MAX_LEN_LOG2-1:0] setting_primary_fft_len_mask;
    input [PRIMARY_FFT_MAX_LEN_DECIM_LOG2:0] setting_primary_fft_len_decim;
    input [PRIMARY_FFT_MAX_LEN_DECIM_LOG2_LOG2-1:0] setting_primary_fft_len_decim_log2;
    input [PRIMARY_FFT_MAX_LEN_DECIM_LOG2-1:0] setting_primary_fft_len_decim_mask;
    input [SECONDARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_secondary_fft_len_log2;
    input [SECONDARY_FFT_MAX_LEN_LOG2:0] setting_secondary_fft_len_mask;
    input setting_secondary_fft_len_log2_changed;
    input [15:0] i_tdata_i;
    input [15:0] i_tdata_q;
    input i_tlast;
    input i_tvalid;
    output i_tready;
    input [15:0] i_replay_tdata_i;
    input [15:0] i_replay_tdata_q;
    input i_replay_tlast;
    input i_replay_empty;
    input i_replay_tvalid;
    output i_replay_tready;
    input [15:0] i_tdata_fft_i;
    input [FFT_SHIFT_WIDTH-1:0] i_tdata_fft_shift;
    input [PRIMARY_FFT_MAX_LEN_DECIM_LOG2-1:0] i_tdata_fft_shift_idx;
    input i_tdata_fft_shift_valid;
    input i_tlast_fft;
    input i_tvalid_fft;
    output i_tready_fft;
    input [31:0] tx_word;
    output reg tx_en_out;
    output [NUM_DECODE_PATHWAYS-1:0] o_tkeep;
    output [32*NUM_DECODE_PATHWAYS-1:0] o_tdata;
    output [NUM_DECODE_PATHWAYS-1:0] o_tlast;
    output [NUM_DECODE_PATHWAYS-1:0] o_tvalid;
    input [NUM_DECODE_PATHWAYS-1:0] o_tready;
    output [32*NUM_DECODE_PATHWAYS-1:0] o_decoded_tdata;
    output [NUM_DECODE_PATHWAYS-1:0] o_decoded_tvalid;
    output [NUM_DECODE_PATHWAYS-1:0] o_decoded_tlast;
    input [NUM_DECODE_PATHWAYS-1:0] o_decoded_tready;
    output [31:0] o_corr_tdata;
    output o_corr_tvalid;
    output o_corr_tlast;
    input o_corr_tready;
    input tx_disable;
    input [7:0] num_payload_bits;
    input [7:0] max_jitter;
    input [14:0] recharge_len;
    input [3:0] mf_num_accum;
    input [7:0] mf_accum_len;
    input mf_settings_changed;
    input [15:0] wait_step;
    input [63:0] cur_time;
    input [PRIMARY_FFT_MAX_LEN-1:0] primary_fft_mask;
    input trigger_cfo_sfo_search;
    output iq_sync_req;
    output iq_sync_latest;
    input iq_sync_ack;
    output iq_flush_req;
    input iq_flush_done;
    output fft_sync_req;
    output fft_sync_latest;
    input fft_sync_ack;
    input [CORR_WAIT_LEN_LOG2-1:0] corr_wait_len;
    input window_ram_write_en;
    input [PRIMARY_FFT_WIDTH-1:0] window_ram_write_data;
    input disable_sfo_it;
    input [CORR_WIDTH-1:0] corr_div_ram_data;
    input corr_div_ram_write;
    input corr_div_ram_reset;

    //Debug stuff
    input reset_diagnostic_counter;
    output [5:0] readies;
    output [5:0] valids;
    input [31:0] cfo_search_debug_in;
    output [159:0] cfo_search_debug;

    /***************Internal Signal Assignment*************/
    
    wire [NUM_DECODE_PATHWAYS*ESAMP_WIDTH-1:0] es, sfo_es;
    wire [NUM_DECODE_PATHWAYS-1:0] fmFlag;
    wire [NUM_DECODE_PATHWAYS-1:0] tx_en;
    
    wire [NUM_DECODE_PATHWAYS-1:0] do_op;
    wire [NUM_DECODE_PATHWAYS-1:0] header_ready;
    wire [NUM_DECODE_PATHWAYS-1:0] detector_reset;
    wire [NUM_DECODE_PATHWAYS-1:0] correlation_done;
    wire [NUM_DECODE_PATHWAYS-1:0] pathway_reset;
    wire [NUM_DECODE_PATHWAYS-1:0] currently_decoding;
    
    wire [NUM_DECODE_PATHWAYS-1:0] cfo_tvalid,cfo_tready,cfo_tlast,cfo_tkeep,cfo_replay_flag,cfo_corr_replay_flag;
    wire [NUM_DECODE_PATHWAYS-1:0] sfo_tvalid,sfo_tready,sfo_tlast,sfo_tkeep;
    wire [CORR_WIDTH*NUM_DECODE_PATHWAYS-1:0] cfo_assignment_corr;
    wire [CORR_METADATA_WIDTH*NUM_DECODE_PATHWAYS-1:0] cfo_assignment_metadata;
    wire [RESAMPLE_INT_WIDTH*NUM_DECODE_PATHWAYS-1:0] cfo_assignment_n1;
    wire [RESAMPLE_FRAC_WIDTH*NUM_DECODE_PATHWAYS-1:0] cfo_assignment_n2;
    wire [PRIMARY_FFT_MAX_LEN_LOG2*NUM_DECODE_PATHWAYS-1:0] cfo_assignment_cfo_idx;

    //This block parses incoming fft (magnitude) data and basically just implements max hold for now
    mrr_cfo_fft_interpreter #(
        .CORR_VAL_WIDTH(CORR_VAL_WIDTH)
    ) inst_CFO (
        .clk(clk),
        .rst(rst),
        .IDataIn(i_tdata_i),
        .QDataIn(i_tdata_q),
        .i_tvalid(i_tvalid),
        .i_tlast(i_tlast),
        .i_tready(i_tready),
        .IReplayDataIn(i_replay_tdata_i),
        .QReplayDataIn(i_replay_tdata_q),
        .i_replay_tvalid(i_replay_tvalid),
        .i_replay_empty(i_replay_empty),
        .i_replay_tlast(i_replay_tlast),
        .i_replay_tready(i_replay_tready),
        .i_tlast_fft(i_tlast_fft),
        .i_tvalid_fft(i_tvalid_fft),
        .i_tready_fft(i_tready_fft),
        .o_tready(cfo_tready),
        .o_tvalid(cfo_tvalid),
        .o_tlast(cfo_tlast),
        .o_tkeep(cfo_tkeep),
        .o_corr_tdata(o_corr_tdata),
        .o_corr_tvalid(o_corr_tvalid),
        .o_corr_tlast(o_corr_tlast),
        .o_corr_tready(o_corr_tready),
        .correlation_done(correlation_done),
        .iq_sync_req(iq_sync_req),
        .iq_sync_latest(iq_sync_latest),
        .iq_sync_ack(iq_sync_ack),
        .iq_flush_req(iq_flush_req),
        .iq_flush_done(iq_flush_done),
        .fft_sync_req(fft_sync_req),
        .fft_sync_latest(fft_sync_latest),
        .fft_sync_ack(fft_sync_ack),
        .o_pathway_reset(pathway_reset),
        .o_replay_flag(cfo_replay_flag),
        .o_corr_replay_flag(cfo_corr_replay_flag),
        .o_header_ready(header_ready),
        .mf_num_accum(mf_num_accum),
        .mf_accum_len(mf_accum_len),
        .mf_settings_changed(mf_settings_changed),
        .trigger_search(trigger_cfo_sfo_search),
        .FFTDataIn(i_tdata_fft_i),
        .FFTDataInShift(i_tdata_fft_shift),
        .FFTDataInShiftIdx(i_tdata_fft_shift_idx),
        .FFTDataInShiftValid(i_tdata_fft_shift_valid),
        .threshold_in(threshold_in),
        .corr_threshold_in(corr_threshold_in),
        .detector_reset(detector_reset),
        .currently_decoding(currently_decoding),
        .primary_fft_mask(primary_fft_mask),
        .es_final(es),
        .out_assignment_corr(cfo_assignment_corr),
        .out_assignment_metadata(cfo_assignment_metadata),
        .out_assignment_n1(cfo_assignment_n1),
        .out_assignment_n2(cfo_assignment_n2),
        .out_assignment_cfo_idx(cfo_assignment_cfo_idx),
        .setting_num_harmonics(setting_num_harmonics),
        .setting_sfo_frac(setting_sfo_frac),
        .setting_sfo_int(setting_sfo_int),
        .setting_resample_frac(setting_resample_frac),
        .setting_resample_int(setting_resample_int),
        .setting_primary_fft_len(setting_primary_fft_len),
        .setting_primary_fft_len_log2(setting_primary_fft_len_log2),
        .setting_primary_fft_len_mask(setting_primary_fft_len_mask),
        .setting_primary_fft_len_decim(setting_primary_fft_len_decim),
        .setting_primary_fft_len_decim_log2(setting_primary_fft_len_decim_log2),
        .setting_primary_fft_len_decim_mask(setting_primary_fft_len_decim_mask),
        .setting_secondary_fft_len_log2(setting_secondary_fft_len_log2),
        .setting_secondary_fft_len_mask(setting_secondary_fft_len_mask),
        .setting_secondary_fft_len_log2_changed(setting_secondary_fft_len_log2_changed),
        .reset_diagnostic_counter(reset_diagnostic_counter),
        .window_ram_write_en(window_ram_write_en),
        .window_ram_write_data(window_ram_write_data),
        .corr_div_ram_data(corr_div_ram_data),
        .corr_div_ram_write(corr_div_ram_write),
        .corr_div_ram_reset(corr_div_ram_reset),
        .debug_in(cfo_search_debug_in),
        .debug(cfo_search_debug)
    ); 

    genvar pathway_idx;
    generate 
        for (pathway_idx = 0; pathway_idx < NUM_DECODE_PATHWAYS; pathway_idx = pathway_idx + 1) begin

            /***************End Internal Signal Assignment*************/
            
            assign do_op[pathway_idx] = i_tvalid & i_tready;

            mrr_correlation inst_cor (
                .clk(clk),
                .rst(rst | pathway_reset[pathway_idx]),
                .rst_corr_state(detector_reset[pathway_idx]),
                .i_tdata(es[ESAMP_WIDTH*(pathway_idx+1)-1-:ESAMP_WIDTH]),
                .i_tkeep(cfo_tkeep[pathway_idx]),
                .i_tvalid(cfo_tvalid[pathway_idx]),
                .i_tready(cfo_tready[pathway_idx]),
                .i_tlast(cfo_tlast[pathway_idx]),
                .i_replay_flag(cfo_corr_replay_flag[pathway_idx]),
                .i_replay_header_flag(cfo_replay_flag[pathway_idx]),
                .o_tvalid(sfo_tvalid[pathway_idx]),
                .o_tready(sfo_tready[pathway_idx]),
                .o_tlast(sfo_tlast[pathway_idx]),
                .o_tkeep(sfo_tkeep[pathway_idx]),
                .o_tdata(sfo_es[ESAMP_WIDTH*(pathway_idx+1)-1-:ESAMP_WIDTH]),
                .syncd_flag(fmFlag[pathway_idx]),
                .correlation_done(correlation_done[pathway_idx]),
                .max_jitter(max_jitter),
                .recharge_len(recharge_len),
                .corr_wait_len(corr_wait_len),
                .header_ready(header_ready[pathway_idx])
            ); 
        
            mrr_loopback_bpk #(.PACKET_INDEX(PACKET_INDEX)) inst_lb (
                .clk(clk),
                .rst(rst | pathway_reset[pathway_idx]),
                .setting_primary_fft_len(setting_primary_fft_len),
                .setting_primary_fft_len_log2(setting_primary_fft_len_log2),
                .tx_disable(tx_disable),
                .wait_step(wait_step),
                .tx_word(tx_word),
                .num_payload_bits(num_payload_bits),
                .max_jitter(max_jitter),
                .cfo_idx({cfo_assignment_cfo_idx[PRIMARY_FFT_MAX_LEN_LOG2*(pathway_idx+1)-1-:PRIMARY_FFT_MAX_LEN_LOG2]}),
                .sfo_idx({cfo_assignment_n2[RESAMPLE_FRAC_WIDTH*(pathway_idx+1)-1-:RESAMPLE_FRAC_WIDTH],cfo_assignment_n1[RESAMPLE_INT_WIDTH*(pathway_idx+1)-1-:RESAMPLE_INT_WIDTH]}),
                .cur_time(cur_time),
                .cur_corr(cfo_assignment_corr[CORR_WIDTH*(pathway_idx+1)-1-:CORR_WIDTH]),
                .cur_metadata(cfo_assignment_metadata[CORR_METADATA_WIDTH*(pathway_idx+1)-1-:CORR_METADATA_WIDTH]),
                .fm_flag(fmFlag[pathway_idx]),
                .recharge_len(recharge_len),
                .i_tdata(sfo_es[ESAMP_WIDTH*(pathway_idx+1)-1-:ESAMP_WIDTH]),
                .i_tvalid(sfo_tvalid[pathway_idx]),
                .i_tlast(sfo_tlast[pathway_idx]),
                .i_tkeep(sfo_tkeep[pathway_idx]),
                .i_tready(sfo_tready[pathway_idx]),
                .i_replay_flag(cfo_replay_flag[pathway_idx]),
                .o_tdata(o_tdata[32*(pathway_idx+1)-1-:32]),
                .o_tlast(o_tlast[pathway_idx]),
                .o_tvalid(o_tvalid[pathway_idx]),
                .o_tready(o_tready[pathway_idx]),
                .o_tkeep(o_tkeep[pathway_idx]),
                .o_decoded_tdata(o_decoded_tdata[32*(pathway_idx+1)-1-:32]),
                .o_decoded_tvalid(o_decoded_tvalid[pathway_idx]),
                .o_decoded_tlast(o_decoded_tlast[pathway_idx]),
                .o_decoded_tready(o_decoded_tready[pathway_idx]),
                .currently_decoding(currently_decoding[pathway_idx]),
                .detector_reset(detector_reset[pathway_idx]),
                .disable_sfo_it(disable_sfo_it),
                .tx_en(tx_en[pathway_idx])
            );

        end
    endgenerate

    integer tx_en_idx;
    always @* begin
        tx_en_out = 1'b0;
        for(tx_en_idx=0; tx_en_idx<NUM_DECODE_PATHWAYS; tx_en_idx=tx_en_idx+1) begin
            tx_en_out = tx_en_out | tx_en[tx_en_idx];
        end
    end

    assign readies = {i_tready_fft, i_tready, o_tready, o_decoded_tready, cfo_tready, sfo_tready};
    assign valids = {i_tvalid_fft, i_tvalid, o_tvalid, o_decoded_tvalid, cfo_tvalid, sfo_tvalid};

endmodule
