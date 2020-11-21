/***************************** Overview ***************************************
 * sfo_fft_correlator:
 *  This block takes as input a frequency-domain representation of the
 *  power-domain timeseries of a single CFO hypothesis.  Given a single SFO
 *  hypothesis, this block calculates the correlation as the summation across
 *  all harmonics which are a multiple of the SFO hypothesis.  Only works for
 *  datasets which resemble a repetitive structure.  PPM of all zeros is the
 *  ideal candidate for use for this SFO determination technique.
**************************** End Overview ************************************/

module sfo_fft_correlator 
#(
    parameter FFT_LEN_LOG2=9,
    parameter POWER_WIDTH=16
)(clk, reset, sfo_int_part, sfo_frac_part, setting_num_harmonics, sfo_divisor, corr_threshold, correlation_reset, correlation_update, fft_mag_in, fft_mag_exponent_in, metadata_out, correlation_out, correlation_out_valid);

`include "mrr_params.vh"

input clk;
input reset;
input [SFO_INT_WIDTH-1:0] sfo_int_part;
input [SFO_FRAC_WIDTH-1:0] sfo_frac_part;
input [MAX_NUM_HARMONICS_LOG2-1:0] setting_num_harmonics;
input [POWER_WIDTH-1:0] sfo_divisor;
input [POWER_WIDTH-1:0] corr_threshold;
input correlation_reset;
input correlation_update;
input [POWER_WIDTH-1:0] fft_mag_in;
input [FFT_SHIFT_WIDTH-1:0] fft_mag_exponent_in;
output [CORR_MANTISSA_WIDTH:0] correlation_out;
output [POWER_WIDTH*2+CORR_MANTISSA_WIDTH:0] metadata_out;
output reg correlation_out_valid;

// Index accumulators
reg [SFO_INT_WIDTH-1:0] sfo_int;
reg [FFT_LEN_LOG2-1:0] fft_index;
reg [FFT_LEN_LOG2-1:0] harmonic_counter;
reg [SFO_FRAC_WIDTH-1:0] sfo_frac;
reg [POWER_WIDTH+MAX_NUM_HARMONICS_LOG2-1:0] correlation_numerator, correlation_denominator;
reg [SKIRT_WIDTH_LOG2:0] bins_since_last_harmonic;

//Scale the divisor depending on what the exponent is for fft_mag_in
wire [POWER_WIDTH-1:0] divisor_shifted = sfo_divisor >> fft_mag_exponent_in;
wire [POWER_WIDTH-1:0] divisor_shifted_min = (divisor_shifted < 1) ? 1 : divisor_shifted;

// Divide I part by divisor from settings register
wire [31:0] divide_result_int;
wire [31:0] divide_result_frac;
reg [31:0] divide_result_int_reg;
reg [31:0] divide_result_frac_reg;
reg divide_in_valid;
wire divide_result_valid;
divide_uint32 divide_inst (
  .aclk(clk),
  .aresetn(~(reset | correlation_reset)),
  .s_axis_divisor_tvalid(divide_in_valid),
  .s_axis_divisor_tready(),
  .s_axis_divisor_tlast(1'b0),
  .s_axis_divisor_tdata(divisor_shifted_min),
  .s_axis_dividend_tvalid(divide_in_valid),
  .s_axis_dividend_tready(),
  .s_axis_dividend_tlast(1'b0),
  .s_axis_dividend_tdata(correlation_numerator[POWER_WIDTH-1:0]),
  .m_axis_dout_tvalid(divide_result_valid),
  .m_axis_dout_tready(1'b1),
  .m_axis_dout_tdata({divide_result_int,divide_result_frac}));

wire [31:0] corr_divide_result_int;
wire [31:0] corr_divide_result_frac;
reg [31:0] corr_divide_result_int_reg;
reg [31:0] corr_divide_result_frac_reg;
wire corr_divide_result_valid;
divide_uint32 divide_corr_inst (
  .aclk(clk),
  .aresetn(~(reset | correlation_reset)),
  .s_axis_divisor_tvalid(divide_in_valid),
  .s_axis_divisor_tready(),
  .s_axis_divisor_tlast(1'b0),
  .s_axis_divisor_tdata((correlation_denominator[POWER_WIDTH-1:0] == 0) ? 1 : correlation_denominator[POWER_WIDTH-1:0]),
  .s_axis_dividend_tvalid(divide_in_valid),
  .s_axis_dividend_tready(),
  .s_axis_dividend_tlast(1'b0),
  .s_axis_dividend_tdata(correlation_numerator[POWER_WIDTH-1:0]),
  .m_axis_dout_tvalid(corr_divide_result_valid),
  .m_axis_dout_tready(1'b1),
  .m_axis_dout_tdata({corr_divide_result_int,corr_divide_result_frac}));

wire [CORR_MANTISSA_WIDTH-1:0] corr_divide_out = {corr_divide_result_int_reg[12-:13],corr_divide_result_frac_reg[31-:13]};
wire corr_meets_threshold = (corr_divide_out > corr_threshold);
assign correlation_out = {corr_meets_threshold,divide_result_int_reg[12-:13],divide_result_frac_reg[31-:13]};
assign metadata_out = {correlation_out,correlation_numerator[POWER_WIDTH-1:0],sfo_divisor[POWER_WIDTH-1:0]};

always @(posedge clk) begin
    if(reset | correlation_reset) begin
        sfo_int <= (sfo_frac_part[SFO_FRAC_WIDTH-1]) ? sfo_int_part+1 : sfo_int_part;
        sfo_frac <= sfo_frac_part + 2**(SFO_FRAC_WIDTH-1);
        fft_index <= 0;
        correlation_numerator <= 0;
        correlation_denominator <= 0;
        harmonic_counter <= 0;
        divide_in_valid <= 1'b0;
        correlation_out_valid <= 1'b0;
        bins_since_last_harmonic <= SKIRT_WIDTH;
        //divide_result_int_reg <= 0;
        //divide_result_frac_reg <= 0;
        //corr_divide_result_int_reg <= 0;
        //corr_divide_result_frac_reg <= 0;
    end else begin
	// Each incoming sample increments the FFT index by 1.  When this
	// exceeds sfo_int, the correlation is updated along with sfo_int and
	// sfo_frac.
        divide_in_valid <= 1'b0;
        if(correlation_update) begin
            fft_index <= fft_index + 1;
            if(harmonic_counter < setting_num_harmonics) begin
                if(fft_index == sfo_int) begin
                    bins_since_last_harmonic <= 0;
                    harmonic_counter <= harmonic_counter + 1;
                    if(harmonic_counter == setting_num_harmonics-1) begin
                        divide_in_valid <= 1'b1;
                    end
                    correlation_numerator <= correlation_numerator + fft_mag_in;
	            if(sfo_frac >= (SFO_FRAC_RANGE-sfo_frac_part)) begin
                        sfo_int <= sfo_int + sfo_int_part + 1;
                    end else begin
                        sfo_int <= sfo_int + sfo_int_part;
                    end
                    sfo_frac <= sfo_frac + sfo_frac_part;

                end else if((fft_index != 0) && (fft_index < sfo_int-SKIRT_WIDTH) && (bins_since_last_harmonic >= SKIRT_WIDTH)) begin
                    correlation_denominator <= correlation_denominator + fft_mag_in;
                end else begin
                    if(bins_since_last_harmonic <= SKIRT_WIDTH) begin
                        bins_since_last_harmonic <= bins_since_last_harmonic + 1;
                    end
                end
            end
        end
        if(divide_result_valid) begin
            divide_result_int_reg <= divide_result_int;
            divide_result_frac_reg <= divide_result_frac;
            correlation_out_valid <= 1'b1;
        end
        if(corr_divide_result_valid) begin
            corr_divide_result_int_reg <= corr_divide_result_int;
            corr_divide_result_frac_reg <= corr_divide_result_frac;
        end
    end
end

endmodule
