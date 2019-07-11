module mrr_loopback_bpk
#(
    parameter PACKET_INDEX = 10,
    parameter SPP = 64,
    parameter CWIDTH = 32,
    parameter ZWIDTH = 24,
    parameter PN_SEQ = 15'b000100110101111
)(clk, rst, tx_disable, wait_step, tx_word, num_payload_bits, max_jitter, recharge_len, fm_flag, i_tdata, i_tvalid, i_tlast, i_tkeep, i_replay_flag, i_tready, o_tdata, o_tlast, o_tvalid, o_tready, o_tkeep, o_decoded_tdata, o_decoded_tvalid, o_decoded_tlast, o_decoded_tready, cfo_idx, sfo_idx, cur_time, cur_corr, cur_metadata, currently_decoding, detector_reset, setting_primary_fft_len, setting_primary_fft_len_log2, tx_en);

    `include "mrr_params.vh"

    input clk; 
    input rst;
    input tx_disable; 
    input[15:0] wait_step;
    input[31:0] tx_word; 
    input[7:0] num_payload_bits;
    input[7:0] max_jitter;
    input[14:0] recharge_len;
    input fm_flag; 

    input [ESAMP_WIDTH-1:0] i_tdata;
    input i_tvalid;
    input i_tlast;
    input i_tkeep;
    input i_replay_flag;
    output i_tready;

    output[31:0] o_tdata; 
    output o_tlast; 
    output o_tvalid; 
    input o_tready; 
    output reg o_tkeep;

    output [31:0] o_decoded_tdata;
    output reg o_decoded_tvalid;
    output reg o_decoded_tlast;
    input o_decoded_tready;

    input [31:0] cfo_idx;
    input [31:0] sfo_idx;
    input [63:0] cur_time;
    input [31:0] cur_corr;
    input [CORR_METADATA_WIDTH-1:0] cur_metadata;

    output reg currently_decoding;
    output reg detector_reset;

    input [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_primary_fft_len;
    input [PRIMARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_primary_fft_len_log2;

    output reg tx_en;

    localparam EARLY_RX_OFFSET = 2;

    /* Concept of operations:
     *  Step 1: fm_flag goes high indicating correctly-received TX packet
     *  Step 2: Wait for wait_step number of compensated MRR clock cycles
     *  Step 3: Step through each bit of requested tx_word, counting in compensated MRR clock cycles
     */

    wire do_op = (i_replay_flag) ? i_tkeep : (i_tready & i_tvalid & i_tkeep);

    //Keep CORDIC updated based on input frequency assignment
    wire [CWIDTH-1:0] to_cordic_i = 32'h7FFF;
    wire [CWIDTH-1:0] to_cordic_q = 32'd0;
    wire [CWIDTH-1:0] i_cordic, q_cordic;
    reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] z_counter;
    m_cordic_z24 #(.bitwidth(CWIDTH)) inst_cordic(
        .clock(clk),
        .reset(rst),
        .enable(1'b1),
        .xi(to_cordic_i),
        .yi(to_cordic_q),
        .zi({{{{ZWIDTH-PRIMARY_FFT_MAX_LEN_LOG2}{1'b0}},z_counter} << (ZWIDTH-setting_primary_fft_len_log2)}),
        .flag_in(1'b0),
        .xo(i_cordic),
        .yo(q_cordic),
        .zo(),
        .flag_out()
    );

    reg [2:0] z_counter_div;
    always @(posedge clk) begin
        if(rst) begin
            z_counter <= 0;
            z_counter_div <= 0;
        end else begin
            //For now, just a fixed per-clock-cycle 

	    //TODO: This probably isn't ideal.  Should ideally be linked to
	    //output sample rate, but that has to cross a clock domain which
	    //can get things messy....
            z_counter_div <= z_counter_div + 1;
            if(z_counter_div == 3'd4) begin
                z_counter_div <= 0;
                z_counter <= z_counter + cfo_idx;
            end
        end
    end

    assign o_tdata = {q_cordic[15:0],i_cordic[15:0]};
    assign o_tvalid = i_tvalid;
    assign o_tlast = i_tlast;
    assign i_tready = o_tready;

    reg [2:0] state, next_state;
    reg mrr_cycle_counter_incr, mrr_cycle_counter_rst, mrr_cycle_counter_rst_int_part;
    reg tx_bit_ctr_incr, tx_bit_ctr_rst;
    reg [15+OVERSAMPLING_RATIO_LOG2:0] mrr_cycle_counter, mrr_cycle_counter_last;
    wire [15:0] mrr_cycle_counter_int_part = mrr_cycle_counter[15+OVERSAMPLING_RATIO_LOG2:OVERSAMPLING_RATIO_LOG2];
    wire [OVERSAMPLING_RATIO_LOG2-1:0] mrr_cycle_counter_frac_part = mrr_cycle_counter[OVERSAMPLING_RATIO_LOG2-1:0];
    reg [5:0] tx_bit_ctr;

    wire mrr_cycle_counter_changed = (mrr_cycle_counter_int_part != mrr_cycle_counter_last);

    //Accumulators for soft symbol output
    reg [ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2-1:0] accum, zero_accum;
    reg [OVERSAMPLING_RATIO_LOG2:0] accum_count;
    reg [ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2+PULSE_SEPARATION_LOG2:0] jitter_max_accum, jitter_accum, jitter_accum_first_half, jitter_accum_second_half;

    reg metadata_push_flag, metadata_reset_flag;
    reg [NUM_METADATA_LOG2-1:0] cur_metadata_idx;
    wire [31:0] cur_metadata_mux = 
        (cur_metadata_idx == 0) ? cfo_idx :
        (cur_metadata_idx == 1) ? sfo_idx :
        (cur_metadata_idx == 2) ? cur_time[63:32] :
        (cur_metadata_idx == 3) ? cur_time[31:0] :
        (cur_metadata_idx == 4) ? cur_corr :
        (cur_metadata_idx == 5) ? cur_metadata[63:32] :
                                  cur_metadata[31:0];

    reg jitter_accum_en, accum_en;
    reg jitter_accum_rst, accum_rst;
    assign o_decoded_tdata = (metadata_push_flag) ? cur_metadata_mux : {accum_count, accum};

    reg payload_bit_ctr_incr, payload_bit_ctr_rst;
    reg [7:0] payload_bit_ctr;

    reg latch_scf;

    reg wait_ctr_incr, wait_ctr_rst;
    reg [PRIMARY_FFT_MAX_LEN_LOG2+4:0] wait_ctr;

    //Intended timing of data demodulation:
    // mrr_cycle=0,1: silent (
    reg peak_search_en, peak_search_update_timing, peak_search_update_timing_complete, peak_less_than_half;
    reg [ESAMP_WIDTH-1:0] peak_val;
    reg [19:0] peak_idx, peak_idx_end;

    wire cur_bit = tx_word[tx_bit_ctr];

    reg pn_correlation_update_zero_flag;
    reg pn_correlation_update_one_flag;
    reg pn_correlation_finished_flag;
    reg pn_correlation_reset;
    reg [PN_SEQ_LEN_LOG2+SFO_SEQ_LEN_LOG2-1:0] pn_correlation_write_addr;
    reg [PN_SEQ_LEN_LOG2+SFO_SEQ_LEN_LOG2-1:0] pn_result_idx;

    reg [31:0] pps_counter;
    reg pps_trigger;

    localparam ST_READY = 0;
    localparam ST_WAIT = 1;
    localparam ST_WAIT_UNTIL_FIRST_BIT = 2;
    localparam ST_RX_PAYLOAD = 3;
    localparam ST_WAIT_TURNAROUND = 4;
    localparam ST_TX = 5;
    localparam ST_SELF_TRIGGER_WAIT = 6;
    localparam ST_SEND_METADATA = 7;

    always @(posedge clk) begin
        if(rst) begin
            state <= ST_READY;
            mrr_cycle_counter <= 0;
            mrr_cycle_counter_last <= 0;
            tx_bit_ctr <= 0;
            accum <= 0;
            accum_count <= 0;
            payload_bit_ctr <= 0;
            wait_ctr <= 0;
            peak_val <= 0;
            peak_idx <= 0;
            peak_idx_end <= 0;
            peak_less_than_half <= 0;
            peak_search_update_timing_complete <= 1'b1;
            pn_correlation_write_addr <= 0;
            zero_accum <= 0;
            jitter_accum_first_half <= 0; 
            jitter_accum_second_half <= 0;
            jitter_max_accum <= 0;
            cur_metadata_idx <= 0;
            pps_counter <= 0;
            pps_trigger <= 1'b0;
        end else begin
            state <= next_state;
            mrr_cycle_counter_last <= mrr_cycle_counter_int_part;

            if(pps_counter == 100000000) begin
                pps_trigger <= 1'b1;
                pps_counter <= 0;
            end else begin
                pps_counter <= pps_counter + 1;
                pps_trigger <= 1'b0;
            end

            //This accumulator integrates the amount of energy (from CFO) experienced during each bit
            if(accum_rst) begin
                accum <= 0;
                accum_count <= 0;
            end else if(accum_en) begin
                accum <= accum + i_tdata;
                accum_count <= accum_count + 1;
            end

            if(jitter_accum_rst) begin
                jitter_accum <= 0;
                jitter_accum_first_half <= 0; 
                jitter_accum_second_half <= 0;
                if(jitter_accum > jitter_max_accum) begin
                    jitter_max_accum <= jitter_accum;
                    peak_less_than_half <= jitter_accum_first_half > jitter_accum_second_half;
                end
            end else if(jitter_accum_en) begin
                jitter_accum <= jitter_accum + i_tdata;
                if(mrr_cycle_counter[OVERSAMPLING_RATIO_LOG2+PULSE_SEPARATION_LOG2-1])
                    jitter_accum_second_half <= jitter_accum_second_half + i_tdata;
                else
                    jitter_accum_first_half <= jitter_accum_first_half + i_tdata;
            end

            //MRR's oscillator has significant jitter which causes us to lose synchronization after a few bit periods.  
            // This allows for us to keep track of jitter based on received pulse timing
            if(peak_search_en & ~peak_search_update_timing) begin
                peak_search_update_timing_complete <= 1'b0;
                if(i_tdata > peak_val) begin
                    peak_val <= i_tdata; 
                    peak_idx <= mrr_cycle_counter_frac_part;
                    peak_idx_end <= mrr_cycle_counter_frac_part;
                end else if(i_tdata == peak_val) begin
                    peak_idx_end <= mrr_cycle_counter_frac_part;
                end
            end

            //Index into metadata to return to user
            if(metadata_reset_flag) begin
                cur_metadata_idx <= 0;
            end else if(metadata_push_flag) begin
                cur_metadata_idx <= cur_metadata_idx + 1;
            end

            //Wait for loopback to catch up with delay imposed by fm_flag
            if(wait_ctr_rst)
                wait_ctr <= 0;
            else if(wait_ctr_incr)
                wait_ctr <= wait_ctr + 1;

            if(payload_bit_ctr_rst)
                payload_bit_ctr <= 0;
            else if(payload_bit_ctr_incr) begin
                payload_bit_ctr <= payload_bit_ctr + 1;
            end

            //mrr_cycle_counter counts the number of resampled MRR cycles which have elapsed since find_max triggered
            if(mrr_cycle_counter_rst) begin
                mrr_cycle_counter <= 0;
            end else if(mrr_cycle_counter_rst_int_part) begin
                mrr_cycle_counter[15+OVERSAMPLING_RATIO_LOG2:OVERSAMPLING_RATIO_LOG2] <= 0;
            end else if(mrr_cycle_counter_incr) begin
                mrr_cycle_counter <= mrr_cycle_counter + 1;
            end else if(peak_search_update_timing & ~peak_search_update_timing_complete) begin
                jitter_max_accum <= 0;
                peak_val <= 0;
                peak_search_update_timing_complete <= 1'b1;
                if(peak_less_than_half) begin
                    mrr_cycle_counter <= max_jitter;
                end else begin
                    mrr_cycle_counter <= {{{OVERSAMPLING_RATIO_LOG2+8}{1'b1}},~max_jitter};
                end
            end
                
            //tx_bit_ctr counts the number of transmit bits sent back to MRR
            if(tx_bit_ctr_rst) begin
                tx_bit_ctr <= 0;
            end else if(tx_bit_ctr_incr) begin
                tx_bit_ctr <= tx_bit_ctr + 1;
            end

            if(pn_correlation_reset) begin
                pn_correlation_write_addr <= 0;
            end else if(pn_correlation_update_zero_flag) begin
                zero_accum <= accum;
            end else if(pn_correlation_update_one_flag) begin
                pn_correlation_write_addr <= pn_correlation_write_addr + 1;
            end
        end
    end

    always @* begin
        next_state = state;
        mrr_cycle_counter_incr = 1'b0;
        mrr_cycle_counter_rst = 1'b0;
        mrr_cycle_counter_rst_int_part = 1'b0;
        tx_bit_ctr_rst = 1'b0;
        tx_bit_ctr_incr = 1'b0;
        o_tkeep = 1'b0;
        detector_reset = 1'b0;
        accum_en = 1'b0;
        accum_rst = 1'b0;
        jitter_accum_en = 1'b0;
        jitter_accum_rst = 1'b0;
        o_decoded_tvalid = 1'b0;
        o_decoded_tlast = 1'b0;
        payload_bit_ctr_incr = 1'b0;
        payload_bit_ctr_rst = 1'b0;
        wait_ctr_incr = 1'b0;
        wait_ctr_rst = 1'b0;
        latch_scf = 1'b0;
        tx_en = 1'b0;
        peak_search_en = 1'b0;
        peak_search_update_timing = 1'b0;
        pn_correlation_update_zero_flag = 1'b0;
        pn_correlation_update_one_flag = 1'b0;
        pn_correlation_finished_flag = 1'b0;
        pn_correlation_reset = 1'b0;
        currently_decoding = 1'b1;
        metadata_push_flag = 1'b0;
        metadata_reset_flag = 1'b0;
        
        case(state)
            //In ST_READY, we are waiting for an incoming packet to trigger loopback
            ST_READY: begin
                mrr_cycle_counter_rst = 1'b1;
                tx_bit_ctr_rst = 1'b1;
                payload_bit_ctr_rst = 1'b1;
                wait_ctr_rst = 1'b1;
                latch_scf = 1'b1;
                pn_correlation_reset = 1'b1;
                currently_decoding = 1'b0;
                accum_rst = 1'b1;
                metadata_reset_flag = 1'b1;

                //Occasionally (once per second) spit out a 1-element dummy packet to satisfy host interface
                o_decoded_tvalid = pps_trigger;
                o_decoded_tlast = pps_trigger;

                if(fm_flag) begin
                    next_state = ST_RX_PAYLOAD;
                end
            end

	    //After a trigger from the find_max logic, we wait a set period of
	    // time for MRR to transition to receive mode num_payload_bits
	    // signifies the number of bits to decode
            ST_RX_PAYLOAD: begin
                mrr_cycle_counter_incr = do_op;
                peak_search_en         = do_op;
                accum_en               = do_op;
                jitter_accum_en        = do_op;

	        //fm_flag indicates we are synchronized to the symbol boundary.
	        // However, it is up to this block to synchronize to the following
	        // PN code (15'b000100110101111).  Do this correlation by summing
	        // difference-based measurements between the zero- and one-chips.
                pn_correlation_update_zero_flag = mrr_cycle_counter_changed & (mrr_cycle_counter_int_part == 1);//TODO: Needs to include the next index as well... | mrr_cycle_counter_int_part == 3);
                pn_correlation_update_one_flag = mrr_cycle_counter_changed & (mrr_cycle_counter_int_part == 3);//TODO: Needs to include the next index as well | mrr_cycle_counter_int_part == 5);
                pn_correlation_finished_flag = (mrr_cycle_counter_int_part == recharge_len+1) & (payload_bit_ctr == (PN_SEQ_LEN + SFO_SEQ_LEN));

                accum_rst = mrr_cycle_counter_changed;
                jitter_accum_rst = mrr_cycle_counter_changed & (mrr_cycle_counter[OVERSAMPLING_RATIO_LOG2+PULSE_SEPARATION_LOG2-1:OVERSAMPLING_RATIO_LOG2-1] == 0);
                o_decoded_tvalid = mrr_cycle_counter_changed & (mrr_cycle_counter_int_part <= recharge_len+2) & (mrr_cycle_counter_int_part > 0);
                o_decoded_tlast = mrr_cycle_counter_changed & (mrr_cycle_counter_int_part == recharge_len+2);

                payload_bit_ctr_incr  = (mrr_cycle_counter_int_part == recharge_len+2);
                peak_search_update_timing = (mrr_cycle_counter_int_part == recharge_len+2);

                if((payload_bit_ctr-pn_result_idx) == num_payload_bits) begin
                    mrr_cycle_counter_rst_int_part = 1'b1;
                    next_state = ST_WAIT_TURNAROUND;
                end
            end

            ST_WAIT_TURNAROUND: begin
                mrr_cycle_counter_incr = do_op;
                if(mrr_cycle_counter_int_part == wait_step) begin
                    mrr_cycle_counter_rst_int_part = 1'b1;
                    next_state = ST_TX;
                end
            end

	    //Then transmit the packet, one bit at a time.  Transition back to
	    // a waiting state after all 32 bits have been transmitted to MRR
            ST_TX: begin
                tx_en = 1'b1;
                detector_reset = 1'b1;
                mrr_cycle_counter_incr = do_op;
                mrr_cycle_counter_rst_int_part = (mrr_cycle_counter_int_part == 4);
                tx_bit_ctr_incr = (mrr_cycle_counter_int_part == 4);
                o_tkeep = (tx_disable) ? 1'b0 : (cur_bit) ? (mrr_cycle_counter_int_part == 0) : (mrr_cycle_counter_int_part == 2);
                if(tx_bit_ctr == 32) begin
                    next_state = ST_SELF_TRIGGER_WAIT;
                end 
            end

            //Keep currently_decoding high for a while to avoid self-trigger
            ST_SELF_TRIGGER_WAIT: begin
                detector_reset = 1'b1;
                wait_ctr_incr = do_op;
                if(wait_ctr == ({2'd0,setting_primary_fft_len} << 2))
                    next_state = ST_SEND_METADATA;
            end

            ST_SEND_METADATA: begin
                metadata_push_flag = 1'b1;
                o_decoded_tvalid = 1'b1;
                o_decoded_tlast = (cur_metadata_idx == NUM_METADATA-1);
                if(cur_metadata_idx == NUM_METADATA-1)
                    next_state = ST_READY;
            end
        endcase
    end

    //Separate state machine to find the best PN correlation fit
    reg [3:0] pn_search_state, next_pn_search_state;
    reg [SFO_SEQ_LEN_LOG2-1:0] pn_search_idx;
    reg [PN_SEQ_LEN_LOG2-1:0] pn_search_sub_idx;
    wire [SFO_SEQ_LEN_LOG2+PN_SEQ_LEN_LOG2-1:0] pn_read_idx = pn_search_sub_idx + pn_search_idx;
    reg pn_corr_accum_en;
    reg pn_corr_accum_en_delay;
    reg pn_update_max_corr;
    reg pn_set_result_offset;
    reg pn_reset_search;

    reg [PN_SEQ_LEN_LOG2+ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2:0] pn_corr_accum, highest_pn_search_corr;
    reg [SFO_SEQ_LEN_LOG2-1:0] highest_pn_search_idx;

    wire [ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2:0] pn_readback;
    wire [PN_SEQ_LEN_LOG2+ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2:0] pn_readback_se;
    assign pn_readback_se = {{{PN_SEQ_LEN_LOG2}{pn_readback[ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2]}},pn_readback};
    reg [PN_SEQ_LEN-1:0] pn_sequence;

    wire [ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2:0] zero_accum_padded = {1'b0,zero_accum};
    wire [ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2:0] accum_padded = {1'b0,accum};
    ram_2port #(.DWIDTH(ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2+1), .AWIDTH(PN_SEQ_LEN_LOG2+SFO_SEQ_LEN_LOG2)) pn_rb_ram (
        //Port A (written to by decoding logic)
        .clka(clk),
        .ena(1'b1),
        .wea(pn_correlation_update_one_flag),
        .addra(pn_correlation_write_addr),
        .dia(zero_accum_padded-accum_padded),
        .doa(),

        //Port B (read from correlation logic)
        .clkb(clk),
        .enb(1'b1),
        .web(1'b0),
        .addrb(pn_read_idx),
        .dib(),
        .dob(pn_readback)
    );

    localparam PN_SEARCH_IDLE = 0;
    localparam PN_SEARCH_CORR_UPDATE = 1;
    localparam PN_SEARCH_CORR_UPDATE_DELAY = 2;
    localparam PN_SEARCH_INCR_OFFSET = 3;
    localparam PN_SEARCH_SET_RESULT_OFFSET = 4;

    always @(posedge clk) begin
        if(rst) begin
            pn_search_state <= PN_SEARCH_IDLE;
            pn_corr_accum <= 0;
            pn_search_sub_idx <= 0;
            pn_search_idx <= 0;
            highest_pn_search_corr <= 0;
            highest_pn_search_idx <= 0;
            pn_corr_accum_en_delay <= 0;
            pn_sequence <= 0;
            pn_result_idx <= 0;
        end else begin
            pn_search_state <= next_pn_search_state;

            pn_corr_accum_en_delay <= pn_corr_accum_en;

            if(pn_reset_search) begin
                pn_search_sub_idx <= 0;
                pn_search_idx <= 0;
                pn_corr_accum <= 0;
                highest_pn_search_corr <= 0;
                pn_sequence <= PN_SEQ;
            end
            if(pn_corr_accum_en) begin
                pn_search_sub_idx <= pn_search_sub_idx + 8'd1;
            end

            //All memory transactions delayed by one cycle
            if(pn_corr_accum_en_delay) begin
                pn_sequence <= {pn_sequence[PN_SEQ_LEN-2:0], 1'b0};
                if(pn_sequence[PN_SEQ_LEN-1])
                    pn_corr_accum <= pn_corr_accum - pn_readback_se;
                else
                    pn_corr_accum <= pn_corr_accum + pn_readback_se;
            end

            if(pn_update_max_corr) begin
                pn_corr_accum <= 0;
                pn_sequence <= PN_SEQ;
                pn_search_idx <= pn_search_idx + 8'd1;
                pn_search_sub_idx <= 0;
                if((pn_corr_accum > highest_pn_search_corr) && (pn_corr_accum[PN_SEQ_LEN_LOG2+ESAMP_WIDTH+OVERSAMPLING_RATIO_LOG2] == 1'b0)) begin
                    highest_pn_search_corr <= pn_corr_accum;
                    highest_pn_search_idx <= pn_search_idx;
                end
            end
            if(pn_set_result_offset) begin
                pn_result_idx <= highest_pn_search_idx;
            end
        end
    end

    always @* begin
        next_pn_search_state = pn_search_state;
        pn_corr_accum_en = 1'b0;
        pn_update_max_corr = 1'b0;
        pn_set_result_offset = 1'b0;
        pn_reset_search = 1'b0;
        
        case(pn_search_state)
            PN_SEARCH_IDLE: begin
                if(pn_correlation_finished_flag) begin
                    pn_reset_search = 1'b1;
                    next_pn_search_state = PN_SEARCH_CORR_UPDATE;
                end
            end

            PN_SEARCH_CORR_UPDATE: begin
                pn_corr_accum_en = 1'b1;
                if(pn_search_sub_idx == PN_SEQ_LEN-1) begin
                    next_pn_search_state = PN_SEARCH_CORR_UPDATE_DELAY;
                end
            end

            PN_SEARCH_CORR_UPDATE_DELAY: begin
                next_pn_search_state = PN_SEARCH_INCR_OFFSET;
            end

            PN_SEARCH_INCR_OFFSET: begin
                pn_update_max_corr = 1'b1;
                if(pn_search_idx == SFO_SEQ_LEN-1) begin
                    next_pn_search_state = PN_SEARCH_SET_RESULT_OFFSET;
                end else begin
                    next_pn_search_state = PN_SEARCH_CORR_UPDATE;
                end
            end

            PN_SEARCH_SET_RESULT_OFFSET: begin
                pn_set_result_offset = 1'b1;
                next_pn_search_state = PN_SEARCH_IDLE;
            end
        endcase
    end
    
endmodule
