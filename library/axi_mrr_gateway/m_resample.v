/*************************** Overview *************************************
Downsample the sample by factor of n1 + n3/n2 to get 16 oversampling rate,
which is required for correlation to work
**************************End Overview ************************************/
module m_resample (
    input clk, 
    input rst,
    input[15:0] n1, 
    input[15:0] n2,
    input[15:0] n3,
    input[15:0] decim,
    input i_tlast,
    input i_tvalid, 
    output i_tready,
    output o_tlast, 
    output o_tvalid,
    input o_tready
);

   //downsample factor n1+n3/n2 

   reg        extra_delay;
   wire[14:0] half_n2 = n2[15:1];
   reg [15:0] counter1;
   reg [15:0] counter2;
   wire       on_last_one =  (counter1 >= (n1-1)) | (n1 == 0);  // n==0 lets everything through
   reg        on_last_one_delay ;
   wire       over_counter2 = (counter2 + n3 >= n2) & (n2 != 0);
   reg        over_counter2_delay;
   wire       over_half = (counter2 >= half_n2) & (n2 != 0);
   reg        over_half_delay;
   reg        hold_flag;
   wire       extra = (extra_delay)? 1'b0 : (~over_half_delay & over_half) | (over_half_delay & over_counter2_delay & over_half);
   
   reg [15:0] decim_counter;

   wire o_tvalid_pre = (n1 == 1)? (i_tvalid & ~extra) : (i_tvalid & ((over_half)? on_last_one_delay : on_last_one));

   assign o_tvalid = o_tvalid_pre & (decim_counter == 0);
   assign o_tlast = i_tlast;
   assign i_tready = o_tready;// | ((n1 == 1)? extra : ~((over_half)? on_last_one_delay : on_last_one));

   always @(posedge clk) begin
       if(rst) begin
           decim_counter <= 0;
       end else begin
           if(o_tvalid_pre) begin
               if((decim == 0) || (decim_counter == decim-1)) begin
                   decim_counter <= 0;
               end else begin
                   decim_counter <= decim_counter + 1;
               end
           end
       end
   end

   // Caution if changing n during operation!
   always @(posedge clk) begin
       if(rst)begin
           on_last_one_delay<= 0;
           over_half_delay     <= 0;
           over_counter2_delay <= 0;
           extra_delay         <= 0;
       end else if(i_tvalid & i_tready) begin
           on_last_one_delay   <= on_last_one;
           over_half_delay     <= over_half;
           over_counter2_delay <= over_counter2;
           extra_delay         <= extra;
       end
   end

   always @(posedge clk) begin
       if(rst) begin
           counter1 <= 0;
           hold_flag <= 0;
       end else if(i_tvalid & i_tready) begin
           if(on_last_one) begin
               counter1 <= 16'd0;
               hold_flag <= 0;
           end else if((counter1 == 0) & (over_counter2) & ~hold_flag) begin
               counter1 <= counter1;
               hold_flag <= 1; // to guarantee at most one hold each cycle
           end else begin 
               counter1 <= counter1 + 16'd1;
           end
       end
   end

   always @(posedge clk) begin
       if(rst)
           counter2 <= 0;
       else if(n1 == 1) begin
           if(o_tvalid & o_tready)begin
               if(over_counter2)
                   counter2 <= counter2 + n3 - n2;
               else
                   counter2 <= counter2 + n3;
           end
       end else if(on_last_one_delay & i_tvalid & i_tready) begin
           if(over_counter2)
               counter2 <= counter2 + n3 - n2;
           else
               counter2 <= counter2 + n3;
       end
   end

endmodule // resample
