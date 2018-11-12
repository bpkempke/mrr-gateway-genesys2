/*
 * MRR's "matched filter" is augmented to provide near-MF functionality using significantly less resources.
 * The new matched filter reduces memory requirements from O(number of samples) to O(constant).
 * Now, the matched filter is divided up into N accumulators
 * Incoming samples are added to a temporary accumulator until it contains M samples (M = pulse_len/N)
 * Once the temporary accumulator is filled, it is added to the total Es with the oldest being subtracted, thus incrementing the matched filter in time
*/
module mrr_cfo_mf_es
#(
    parameter MF_MAX_N_LOG2 = 4,
    parameter MF_MAX_M_LOG2 = 7,
    parameter DATA_IN_WIDTH = 16,
    parameter ES_OUT_WIDTH = 9,
    parameter POWER_VAL_WIDTH = 18, //NOTE: Capped at 18 due to using DSP48
    parameter MF_MAX_N = 2**MF_MAX_N_LOG2,
    parameter MF_MAX_M = 2**MF_MAX_M_LOG2,
    parameter MF_RESULT_WIDTH = MF_MAX_M_LOG2+MF_MAX_N_LOG2+DATA_IN_WIDTH
)(
    input clk,
    input rst,
    input enable,
    input [MF_MAX_N_LOG2-1:0] setting_num_accum,
    input [MF_MAX_M_LOG2-1:0] setting_accum_len_log2,
    input accum_settings_changed,
    input [DATA_IN_WIDTH-1:0] i_tdata,
    input [DATA_IN_WIDTH-1:0] q_tdata,
    output [ES_OUT_WIDTH-1:0] Es
);

localparam SATURATION_VAL = {(ES_OUT_WIDTH){1'b1}};

wire [MF_RESULT_WIDTH-1:0] i_tdata_extend = 
    {{(MF_MAX_M_LOG2+MF_MAX_N_LOG2){i_tdata[DATA_IN_WIDTH-1]}},i_tdata};
wire [MF_RESULT_WIDTH-1:0] q_tdata_extend = 
    {{(MF_MAX_M_LOG2+MF_MAX_N_LOG2){q_tdata[DATA_IN_WIDTH-1]}},q_tdata};

reg [MF_MAX_N_LOG2-1:0] num_valid_accums;
reg [MF_MAX_M_LOG2-1:0] cur_m_ctr;
reg [MF_MAX_M_LOG2+MF_MAX_N_LOG2+DATA_IN_WIDTH-1:0] mf_i, mf_q;
wire [MF_MAX_M_LOG2+MF_MAX_N_LOG2+DATA_IN_WIDTH-1:0] mf_i_scaled, mf_q_scaled;
assign mf_i_scaled = mf_i << (MF_MAX_M_LOG2-setting_accum_len_log2);
assign mf_q_scaled = mf_q << (MF_MAX_M_LOG2-setting_accum_len_log2);

wire [POWER_VAL_WIDTH*2-1:0] Esfp;
wire Esfp_valid;
complex_to_magsq #(.WIDTH(POWER_VAL_WIDTH)) mf_magsq_inst(
    .clk(clk),
    .reset(rst),
    .clear(1'b0),
    .i_tdata({mf_i_scaled[MF_RESULT_WIDTH-1-:POWER_VAL_WIDTH],mf_q_scaled[MF_RESULT_WIDTH-1-:POWER_VAL_WIDTH]}),
    .i_tlast(1'b1),
    .i_tvalid(enable),
    .i_tready(),
    .o_tdata(Esfp),
    .o_tlast(),
    .o_tvalid(Esfp_valid),
    .o_tready(enable)
);

assign Es = (Esfp > SATURATION_VAL) ? SATURATION_VAL : Esfp[ES_OUT_WIDTH-1:0];

reg [MF_RESULT_WIDTH-1:0] i_accum [MF_MAX_N-1:0];
reg [MF_RESULT_WIDTH-1:0] q_accum [MF_MAX_N-1:0];

reg [MF_MAX_N_LOG2-1:0] cur_accum_idx;
wire [MF_MAX_N_LOG2-1:0] next_accum_idx = ((cur_accum_idx + 1) < setting_num_accum) ? cur_accum_idx + 1 : 0;

integer i;
always @(posedge clk) begin
    if(rst | accum_settings_changed) begin
        mf_i <= 0;
        mf_q <= 0;
        num_valid_accums <= 0;
        cur_m_ctr <= 0;
        cur_accum_idx <= 0;
        for(i=0; i<MF_MAX_N; i=i+1) begin
            i_accum[i] <= 0;
            q_accum[i] <= 0;
        end
    end else begin
        if(enable) begin
            if(cur_m_ctr >= ({{{MF_MAX_M_LOG2}{1'b0}},1'b1} << setting_accum_len_log2)) begin
                cur_m_ctr <= 1;
                mf_i <= mf_i + i_accum[cur_accum_idx] - i_accum[next_accum_idx];
                mf_q <= mf_q + q_accum[cur_accum_idx] - q_accum[next_accum_idx];
                i_accum[next_accum_idx] <= i_tdata_extend;
                q_accum[next_accum_idx] <= q_tdata_extend;
                cur_accum_idx <= next_accum_idx; 
            end else begin
                cur_m_ctr <= cur_m_ctr + 1;
                i_accum[cur_accum_idx] <= i_accum[cur_accum_idx] + i_tdata_extend;
                q_accum[cur_accum_idx] <= q_accum[cur_accum_idx] + q_tdata_extend;
            end
        end
    end
end

endmodule

