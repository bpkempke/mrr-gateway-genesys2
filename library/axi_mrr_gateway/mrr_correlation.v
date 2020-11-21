/*************************** Overview *****************************************
The functionality of correlation block is the find the maximum correlation
value.  Baseband and carrier frequency offsets are assumed to have already been
applied prior to input to this block.  The correlator has been implemented here
using a block ram. There is one block ram storing a complete copy (32768) of
data, 31 shift registers, each of which stores a "necessary" portion of data.
For example, shift_reg1 stores the data portion from 1421 to 1427, because
these are the possible time indices for the first pulse among 31 frequency
hypotheses. In this way, the correlation block won't use too much resource, but
can be fast enough for our use. One thing to do is that carrier frequency index
should be included here just like baseband frequency index.
**************************End Overview ****************************************/
module mrr_correlation
#(
    parameter CORR_VAL_WIDTH = 14,
    parameter NUM_RAKE_PULSES = 31,
    parameter RAKE_IDX_WIDTH = 15, //2^15 = 32768
    parameter AWIDTH = 15, //2^15 = 32768
    parameter SMAX = 31,
    parameter FREQ_IDX_WIDTH = 6 //64
)(clk, rst, max_jitter, recharge_len, rst_corr_state, i_tdata, i_tkeep, i_tvalid, i_tlast, i_tready, i_replay_flag, i_replay_header_flag, o_tready, o_tvalid, o_tlast, o_tkeep, o_tdata, syncd_flag, correlation_done, header_ready, corr_wait_len);

`include "mrr_params.vh"

localparam HIST_LEN_LOG2 = SFO_SEQ_LEN_LOG2 + OVERSAMPLING_RATIO_LOG2 + MAX_CHIPS_PER_SYMBOL_LOG2;
localparam FRAC_WIDTH = 16;

input clk;
input rst;
input [7:0] max_jitter;
input[14:0] recharge_len;
input rst_corr_state;
input [ESAMP_WIDTH-1:0] i_tdata;
input i_tkeep;
input i_tvalid;
input i_tlast;
output i_tready;
input i_replay_flag;
input i_replay_header_flag;
input o_tready;
output o_tvalid;
output o_tlast;
output o_tkeep;
output [ESAMP_WIDTH-1:0] o_tdata;
output reg syncd_flag;
output reg correlation_done;
output reg header_ready;
input [CORR_WAIT_LEN_LOG2-1:0] corr_wait_len;

//NOTE ON FUNCTIONALITY:
//  Every time a valid CFO/SFO lock is verified by the higher-level search, the
//  cfo transitions to replaying samples by asserting i_replay_flag.  Next, a
//  flood of replayed power-domain samples is fed to this correlation block at
//  a rate that is correctly resampled using the cfo_tkeep flag.  It is the
//  duty of this block to: 
//
//    1) Determine the symbol-level time offset of the initial header pulse train
//       (16'b0000000000000000)
//    2) Determine the bit-level time offset of the following PN sequence 
//       (15'b000100110101111)

assign i_tready = o_tready;
assign o_tvalid = i_tvalid;
assign o_tlast = i_tlast;
assign o_tkeep = i_tkeep;
assign o_tdata = i_tdata;

wire do_op_in = i_replay_flag & i_tkeep;
wire do_op_in_header = i_replay_header_flag & i_tkeep;
reg [HIST_LEN_LOG2-1:0] write_hist_addr;
reg [HIST_LEN_LOG2-1:0] max_training_sequence_offset, delay_counter;
reg ingest_and_increment;

reg [HIST_LEN_LOG2-1:0] cur_training_sequence_int, cur_sequence_start, start_training_sequence_int;
reg [MAX_CHIPS_PER_SYMBOL_LOG2+OVERSAMPLING_RATIO_LOG2-1:0] cur_training_sequence_offset;
reg [ESAMP_WIDTH+SFO_SEQ_LEN_LOG2-1:0] cur_training_sequence_accum, max_training_sequence_accum;
reg [HIST_LEN_LOG2-1:0] jitter_offset, jitter_max_offset, jitter_offset_delayed;
wire [HIST_LEN_LOG2-1:0] read_hist_addr = cur_training_sequence_int + jitter_offset;
wire [ESAMP_WIDTH-1:0] read_hist_data;
reg [ESAMP_WIDTH-1:0] jitter_max_corr;

wire [HIST_LEN_LOG2-1:0] sfo_int = ({{{HIST_LEN_LOG2-15}{1'b0}},recharge_len}+2)<<OVERSAMPLING_RATIO_LOG2;//Fixed due to resampling upstream

ram_2port #(.DWIDTH(ESAMP_WIDTH), .AWIDTH(HIST_LEN_LOG2)) mf_hist (
    .clka(clk),
    .ena(1'b1),
    .wea(ingest_and_increment),
    .addra(write_hist_addr),
    .dia(i_tdata),
    .doa(),

    .clkb(clk),
    .enb(1'b1),
    .web(1'b0),
    .addrb(read_hist_addr),
    .dib(),
    .dob(read_hist_data)
);

reg [3:0] state, next_state;
reg reset_write_hist_addr;
reg reset_training_sequence_search;
reg reset_training_sequence_indices;
reg training_sequence_next_addr;
reg training_offset_incr;
reg store_highest_correlation;
reg increment_delay_counter;
reg increment_jitter_offset;
reg increment_jitter_offset_delayed;
reg reset_jitter_offset;

parameter STATE_IDLE                       = 0;
parameter STATE_INGEST_HISTORICAL_SAMPLES  = 1;
parameter STATE_SEARCH_TRAINING_SEQUENCE1  = 2;
parameter STATE_SEARCH_TRAINING_SEQUENCE1_BUBBLE  = 3;
parameter STATE_SEARCH_TRAINING_SEQUENCE1B = 4;
parameter STATE_SEARCH_TRAINING_SEQUENCE2  = 5;
parameter STATE_WAIT_SYNCD                 = 6;
parameter STATE_ASSERT_SYNCD_FLAG          = 7;

always @(posedge clk) begin
    if(rst) begin
        state <= STATE_IDLE;
        write_hist_addr <= 0;
        cur_training_sequence_offset <= 0;
        cur_training_sequence_accum <= 0;
        cur_training_sequence_int <= 0;
        cur_sequence_start <= 0;
        max_training_sequence_offset <= 0;
        max_training_sequence_accum <= 0;
        start_training_sequence_int <= 0;
        delay_counter <= 0;
        jitter_offset <= 0;
        jitter_offset_delayed <= 0;
        jitter_max_corr <= 0;
        jitter_max_offset <= 0;
        increment_jitter_offset_delayed <= 0;
    end else begin
        state <= next_state;

	//During replay, write_hist_addr keeps track of an incrementing address
	// into local RAM
        if(reset_write_hist_addr) begin
            write_hist_addr <= 0;
        end else if(ingest_and_increment) begin
            write_hist_addr <= write_hist_addr + 1;
        end

        //Logic to keep track of timing given a certain amount of allowable jitter
        if(reset_jitter_offset) begin
            jitter_offset <= ~max_jitter + 1;
            jitter_max_corr <= 0;
            jitter_max_offset <= 0;
        end else if(increment_jitter_offset) begin
            jitter_offset <= jitter_offset + max_jitter;
        end

        if(increment_jitter_offset_delayed) begin
            if(read_hist_data > jitter_max_corr) begin
                jitter_max_corr <= read_hist_data;
                jitter_max_offset <= jitter_offset_delayed;
            end
        end
        increment_jitter_offset_delayed <= increment_jitter_offset;
        jitter_offset_delayed <= jitter_offset;

	//Logic to take care of address indexing into historical data.  The SFO
	//  is used (sfo_int and sfo_frac) to provide the proper stride length
	//  through the historical data.  The search is performed multiple
	//  times with varying time offsets (cur_training_sequence_offset)
        if(reset_training_sequence_search) begin
            cur_training_sequence_offset <= 0;
            cur_training_sequence_accum <= 0;
            max_training_sequence_offset <= 0;
            max_training_sequence_accum <= 0;
            start_training_sequence_int <= write_hist_addr - sfo_int;
            delay_counter <= 0;
        end
        if(reset_training_sequence_indices) begin
            cur_training_sequence_int <= start_training_sequence_int + cur_training_sequence_offset;
            cur_sequence_start        <= start_training_sequence_int + cur_training_sequence_offset + sfo_int;
        end else if(training_sequence_next_addr) begin
            cur_training_sequence_int <= cur_training_sequence_int - sfo_int + jitter_max_offset;
        end
        if(training_offset_incr) begin
            cur_training_sequence_offset <= cur_training_sequence_offset + 1;
        end

	//Accumulator keeps track of correlation for the current time offset
        if(training_offset_incr) begin
            cur_training_sequence_accum <= 0;
        end else if(training_sequence_next_addr) begin
            cur_training_sequence_accum <= cur_training_sequence_accum + jitter_max_corr;
        end
        if(store_highest_correlation) begin
            max_training_sequence_offset <= cur_sequence_start - write_hist_addr;
            max_training_sequence_accum <= cur_training_sequence_accum;
        end

        if(increment_delay_counter) begin
            delay_counter <= delay_counter + 1;
        end
    end
end

always @* begin
    next_state = state;
    ingest_and_increment = 1'b0;
    increment_jitter_offset = 1'b0;
    reset_jitter_offset = 1'b0;
    reset_write_hist_addr = 1'b0;
    reset_training_sequence_search = 1'b0;
    training_sequence_next_addr = 1'b0;
    store_highest_correlation = 1'b0;
    training_offset_incr = 1'b0;
    syncd_flag = 1'b0;
    increment_delay_counter = 1'b0;
    header_ready = 1'b0;
    correlation_done = 1'b0;
    reset_training_sequence_indices = 1'b0;

    case(state)

	//Wait for i_replay_flag symbolizing the reception of a valid
	// training sequence reception with valid CFO/SFO offset
        STATE_IDLE: begin
            reset_write_hist_addr = 1'b1;
            if(i_replay_flag) begin
                next_state = STATE_INGEST_HISTORICAL_SAMPLES;
            end
        end

	//Fill historical array with power-domain samples until i_replay_flag
	// is de-asserted.  Incoming samples are framed with the i_tkeep flag
	// which should provide a 4x oversampling above the pulse width.
        STATE_INGEST_HISTORICAL_SAMPLES: begin
            ingest_and_increment = do_op_in;
            reset_training_sequence_search = 1'b1;
            reset_training_sequence_indices = 1'b1;
            reset_jitter_offset = 1'b1;
            if(~i_replay_flag) begin
                next_state = STATE_SEARCH_TRAINING_SEQUENCE1;
            end
        end

	//Once historical data has been loaded locally, we need to determine
	// the time offset of the training sequence (modulo the symbol period).
	// At a 4x oversampling rate and 34 chips per symbol, this results in
	// 136 different possible symbol-level time offsets.
        STATE_SEARCH_TRAINING_SEQUENCE1: begin
            increment_jitter_offset = 1'b1;
            if((jitter_offset[HIST_LEN_LOG2-1] == 1'b0) && (jitter_offset > max_jitter/2)) begin
                next_state = STATE_SEARCH_TRAINING_SEQUENCE1_BUBBLE;
            end
        end

        STATE_SEARCH_TRAINING_SEQUENCE1_BUBBLE: begin
            next_state = STATE_SEARCH_TRAINING_SEQUENCE1B;
        end

        STATE_SEARCH_TRAINING_SEQUENCE1B: begin
            training_sequence_next_addr = 1'b1;
            reset_jitter_offset = 1'b1;
            if(cur_training_sequence_int <= (sfo_int + max_jitter)) begin
                next_state = STATE_SEARCH_TRAINING_SEQUENCE2;
            end else begin
                next_state = STATE_SEARCH_TRAINING_SEQUENCE1;
            end
        end

	//Indices are incremented and max correlation is tracked in this state,
	// exiting upon completion.
        STATE_SEARCH_TRAINING_SEQUENCE2: begin
            training_offset_incr = 1'b1;
            store_highest_correlation = (cur_training_sequence_accum > max_training_sequence_accum);
            reset_training_sequence_indices = 1'b1;
            if(cur_training_sequence_offset < sfo_int) begin
                next_state = STATE_SEARCH_TRAINING_SEQUENCE1;
            end else begin
                next_state = STATE_WAIT_SYNCD;
            end
        end

	//Wait until it's the next synchronized symbol until asserting a flag
	// for downstream logic indicating CFO, SFO, and time offsets are all
	// locked
        STATE_WAIT_SYNCD: begin
            correlation_done = 1'b1;
            increment_delay_counter = do_op_in_header;
            header_ready = 1'b1;
            if(delay_counter == ({corr_wait_len,{{OVERSAMPLING_RATIO_LOG2}{1'b0}}} + max_training_sequence_offset)) begin
                next_state = STATE_ASSERT_SYNCD_FLAG;
            end
        end

	//Alert downstream processing that a header has been detected and
	// time-synchronized by asserting fm_flag.
        STATE_ASSERT_SYNCD_FLAG: begin
            correlation_done = 1'b1;
            syncd_flag = 1'b1;
            header_ready = 1'b1;
            if(~i_replay_header_flag) begin
                next_state = STATE_IDLE;
            end
        end
    endcase
end

endmodule
