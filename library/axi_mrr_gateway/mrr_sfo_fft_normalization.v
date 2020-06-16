
module mrr_sfo_fft_normalization(
clk,
rst,
clear,
setting_primary_fft_len_log2,
setting_primary_fft_len_mask,
setting_secondary_fft_len_mask,
data_in_mag,
data_in_valid,
data_in_last,
data_out_idx_next,
data_out_shift
);

`include "mrr_params.vh"

localparam PRIO_WIDTH=5;

input clk;
input rst;
input clear;
input [31:0] data_in_mag;
input data_in_valid;
input data_in_last;
input [PRIMARY_FFT_MAX_LEN_LOG2-1:0] data_out_idx_next;
input [PRIMARY_FFT_MAX_LEN_LOG2_LOG2-1:0] setting_primary_fft_len_log2;
input [PRIMARY_FFT_MAX_LEN_LOG2:0] setting_primary_fft_len_mask;
input [SECONDARY_FFT_MAX_LEN_LOG2:0] setting_secondary_fft_len_mask;
output [PRIO_WIDTH-1:0] data_out_shift;

reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] data_out_idx_next_last;

//Counter keeps track of where we are in CFO/SFO FFT 
reg [PRIMARY_FFT_MAX_LEN_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] data_in_idx, data_in_idx_last;
wire [PRIMARY_FFT_MAX_LEN_LOG2+SECONDARY_FFT_MAX_LEN_LOG2-1:0] data_in_idx_next = data_in_idx+1;

//MSB priority encoder for incoming data
wire [PRIO_WIDTH-1:0] data_in_prio_msb;
wire [PRIO_WIDTH-1:0] priority_ram_read;
wire [PRIO_WIDTH-1:0] priority_ram_read_last;
reg [PRIO_WIDTH-1:0] priority_ram_read_last_latched;
wire [PRIO_WIDTH-1:0] max_prio_msb = 
                     ((data_in_idx & ({{{PRIMARY_FFT_MAX_LEN_LOG2}{1'b0}},setting_secondary_fft_len_mask} << setting_primary_fft_len_log2)) == 0) ? data_in_prio_msb : 
                     (data_in_prio_msb > priority_ram_read) ? data_in_prio_msb : priority_ram_read;
mrr_prio_encoder #(
    .IN_WIDTH(32),
    .OUT_WIDTH(5)
) prio_encoder_inst (
    .in(data_in_mag),
    .out(data_in_prio_msb)
);

wire [PRIMARY_FFT_MAX_LEN_LOG2-1:0] priority_ram_read_idx = data_in_idx_next & setting_primary_fft_len_mask;
reg [PRIMARY_FFT_MAX_LEN_LOG2-1:0] priority_ram_read_idx_last;
assign priority_ram_read = ((data_in_idx & setting_primary_fft_len_mask) == priority_ram_read_idx_last) ? priority_ram_read_last : priority_ram_read_last_latched;

//RAM block storing all priority-encoded MSBs from prior FFTs
ram_2port #(.DWIDTH(PRIO_WIDTH), .AWIDTH(PRIMARY_FFT_MAX_LEN_LOG2)) priority_ram_inst (
    .clka(clk),
    .ena(1'b1),
    .wea(data_in_valid),
    .addra(data_in_idx & setting_primary_fft_len_mask),
    .dia(max_prio_msb),
    .doa(),

    .clkb(clk),
    .enb(1'b1),
    .web(1'b0),
    .addrb(priority_ram_read_idx),
    .dib(),
    .dob(priority_ram_read_last)
);

//Offload priority results into this FFT block to allow for zero-latency access
// to results upon output
wire last_secondary_fft = (((data_in_idx >> setting_primary_fft_len_log2) & setting_secondary_fft_len_mask) == setting_secondary_fft_len_mask);
wire [PRIO_WIDTH-1:0] data_out_shift_next;
ram_2port #(.DWIDTH(PRIO_WIDTH), .AWIDTH(PRIMARY_FFT_MAX_LEN_LOG2)) priority_ram_pong (
    .clka(clk),
    .ena(1'b1),
    .wea(last_secondary_fft),
    .addra(data_in_idx & setting_primary_fft_len_mask),
    .dia(max_prio_msb),
    .doa(),

    .clkb(clk),
    .enb(1'b1),
    .web(1'b0),
    .addrb(data_out_idx_next),
    .dib(),
    .dob(data_out_shift_next)
);

always @(posedge clk) begin
    if(rst) begin
        priority_ram_read_idx_last <= 0;
        priority_ram_read_last_latched <= 0;
        data_in_idx_last <= 0;
        data_in_idx <= 0;
    end else begin
        priority_ram_read_idx_last <= priority_ram_read_idx;
        data_in_idx_last <= data_in_idx;
        if(data_in_idx_last != data_in_idx) begin
            priority_ram_read_last_latched <= priority_ram_read_last;
        end
        if(data_in_valid) begin
            data_in_idx <= data_in_idx + 1;
        end
    end
end

reg [PRIO_WIDTH-1:0] data_out_shift_latched;
assign data_out_shift = (data_out_idx_next != data_out_idx_next_last) ? data_out_shift_next : data_out_shift_latched;
always @(posedge clk) begin
    if(rst) begin
        data_out_shift_latched <= 0;
        data_out_idx_next_last <= 0;
    end else begin
        data_out_idx_next_last <= data_out_idx_next;
        if(data_out_idx_next != data_out_idx_next_last) begin
            data_out_shift_latched <= data_out_shift_next;
        end
    end
end

endmodule
