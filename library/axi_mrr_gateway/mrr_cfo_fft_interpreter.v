/***************************** Overview ***************************************
 * mrr_cfo_fft_interpreter:
 *  This block takes as input successive FFTs from the baseband IQ data stream.
 *  The FFT's length is chosen to be the closest power of two to the MRR's
 *  baseband sampling clock (pulse width), equivalent to searching all possible
 *  CFOs.  The FFT magnitude histories are stored in a RAM block for occasional
 *  recall during header detection.  The new header detection paradigm consists
 *  of transmitting a number of pulses with a constant repetition frequency.
 *  This allows for efficient detection through the use of a secondary FFT step
 *  across successive CFO FFTs.  This is repeated for each CFO and independent
 *  correlators keep track of the correlation for each possible SFO over the
 *  required search range.
**************************** End Overview ************************************/


module mrr_cfo_fft_interpreter
#(
    parameter WIDTH = 16,
    parameter CORR_VAL_WIDTH=14,
    parameter CWIDTH = 32,
    parameter ZWIDTH = 24,
    parameter MAX_FFT_SIZE_LOG2 = 12
)(
clk,
rst,
IDataIn,
QDataIn,
i_tvalid,
i_tlast,
i_tready,
IReplayDataIn,
QReplayDataIn,
i_replay_tvalid,
i_replay_empty,
i_replay_tlast,
i_replay_tready,
i_tvalid_fft,
i_tlast_fft,
i_tready_fft,
o_tready,
o_tvalid,
o_tlast,
o_tkeep,
o_corr_tdata,
o_corr_tvalid,
o_corr_tlast,
o_corr_tready,
correlation_done,
iq_sync_req,
iq_sync_latest,
iq_sync_ack,
iq_flush_req,
iq_flush_done,
fft_sync_req,
fft_sync_latest,
fft_sync_ack,
o_pathway_reset,
o_replay_flag,
o_corr_replay_flag,
o_header_ready,
detector_reset,
currently_decoding,
FFTDataIn, //In-phase contains the magnitude data
FFTDataInShift,
FFTDataInShiftIdx,
FFTDataInShiftValid,
mf_num_accum,
mf_accum_len,
mf_settings_changed,
trigger_search,
threshold_in,
primary_fft_mask,
es_final,
out_assignment_corr,
out_assignment_metadata,
out_assignment_n1,
out_assignment_n2,
out_assignment_cfo_idx,
setting_sfo_frac,
setting_sfo_int,
setting_resample_frac,
setting_resample_int,
setting_num_harmonics,
setting_primary_fft_len,
setting_primary_fft_len_log2,
setting_primary_fft_len_mask,
setting_primary_fft_len_decim,
setting_primary_fft_len_decim_log2,
setting_primary_fft_len_decim_mask,
setting_secondary_fft_len_log2,
setting_secondary_fft_len_mask,
setting_secondary_fft_len_log2_changed,
debug
);

`include "mrr_params.vh"

input clk;
input rst;
input [15:0] IDataIn;
input [15:0] QDataIn;
input i_tvalid;
input i_tlast;
output i_tready;
input [15:0] IReplayDataIn;
input [15:0] QReplayDataIn;
input i_replay_tvalid;
input i_replay_empty;
input i_replay_tlast;
output reg i_replay_tready;
input i_tvalid_fft;
input i_tlast_fft;
output i_tready_fft;
input [NUM_DECODE_PATHWAYS-1:0] o_tready;
output [NUM_DECODE_PATHWAYS-1:0] o_tvalid;
output [NUM_DECODE_PATHWAYS-1:0] o_tlast;
output [NUM_DECODE_PATHWAYS-1:0] o_tkeep;
output [31:0] o_corr_tdata;
output o_corr_tvalid;
output o_corr_tlast;
input o_corr_tready;
input [NUM_DECODE_PATHWAYS-1:0] correlation_done;
output reg [NUM_DECODE_PATHWAYS-1:0] o_pathway_reset;
output reg [NUM_DECODE_PATHWAYS-1:0] o_replay_flag;
output reg [NUM_DECODE_PATHWAYS-1:0] o_corr_replay_flag;
input [NUM_DECODE_PATHWAYS-1:0] o_header_ready;
input currently_decoding;
input detector_reset;
output reg iq_sync_req;
output reg iq_sync_latest;
input iq_sync_ack;
output reg iq_flush_req;
input iq_flush_done;
output reg fft_sync_req;
output reg fft_sync_latest;
input fft_sync_ack;
input [15:0] FFTDataIn; //In-phase contains the magnitude data
input [FFT_SHIFT_WIDTH-1:0] FFTDataInShift;
input [PRIMARY_FFT_MAX_LEN_DECIM_LOG2-1:0] FFTDataInShiftIdx;
input FFTDataInShiftValid;
input [3:0] mf_num_accum;
input [7:0] mf_accum_len;
input mf_settings_changed;
input trigger_search;
input [CORR_VAL_WIDTH-1:0] threshold_in;
input [PRIMARY_FFT_MAX_LEN-1:0] primary_fft_mask;
output [ESAMP_WIDTH*NUM_DECODE_PATHWAYS-1:0] es_final;
output [CORR_WIDTH*NUM_DECODE_PATHWAYS-1:0] out_assignment_corr;
output [CORR_METADATA_WIDTH*NUM_DECODE_PATHWAYS-1:0] out_assignment_metadata;
output [RESAMPLE_INT_WIDTH*NUM_DECODE_PATHWAYS-1:0] out_assignment_n1;
output [RESAMPLE_FRAC_WIDTH*NUM_DECODE_PATHWAYS-1:0] out_assignment_n2;
output [PRIMARY_FFT_MAX_LEN_LOG2*NUM_DECODE_PATHWAYS-1:0] out_assignment_cfo_idx;
input [SFO_FRAC_WIDTH*NUM_CORRELATORS-1:0] setting_sfo_frac;
input [SFO_INT_WIDTH*NUM_CORRELATORS-1:0] setting_sfo_int;
input [RESAMPLE_FRAC_WIDTH*NUM_CORRELATORS-1:0] setting_resample_frac;
input [RESAMPLE_INT_WIDTH*NUM_CORRELATORS-1:0] setting_resample_int;
input [NUM_HARMONICS_LOG2-1:0] setting_num_harmonics;
input [SECONDARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_secondary_fft_len_log2;
input [SECONDARY_FFT_MAX_LEN_LOG2:0] setting_secondary_fft_len_mask;
input setting_secondary_fft_len_log2_changed;
input [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_primary_fft_len;
input [PRIMARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_primary_fft_len_log2;
input [PRIMARY_FFT_MAX_LEN_LOG2-1:0] setting_primary_fft_len_mask;
input [PRIMARY_FFT_MAX_LEN_DECIM_LOG2:0] setting_primary_fft_len_decim;
input [PRIMARY_FFT_MAX_LEN_DECIM_LOG2_LOG2-1:0] setting_primary_fft_len_decim_log2;
input [PRIMARY_FFT_MAX_LEN_DECIM_LOG2-1:0] setting_primary_fft_len_decim_mask;
output [63:0] debug;

//Historic primary FFT samples are stored in RAM.
// Once a number of samples corresponding to the length of the
// header search space is reached, the historic samples are
// fed through the secondary FFT to determine SFO frequency

//**** Historic FFT RAM: ****

wire [PRIMARY_FFT_MAX_LEN_LOG2-1:0] cfo_index, cfo_index_preshift;
reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] cfo_index_reversed;
reg [SECONDARY_FFT_MAX_LEN_LOG2-1:0] secondary_fft_write_idx;
wire [PRIMARY_FFT_MAX_LEN_DECIM_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] fft_hist_write_idx;
reg [PRIMARY_FFT_MAX_LEN_DECIM_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] fft_hist_read_idx;
wire [PRIMARY_FFT_WIDTH-1:0] fft_hist_read_data;
wire do_op_fft_in = i_tready_fft & i_tvalid_fft;
wire last_secondary_sample = ((fft_hist_read_idx & setting_secondary_fft_len_mask) == setting_secondary_fft_len_mask);
reg reset_state;
reg load_from_dram;
reg [PRIMARY_FFT_MAX_LEN_DECIM_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] dram_load_ctr;

reg [NUM_CORRELATORS_LOG2-1:0] correlator_shift_counter;
reg [PRIMARY_FFT_MAX_LEN-1:0] primary_fft_mask_shift;

//Incoming samples are fed in bit-reversed order.  Undo this behavior through
// reversing the write index.
reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] primary_fft_write_idx;
assign fft_hist_write_idx = {({{{PRIMARY_FFT_MAX_LEN_LOG2}{1'b0}},secondary_fft_write_idx} & setting_secondary_fft_len_mask) << setting_primary_fft_len_decim_log2} | {primary_fft_write_idx & setting_primary_fft_len_decim_mask};
genvar bit_idx;
for(bit_idx=0; bit_idx < PRIMARY_FFT_MAX_LEN_LOG2; bit_idx = bit_idx + 1) begin
    assign cfo_index_preshift[bit_idx] = cfo_index_reversed[PRIMARY_FFT_MAX_LEN_LOG2-bit_idx-1];
end
assign cfo_index = cfo_index_preshift >> (PRIMARY_FFT_MAX_LEN_LOG2-setting_primary_fft_len_log2);

reg correlator_shift_out;
reg correlator_shift_reset;
wire [FFT_SHIFT_WIDTH-1:0] shift_read;
reg [3:0] correlator_shift_phase;
reg [CORR_MANTISSA_WIDTH-1:0] correlation_out_shift [NUM_CORRELATORS-1:0];
reg [CORR_METADATA_WIDTH-1:0] metadata_out_shift [NUM_CORRELATORS-1:0];
wire [CORR_WIDTH-1:0] cur_corr = {{{CORR_WIDTH-CORR_MANTISSA_WIDTH}{1'b0}},correlation_out_shift[0]};
wire [CORR_METADATA_WIDTH-1:0] cur_metadata = metadata_out_shift[0];
localparam CORR_SHIFT_PHASE_INCR = 0;
localparam CORR_SHIFT_PHASE_READ = 1;
localparam CORR_SHIFT_PHASE_READ2 = 2;
localparam CORR_SHIFT_PHASE_WRITE = 4;

//Output correlator values in real-time
reg [31:0] corr_max, corr_temp;
reg corr_valid;
wire first_cfo_flag = (cfo_index == 0);
assign o_corr_tdata = {first_cfo_flag, corr_max[30:0]};
assign o_corr_tvalid = corr_valid;
assign o_corr_tlast = 1'b1;//(cfo_index == setting_primary_fft_len-1);

//Only output max across correlators
wire corr_valid_temp = (correlator_shift_out & (correlator_shift_phase == CORR_SHIFT_PHASE_WRITE));
wire corr_last_temp = (correlator_shift_counter == NUM_CORRELATORS-1);
wire [31:0] corr_max_temp = (cur_corr > corr_temp) ? cur_corr : corr_temp;
always @(posedge clk) begin
    if(rst) begin
        corr_max <= 0;
        corr_temp <= 0;
        corr_valid <= 1'b0;
    end else begin
        corr_valid <= 1'b0;
        if(corr_valid_temp) begin
            corr_temp <= corr_max_temp;
            if(corr_last_temp) begin
                corr_max <= corr_temp;
                corr_temp <= 0;
                corr_valid <= 1'b1;
            end
        end
    end
end

//ram_2port has the following behavior:
// IF ena/enb == 1'b1:
//   when wea/web is asserted, ram is written on immediately upon clock positive transition
//   when wea/web is deasserted, doa/dob is updated with read value from ram upon clock positive transition
wire [PRIMARY_FFT_MAX_LEN_DECIM_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] read_address = 
    ((fft_hist_read_idx & setting_secondary_fft_len_mask) << setting_primary_fft_len_decim_log2) | 
    (fft_hist_read_idx >> setting_secondary_fft_len_log2);

wire [PRIMARY_FFT_WIDTH-1:0] write_data;
assign write_data = (detector_reset) ? 0 : FFTDataIn;

ram_2port #(.DWIDTH(FFT_SHIFT_WIDTH), .AWIDTH(PRIMARY_FFT_MAX_LEN_DECIM_LOG2)) ram_2port_inst2 (
    .clka(clk),
    .ena(1'b1),
    .wea(FFTDataInShiftValid),
    .addra(FFTDataInShiftIdx & setting_primary_fft_len_decim_mask),
    .dia(FFTDataInShift),
    .doa(),

    .clkb(clk),
    .enb(1'b1),
    .web(1'b0),
    .addrb(cfo_index_reversed & setting_primary_fft_len_decim_mask),
    .dib(),
    .dob(shift_read)
);

ram_2port #(.DWIDTH(PRIMARY_FFT_WIDTH), .AWIDTH(PRIMARY_FFT_MAX_LEN_DECIM_LOG2+SECONDARY_FFT_MAX_LEN_LOG2)) ram_2port_inst (
    .clka(clk), 
    .ena(1'b1),
    .wea(do_op_fft_in), 
    .addra(fft_hist_write_idx),
    .dia(write_data), //TODO: Needs to be deafened to avoid infinite loopback
    .doa(),

    .clkb(clk),
    .enb(1'b1),
    .web(1'b0),
    .addrb(read_address),
    .dib(),
    .dob(fft_hist_read_data)
);

//Another RAM block is used to store raw baseband samples so that they can be
// replayed at the correct resampled rate after the SFO search is done and a
// candidate SFO meets the required threshold.

reg [PRIMARY_FFT_MAX_LEN_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] historic_sample_counter;
wire [15:0] replay_data_q, replay_data_i;
assign replay_data_q = QReplayDataIn;
assign replay_data_i = IReplayDataIn;
wire do_op_iq_in = i_tready & i_tvalid;

//Secondary FFT step is used to search for SFO frequency through
// coherent integration through each candidate SFO frequency's harmonics

reg fft_i_done;
wire fft_i_tready;
wire fft_i_tvalid = ~reset_state & ~fft_i_done;
wire fft_i_tlast = last_secondary_sample;
wire update_historical_read_idx = fft_i_tvalid & fft_i_tready;

wire [63:0] fft_o_tdata;
wire        fft_o_tlast;
wire        fft_o_tvalid;
wire        fft_o_tready;
wire [15:0] fft_o_tuser;

wire [39:0] mag_phase_o_tdata;
wire        mag_phase_o_tlast;
wire        mag_phase_o_tvalid;
reg         mag_phase_o_tready;

//FFT configuration parameters
wire [7:0] secondary_fft_size_log2   = setting_secondary_fft_len_log2;        // Set FFT size
wire secondary_fft_direction         = 0;                       // Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
wire [11:0] secondary_fft_scale      = 12'b011010101010;        // Conservative scaling of 1/N
// Padding of the control word depends on the FFT options enabled
wire [31:0] secondary_fft_ctrl_word  = {11'd0, secondary_fft_scale, secondary_fft_direction, secondary_fft_size_log2};
reg secondary_fft_config_tvalid;
wire secondary_fft_config_tready;

reg rst_fft;
axi_fft_un inst_axi_fft (
    .aclk(clk), .aresetn(~rst_fft),
    .s_axis_data_tvalid(fft_i_tvalid),
    .s_axis_data_tready(fft_i_tready),
    .s_axis_data_tlast(fft_i_tlast),
    .s_axis_data_tdata({16'd0,fft_hist_read_data}),
    .m_axis_data_tvalid(fft_o_tvalid),
    .m_axis_data_tready(fft_o_tready),
    .m_axis_data_tlast(fft_o_tlast),
    .m_axis_data_tdata(fft_o_tdata),
    .m_axis_data_tuser(fft_o_tuser), // FFT index
    .s_axis_config_tdata(secondary_fft_ctrl_word[15:0]),
    .s_axis_config_tvalid(secondary_fft_config_tvalid),
    .s_axis_config_tready(secondary_fft_config_tready));

wire fft_abs_tvalid;
wire fft_abs_tlast;
wire fft_abs_tready;
wire [31:0] fft_abs_tdata;
complex_to_mag_approx #(
    .SAMP_WIDTH(32)
) inst_sfo_mag (
    .clk(clk),
    .reset(rst),
    .clear(1'b0),
    .i_tvalid(fft_o_tvalid),
    .i_tlast(fft_o_tlast),
    .i_tready(fft_o_tready),
    .i_tdata(fft_o_tdata),
    .o_tvalid(fft_abs_tvalid),
    .o_tlast(fft_abs_tlast),
    .o_tready(fft_abs_tready),
    .o_tdata(fft_abs_tdata)
);

//FFT output comes out in bit-reversed indexing order.  This block reorders FFT
// data based on this indexing (provided by fft_o_tuser)
wire fft_size_log2_tready;
wire [31:0] fft_shift_o_tdata;
wire fft_shift_o_tlast;
wire fft_shift_o_tvalid;
wire fft_shift_o_tready;
wire [SECONDARY_FFT_MAX_LEN_LOG2-1:0] sfo_fft_idx_pre;
wire [SECONDARY_FFT_MAX_LEN_LOG2-1:0] sfo_fft_idx;
reg [SECONDARY_FFT_MAX_LEN_LOG2-1:0] sfo_fft_idx_reversed;
genvar sfo_bit_idx;
for(sfo_bit_idx=0; sfo_bit_idx < SECONDARY_FFT_MAX_LEN_LOG2; sfo_bit_idx = sfo_bit_idx + 1) begin
    assign sfo_fft_idx_pre[sfo_bit_idx] = sfo_fft_idx_reversed[SECONDARY_FFT_MAX_LEN_LOG2-sfo_bit_idx-1];
end
assign sfo_fft_idx = (sfo_fft_idx_pre >> (SECONDARY_FFT_MAX_LEN_LOG2-setting_secondary_fft_len_log2));
fft_shift #(
    .MAX_FFT_SIZE_LOG2(SECONDARY_FFT_MAX_LEN_LOG2),
    .WIDTH(32)
) fft_shift_instance (
    .clk(clk),
    .reset(rst),
    .fft_size_log2_tdata(setting_secondary_fft_len_log2),
    .fft_size_log2_tvalid(secondary_fft_config_tvalid),
    .fft_size_log2_tready(fft_size_log2_tready),
    .i_tdata(fft_abs_tdata),
    .i_tlast(fft_abs_tlast),
    .i_tvalid(fft_abs_tvalid),
    .i_tready(fft_abs_tready),
    .i_tuser(sfo_fft_idx),
    .o_tdata(fft_shift_o_tdata),
    .o_tlast(fft_shift_o_tlast),
    .o_tvalid(fft_shift_o_tvalid),
    .o_tready(fft_shift_o_tready) 
);

always @(posedge clk) begin
    if(rst) begin
        sfo_fft_idx_reversed <= 0;
    end else begin
        if(fft_abs_tvalid & fft_abs_tready) begin
            if(fft_abs_tlast) begin
                sfo_fft_idx_reversed <= 0;
            end else begin
                sfo_fft_idx_reversed <= sfo_fft_idx_reversed + 1;
            end
        end
    end
end

assign mag_phase_o_tdata = fft_shift_o_tdata;
assign mag_phase_o_tvalid = fft_shift_o_tvalid;
assign mag_phase_o_tlast = fft_shift_o_tlast;
assign fft_shift_o_tready = mag_phase_o_tready | reset_state;

//No buffering here, so we have a 1:1 input:output ratio
assign i_tready_fft = load_from_dram;

reg [CORR_WIDTH-1:0] max_value_temp;
reg [CORR_WIDTH-1:0] max_value_global;
reg [CORR_METADATA_WIDTH-1:0] max_metadata;

reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] z_counter [NUM_DECODE_PATHWAYS-1:0];
wire [NUM_DECODE_PATHWAYS-1:0] i_tkeep;

//Pathways are assigned the NUM_DECODE_PATHWAYS highest correlations among the 
// potential CFOs
reg [CORR_WIDTH-1:0] pathway_assignment_corr [NUM_DECODE_PATHWAYS-1:0];
reg [CORR_METADATA_WIDTH-1:0] pathway_assignment_metadata [NUM_DECODE_PATHWAYS-1:0];
reg [RESAMPLE_INT_WIDTH-1:0] pathway_assignment_n1 [NUM_DECODE_PATHWAYS-1:0];
reg [RESAMPLE_FRAC_WIDTH-1:0] pathway_assignment_n2 [NUM_DECODE_PATHWAYS-1:0];
reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] pathway_assignment_cfo_idx [NUM_DECODE_PATHWAYS-1:0];
reg [NUM_DECODE_PATHWAYS_LOG2-1:0] assignment_array_addr;
wire [NUM_DECODE_PATHWAYS-1:0] o_tkeep_buf;

//Multiple mixer/matched filter combinations for all downstream 
// processing pathways
genvar pathway_idx;
generate 
    for (pathway_idx = 0; pathway_idx < NUM_DECODE_PATHWAYS; pathway_idx = pathway_idx + 1) begin
        assign out_assignment_corr[(pathway_idx+1)*CORR_WIDTH-1-:CORR_WIDTH] = pathway_assignment_corr[pathway_idx];
        assign out_assignment_metadata[(pathway_idx+1)*CORR_METADATA_WIDTH-1-:CORR_METADATA_WIDTH] = pathway_assignment_metadata[pathway_idx];
        assign out_assignment_n1[(pathway_idx+1)*RESAMPLE_INT_WIDTH-1-:RESAMPLE_INT_WIDTH] = pathway_assignment_n1[pathway_idx];
        assign out_assignment_n2[(pathway_idx+1)*RESAMPLE_FRAC_WIDTH-1-:RESAMPLE_FRAC_WIDTH] = pathway_assignment_n2[pathway_idx];
        assign out_assignment_cfo_idx[(pathway_idx+1)*PRIMARY_FFT_MAX_LEN_LOG2-1-:PRIMARY_FFT_MAX_LEN_LOG2] = pathway_assignment_cfo_idx[pathway_idx];

        wire [WIDTH-1:0] to_cordic_i_pre = (o_replay_flag[pathway_idx]) ? replay_data_i : IDataIn;
        wire [WIDTH-1:0] to_cordic_q_pre = (o_replay_flag[pathway_idx]) ? replay_data_q : QDataIn;
        wire to_cordic_flag = (o_replay_flag[pathway_idx]) ? i_replay_tvalid : do_op_iq_in;

        wire [CWIDTH-1:0] to_cordic_i, to_cordic_q;
        wire [CWIDTH-1:0] i_cordic, q_cordic;

        assign o_tkeep[pathway_idx] = (o_replay_flag[pathway_idx]) ? i_tkeep[pathway_idx] : o_tkeep_buf;
        
        sign_extend #(.bits_in(WIDTH), .bits_out(CWIDTH)) sign_extend_cordic_i_m (.in(to_cordic_i_pre), .out(to_cordic_i));
        sign_extend #(.bits_in(WIDTH), .bits_out(CWIDTH)) sign_extend_cordic_q_m (.in(to_cordic_q_pre), .out(to_cordic_q));

        wire cordic_flag;
        m_cordic_z24 #(.bitwidth(CWIDTH)) inst_cordic(
            .clock(clk),
            .reset(rst),
            .enable(1'b1),
            .xi(to_cordic_i),
            .yi(to_cordic_q),
            .zi({{{{ZWIDTH-PRIMARY_FFT_MAX_LEN_LOG2}{1'b0}},z_counter[pathway_idx]} << (ZWIDTH-setting_primary_fft_len_log2)}),
            .flag_in(to_cordic_flag),
            .xo(i_cordic),
            .yo(q_cordic),
            .zo(),
            .flag_out(cordic_flag)
        );
        
        mrr_cfo_mf_es #(
            .ES_OUT_WIDTH(ESAMP_WIDTH)
        ) inst_mf (
            .clk(clk),
            .rst(rst),
            .enable(cordic_flag),
            .setting_num_accum(mf_num_accum),
            .setting_accum_len_log2(mf_accum_len),
            .accum_settings_changed(mf_settings_changed),
            .i_tdata(i_cordic),
            .q_tdata(q_cordic),
            .Es(es_final[(pathway_idx+1)*ESAMP_WIDTH-1-:ESAMP_WIDTH])
        );

        m_resample inst_resample(
            .clk(clk),
            .rst(rst),
            .n1(pathway_assignment_n1[pathway_idx]),
            .n2(16'h8000),
            .n3({1'b0,pathway_assignment_n2[pathway_idx]}),
            .decim(1 << (setting_primary_fft_len_log2 - setting_primary_fft_len_decim_log2)),
            .i_tlast(i_tlast),
            .i_tvalid(cordic_flag),//(o_replay_flag[pathway_idx]) ? cordic_flag : i_tvalid),
            .i_tready(),
            .o_tlast(),
            .o_tvalid(i_tkeep[pathway_idx]),
            .o_tready(1'b1)
        );
    end
endgenerate

//A number of correlators are used to track the fit of various
// SFO offsets based on magnitude data from the secondary FFT
//TODO: Only feed in the first half of the FFT
reg correlation_search_reset;
reg correlators_reset, correlators_reset_last;
wire correlation_update = mag_phase_o_tvalid;//TODO:??? & ~correlators_reset_last; //TODO: This is a bug with magsq block... should revisit since this is a bug in the magsq block...
wire [CORR_MANTISSA_WIDTH-1:0] correlation_out [NUM_CORRELATORS-1:0];
wire [CORR_METADATA_WIDTH-1:0] metadata_out [NUM_CORRELATORS-1:0];
wire [NUM_CORRELATORS-1:0] correlation_out_valid;

//Directly correlated to the correlator assignemnts are the corresponding n1,n2
//resampler assignments (architected as a ROM)
wire [RESAMPLE_INT_WIDTH-1:0] resample_n1_params_rom [NUM_CORRELATORS-1:0];
wire [RESAMPLE_FRAC_WIDTH-1:0] resample_n2_params_rom [NUM_CORRELATORS-1:0];
genvar correlator_idx;
generate
    for (correlator_idx = 0; correlator_idx < NUM_CORRELATORS; correlator_idx = correlator_idx + 1) begin
        sfo_fft_correlator #(
            .FFT_LEN_LOG2(SECONDARY_FFT_MAX_LEN_LOG2),
            .POWER_WIDTH(CORR_WIDTH)
        ) inst_sfo_correlator(
            .clk(clk),
            .reset(rst),
            .sfo_int_part(setting_sfo_int[(correlator_idx+1)*SFO_INT_WIDTH-1-:SFO_INT_WIDTH]),
            .sfo_frac_part(setting_sfo_frac[(correlator_idx+1)*SFO_FRAC_WIDTH-1-:SFO_FRAC_WIDTH]),
            .setting_num_harmonics(setting_num_harmonics),
            .correlation_reset(correlators_reset),
            .correlation_update(correlation_update),
            .fft_mag_in(mag_phase_o_tdata),
            .correlation_out(correlation_out[correlator_idx]),
            .metadata_out(metadata_out[correlator_idx]),
            .correlation_out_valid(correlation_out_valid[correlator_idx])
        );

        assign resample_n1_params_rom[correlator_idx] = setting_resample_int[(correlator_idx+1)*RESAMPLE_INT_WIDTH-1-:RESAMPLE_INT_WIDTH];
        assign resample_n2_params_rom[correlator_idx] = setting_resample_frac[(correlator_idx+1)*RESAMPLE_FRAC_WIDTH-1-:RESAMPLE_FRAC_WIDTH];
    end
endgenerate


reg [7:0] state, next_state;
reg cfo_index_reset;
reg cfo_index_incr;
reg assignment_array_addr_incr;
reg historic_sample_counter_reset;
reg historic_sample_counter_incr;
reg store_pathway_assignment;
reg global_search_idx_reset;
reg global_search_idx_incr;
reg reset_dram_ctr;
reg [GLOBAL_SEARCH_LEN_LOG2-1:0] global_search_idx;
reg [NUM_CORRELATORS_LOG2-1:0] max_sfo_idx;
reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] max_cfo_idx;

parameter STATE_IDLE  = 0;
parameter STATE_LOAD_FROM_DRAM = 1;
parameter STATE_START = 2;
parameter STATE_WAIT_NORMALIZATION = 3;
parameter STATE_TRACK_MAX = 4;
parameter STATE_INCREMENT_CFO_IDX = 5;
parameter STATE_THRESHOLD_REACHED = 6;
parameter STATE_REPLAY_CORR_SAMPLES = 7;
parameter STATE_WAIT_CORR_DONE = 8;
parameter STATE_REPLAY_HEADER_SAMPLES = 9;
parameter STATE_SYNC_ALL_SAMPLES = 10;
parameter STATE_SYNC_ALL_SAMPLES2 = 11;
parameter STATE_SYNC_ALL_SAMPLES3 = 12;
parameter STATE_INCREMENT_PATHWAY_IDX = 13;
parameter STATE_SYNC_FFT_SAMPLES = 14;

always @(posedge clk) begin
  if(rst_fft) begin
      secondary_fft_config_tvalid <= 1'b1;
  end else begin
      //Upon reset, we need to re-configure the FFT block.  This consists of
      // asserting the config_tvalid flag until the configuration has been
      // loaded
      if(setting_secondary_fft_len_log2_changed) begin
          secondary_fft_config_tvalid <= 1'b1;
      end else if(secondary_fft_config_tready & fft_size_log2_tready) begin
          secondary_fft_config_tvalid <= 0;
      end
  end
end

reg rst_last;
wire rst_fft_pre = (rst | setting_secondary_fft_len_log2_changed);
always @(posedge clk) begin
    rst_last <= rst_fft_pre;
    rst_fft <= rst_fft_pre | rst_last;
end

integer rst_idx;
integer idx;
always @(posedge clk) begin
    if(rst | mf_settings_changed) begin
        max_value_temp <= 0;
        max_value_global <= 0;
        fft_hist_read_idx <= 0;
        fft_i_done <= 0;
        cfo_index_reversed <= 0;
        max_cfo_idx <= 0;
        max_sfo_idx <= 0;
        historic_sample_counter <= 0;
        assignment_array_addr <= 0;
        correlator_shift_counter <= 0;
        correlators_reset_last <= 1'b0;
        primary_fft_write_idx <= 0;
        primary_fft_mask_shift <= 0;
        secondary_fft_write_idx <= 0;
        global_search_idx <= 0;
        correlator_shift_phase <= CORR_SHIFT_PHASE_INCR;
        dram_load_ctr <= 0;
        state <= STATE_IDLE;
        for(rst_idx=0; rst_idx<NUM_DECODE_PATHWAYS; rst_idx=rst_idx+1) begin
            pathway_assignment_n1[rst_idx] <= 0;
            pathway_assignment_n2[rst_idx] <= 0;
            pathway_assignment_cfo_idx[rst_idx] <= 0;
            pathway_assignment_corr[rst_idx] <= 0;
            pathway_assignment_metadata[rst_idx] <= 0;
            z_counter[rst_idx] <= 0;
        end
        for(rst_idx=0; rst_idx<NUM_CORRELATORS; rst_idx=rst_idx+1) begin
            correlation_out_shift[rst_idx] <= 0;
            metadata_out_shift[rst_idx] <= 0;
        end
    end else begin
        state <= next_state;

        if(reset_state) begin
            fft_hist_read_idx <= 0;
        end

        if(reset_dram_ctr) begin
            dram_load_ctr <= 0;
        end else if(load_from_dram & i_tvalid_fft) begin
            dram_load_ctr <= dram_load_ctr + 1;
        end

        correlators_reset_last <= correlators_reset;

        if(global_search_idx_reset) begin
            global_search_idx <= 0;
            max_value_global <= 0;
        end else if(global_search_idx_incr) begin
            global_search_idx <= global_search_idx + 1;
            if(max_value_temp > max_value_global)
                max_value_global <= max_value_temp;
        end

        if(historic_sample_counter_reset) begin
            historic_sample_counter <= 0;
        end else if(historic_sample_counter_incr) begin
            historic_sample_counter <= historic_sample_counter + 1;
        end

        if(correlation_search_reset) begin
            max_value_temp <= 0;
            correlator_shift_phase <= CORR_SHIFT_PHASE_READ;
        end
        if(correlator_shift_out) begin
            if(correlator_shift_phase == CORR_SHIFT_PHASE_READ) begin
                correlator_shift_phase <= CORR_SHIFT_PHASE_READ2;
            end else if(correlator_shift_phase == CORR_SHIFT_PHASE_READ2) begin
                correlator_shift_phase <= CORR_SHIFT_PHASE_WRITE;
            end else if(correlator_shift_phase == CORR_SHIFT_PHASE_WRITE) begin
                $display("corr = %d", cur_corr);
                if((cur_corr > max_value_temp) && primary_fft_mask_shift[0]) begin
                    max_value_temp <= cur_corr;
                    max_metadata <= cur_metadata;
                    max_sfo_idx <= correlator_shift_counter;
                    max_cfo_idx <= cfo_index;
                end
                for(idx=0; idx<NUM_CORRELATORS-1; idx=idx+1) begin
                    correlation_out_shift[idx] <= correlation_out_shift[idx+1];
                    metadata_out_shift[idx] <= metadata_out_shift[idx+1];
                end
                correlator_shift_phase <= CORR_SHIFT_PHASE_INCR;
            end else begin
                correlator_shift_counter <= correlator_shift_counter + 1;
                correlator_shift_phase <= CORR_SHIFT_PHASE_READ;
            end
        end else if(correlator_shift_reset) begin
            correlator_shift_counter <= 0;
            for(idx=0; idx<NUM_CORRELATORS; idx=idx+1) begin
                correlation_out_shift[idx] <= correlation_out[idx];
                metadata_out_shift[idx] <= metadata_out[idx];
            end
        end

        //Update historical FFT read index upon request
        if(update_historical_read_idx) begin
            fft_hist_read_idx <= fft_hist_read_idx + 1;
            if(fft_hist_read_idx == ({{{{SECONDARY_FFT_MAX_LEN_LOG2}{1'b0}}, setting_primary_fft_len_decim_mask} << setting_secondary_fft_len_log2} | setting_secondary_fft_len_mask)) begin
                fft_i_done <= 1'b1;
            end
        end
        if(reset_state) begin
            fft_i_done <= 1'b0;
        end

        //FFT samples are continuously stored into historical array
        // in order to allow for samples to buffer while performing 
        // an SFO search.
        if(reset_dram_ctr) begin
            primary_fft_write_idx <= 0;
            secondary_fft_write_idx <= 0;
        end else if(do_op_fft_in) begin
            primary_fft_write_idx <= primary_fft_write_idx + 1;
            if((primary_fft_write_idx & setting_primary_fft_len_decim_mask) == setting_primary_fft_len_decim_mask) begin
                secondary_fft_write_idx <= secondary_fft_write_idx + 1;
            end
        end

        if(cfo_index_reset) begin
            cfo_index_reversed <= 0;
            primary_fft_mask_shift <= primary_fft_mask;
        end else if(cfo_index_incr) begin
            cfo_index_reversed <= cfo_index_reversed + 1;
            primary_fft_mask_shift <= {primary_fft_mask_shift[0], primary_fft_mask_shift[PRIMARY_FFT_MAX_LEN-1:1]};
        end

        if(assignment_array_addr_incr) begin
            if(assignment_array_addr == NUM_DECODE_PATHWAYS-1)
                assignment_array_addr <= 0;
            else
                assignment_array_addr <= assignment_array_addr + 1;
        end

        if(store_pathway_assignment) begin
            pathway_assignment_n1[assignment_array_addr] <= resample_n1_params_rom[max_sfo_idx];
            pathway_assignment_n2[assignment_array_addr] <= resample_n2_params_rom[max_sfo_idx];
            pathway_assignment_cfo_idx[assignment_array_addr] <= max_cfo_idx;
            pathway_assignment_corr[assignment_array_addr] <= max_value_temp;
            pathway_assignment_metadata[assignment_array_addr] <= max_metadata;
            $display("n1 = %d, n2 = %d, cfo_idx = %d", resample_n1_params_rom[max_sfo_idx], resample_n2_params_rom[max_sfo_idx], max_cfo_idx);
        end
        
        for(idx=0; idx<NUM_DECODE_PATHWAYS; idx=idx+1) begin
            if(do_op_iq_in | (o_replay_flag[idx] & i_replay_tvalid)) begin
                z_counter[idx] <= z_counter[idx] - pathway_assignment_cfo_idx[idx];
            end
        end
    end
end

// Logic for keeping track of SFO search state
always @* begin
    next_state = state;
    reset_state = 1'b0;
    cfo_index_reset = 1'b0;
    cfo_index_incr = 1'b0;
    assignment_array_addr_incr = 1'b0;
    historic_sample_counter_reset = 1'b0;
    historic_sample_counter_incr = 1'b0;
    correlator_shift_out = 1'b0;
    correlator_shift_reset = 1'b1;
    o_replay_flag = 0;
    o_corr_replay_flag = 0;
    correlation_search_reset = 1'b0;
    correlators_reset = 1'b0;
    store_pathway_assignment = 1'b0;
    mag_phase_o_tready = 1'b0;
    global_search_idx_reset = 1'b0;
    global_search_idx_incr = 1'b0;
    o_pathway_reset = 0;
    load_from_dram = 1'b0;
    iq_sync_req = 1'b0;
    iq_sync_latest = 1'b0;
    iq_flush_req = 1'b0;
    fft_sync_req = 1'b0;
    fft_sync_latest = 1'b0;
    reset_dram_ctr = 1'b0;
    i_replay_tready = 1'b0;
    
    case(state)

        //During idle, wait for trigger from filled historical FFT array
        STATE_IDLE: begin
            //Every time SECONDARY_FFT_LEN samples have been 
            // stored, kick off the SFO search (secondary FFT)
            cfo_index_reset = 1'b1;
            reset_state = 1'b1;
            reset_dram_ctr = 1'b1;
            correlation_search_reset = 1'b1;
            correlators_reset = 1'b1;
            global_search_idx_reset = (~currently_decoding) & trigger_search;
            if(trigger_search)
                next_state = STATE_SYNC_FFT_SAMPLES;
        end

        STATE_SYNC_FFT_SAMPLES: begin
            reset_state = 1'b1;
            reset_dram_ctr = 1'b1;
            fft_sync_req = 1'b1;
            if(fft_sync_ack)
                next_state = STATE_LOAD_FROM_DRAM;
        end

        STATE_LOAD_FROM_DRAM: begin
            reset_state = 1'b1;
            load_from_dram = 1'b1;
            if((dram_load_ctr == (({{{SECONDARY_FFT_MAX_LEN_LOG2}{1'b0}},setting_primary_fft_len_decim_mask} << setting_secondary_fft_len_log2) | setting_secondary_fft_len_mask)) & do_op_fft_in)
                next_state = STATE_START;
        end

        //Two steps accomplished here: feed samples into FFT and update
        // correlators upon FFT completion
        STATE_START: begin
            mag_phase_o_tready = 1'b1;
            if(mag_phase_o_tlast & mag_phase_o_tvalid)
                next_state = STATE_WAIT_NORMALIZATION;
        end

        STATE_WAIT_NORMALIZATION: begin
            if(correlation_out_valid[NUM_CORRELATORS-1])
                next_state = STATE_TRACK_MAX;
        end

        //Once an entire FFT has been read, shift out correlator output,
        // keeping track of the peak correlation.  
        STATE_TRACK_MAX: begin
            correlator_shift_out = o_corr_tready;
            correlator_shift_reset = 1'b0;
            if((o_corr_tready == 1'b1) && (correlator_shift_counter == NUM_CORRELATORS-1) && (correlator_shift_phase == CORR_SHIFT_PHASE_INCR))
                next_state = STATE_INCREMENT_CFO_IDX;
        end

        //If we haven't visited all CFOs, continue on to the next.
        // If we have, determine whether any correlators have met the
        // given correlation threshold.  If so, proceed.  If not, restart
        // the header search.
        STATE_INCREMENT_CFO_IDX: begin
            correlators_reset = 1'b1;
            cfo_index_incr = 1'b1;
            reset_dram_ctr = 1'b1;
            if(cfo_index_reversed == setting_primary_fft_len-1) begin
                global_search_idx_incr = global_search_idx < GLOBAL_SEARCH_LEN;
                if((global_search_idx == 0) && (max_value_temp > threshold_in))
                    next_state = STATE_THRESHOLD_REACHED;
                else if((global_search_idx > 0) && (global_search_idx < GLOBAL_SEARCH_LEN) && (max_value_temp > max_value_global))
                    next_state = STATE_THRESHOLD_REACHED;
                else
                    next_state = STATE_SYNC_ALL_SAMPLES2;
            end else begin
                if(cfo_index_reversed[PRIMARY_FFT_MAX_LEN_DECIM_LOG2-1:0] == setting_primary_fft_len_decim_mask) begin
                    next_state = STATE_LOAD_FROM_DRAM;
                end else begin
                    next_state = STATE_START;
                end
            end
        end

        //In case a threshold has been reached, notify all downstream 
        // processing pipelines to expect a flood of historic data (after
        // matched filtering) for them to subsequently search time offset
        STATE_THRESHOLD_REACHED: begin
            store_pathway_assignment = 1'b1;
            historic_sample_counter_reset = 1'b1;
            o_pathway_reset[assignment_array_addr] = 1'b1;
            next_state = STATE_REPLAY_CORR_SAMPLES;
        end

        //Once the processing pathways have been notified, push out stored
        // samples until each has been caught up to real-time. Past this point,
        // CORDICs will be fed directly with incoming samples. No historic data. 
        STATE_REPLAY_CORR_SAMPLES: begin
            historic_sample_counter_incr = i_replay_tvalid;
            i_replay_tready = 1'b1;
            o_corr_replay_flag[assignment_array_addr] = 1'b1;
            o_replay_flag[assignment_array_addr] = 1'b1;
            if(historic_sample_counter == ({{{SECONDARY_FFT_MAX_LEN_LOG2}{1'b0}},setting_primary_fft_len_mask} << setting_secondary_fft_len_log2 | setting_secondary_fft_len_mask))
                next_state = STATE_WAIT_CORR_DONE;
        end

        STATE_WAIT_CORR_DONE: begin
            o_replay_flag[assignment_array_addr] = 1'b1;
            if(correlation_done[assignment_array_addr])
                next_state = STATE_REPLAY_HEADER_SAMPLES;
        end

        STATE_REPLAY_HEADER_SAMPLES: begin
            i_replay_tready = 1'b1;
            historic_sample_counter_incr = o_header_ready[assignment_array_addr];
            o_replay_flag[assignment_array_addr] = 1'b1;
            if(i_replay_empty & ~i_replay_tvalid)  
                next_state = STATE_INCREMENT_PATHWAY_IDX;
        end

        STATE_INCREMENT_PATHWAY_IDX: begin
            assignment_array_addr_incr = 1'b1;
            next_state = STATE_SYNC_ALL_SAMPLES;
        end

        STATE_SYNC_ALL_SAMPLES: begin
            iq_flush_req = 1'b1;
            i_replay_tready = 1'b1;
            if(iq_flush_done)
                next_state = STATE_SYNC_ALL_SAMPLES2;
        end

        STATE_SYNC_ALL_SAMPLES2: begin
            reset_state = 1'b1; //TODO: This is necessary to keep a consistent number of samples fed to FFT.  Should be a dedicated flag possibly for this purpose?
            iq_sync_req = 1'b1;
            iq_sync_latest = 1'b1;
            i_replay_tready = 1'b1;
            if(iq_sync_ack)
                next_state = STATE_SYNC_ALL_SAMPLES3;
        end

        STATE_SYNC_ALL_SAMPLES3: begin
            reset_state = 1'b1;
            fft_sync_req = 1'b1;
            fft_sync_latest = 1'b1;
            if(fft_sync_ack)
                next_state = STATE_IDLE;
        end
       
    endcase
end

//Artifical delay of 20 cycles to account for CORDIC delay
reg [20:0] do_op_iq_in_delay;
always @(posedge clk) begin
    if(rst) begin
        do_op_iq_in_delay <= 0;
    end else begin
        do_op_iq_in_delay <= {do_op_iq_in_delay[19:0], do_op_iq_in};
    end
end

//We need a FIFO to keep track of the multiple bits of flags currently in-process inside the CORDIC
wire [15:0] cordic_fifo_space;
axi_fifo #(
    .WIDTH(NUM_DECODE_PATHWAYS*2),
    .SIZE(6)
) cordic_fifo (
    .clk(clk),
    .reset(rst),
    .clear(1'b0),
    .i_tdata({i_tkeep,{{NUM_DECODE_PATHWAYS}{i_tlast}}}),
    .i_tvalid(do_op_iq_in_delay[20]),
    .i_tready(),
    .o_tdata({o_tkeep_buf,o_tlast}),
    .o_tvalid(o_tvalid),
    .o_tready(o_tready),
    .space(cordic_fifo_space)
);

//Only allow for more incoming samples if there is at least 16 spaces free in FIFO (latency of CORDIC)
assign i_tready = (cordic_fifo_space > 16);

assign debug = {cordic_fifo_space, global_search_idx, state};

endmodule

