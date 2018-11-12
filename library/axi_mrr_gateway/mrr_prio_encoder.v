module mrr_prio_encoder
#(
    parameter IN_WIDTH=64,
    parameter OUT_WIDTH=5
) (
    input [IN_WIDTH-1:0] in,
    output reg [OUT_WIDTH-1:0] out
);

integer i;
always @* begin
    out = 0;
    for (i=0; i < IN_WIDTH; i=i+1)
        if(in[i]) out = i;
end

endmodule
