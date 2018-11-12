module mrr_log2_expand
#(
    parameter LOG2_WIDTH=4
)(
clk,
num_log2_in,
num_out,
mask_out
);

input clk;
input [LOG2_WIDTH-1:0] num_log2_in;
output reg [2**LOG2_WIDTH:0] num_out;
output reg [2**LOG2_WIDTH:0] mask_out;

wire [2**LOG2_WIDTH:0] num_out_int;
reg [2**LOG2_WIDTH:0] mask_out_int;

assign num_out_int = 1 << num_log2_in;

integer i;
always @* begin
    mask_out_int = 0;
    for(i=0; i < 2**LOG2_WIDTH; i=i+1)
        if(i < num_log2_in) mask_out_int[i] = 1'b1;
end

always @(posedge clk) begin
    mask_out <= mask_out_int;
    num_out <= num_out_int;
end

endmodule
