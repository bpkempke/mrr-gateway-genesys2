// -*- verilog -*-
//
//  USRP - Universal Software Radio Peripheral
//
//  Copyright (C) 2003, 2007 Matt Ettus
//

//

module m_cordic_z24(clock, reset, enable, xi, yi, zi, flag_in, xo, yo, zo, flag_out);
   parameter bitwidth = 16;
   parameter stages = 19;
   localparam zwidth = 24;
   
   input clock;
   input reset;
   input enable;
   input flag_in;
   input [bitwidth-1:0] xi, yi;
   output [bitwidth-1:0] xo, yo;
   input [zwidth-1:0] zi;
   output [zwidth-1:0] zo;
   output flag_out;
   
   reg [bitwidth+1:0] 	 x0,y0;
   reg [zwidth-2:0] 	 z0;
   wire [bitwidth+1:0] 	 x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20;
   wire [bitwidth+1:0] 	 y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12,y13,y14,y15,y16,y17,y18,y19,y20;
   wire [zwidth-2:0] 	 z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17,z18,z19,z20;
   reg 		 	 flag0;
   wire  	 flag1,flag2,flag3,flag4,flag5,flag6,flag7,flag8,flag9,flag10,flag11,flag12,flag13,flag14,flag15,flag16,flag17,flag18,flag19,flag20;

   wire [bitwidth+1:0] xi_ext = {{2{xi[bitwidth-1]}},xi};
   wire [bitwidth+1:0] yi_ext = {{2{yi[bitwidth-1]}},yi};

   // Compute consts.  Would be easier if vlog had atan...
   // see gen_cordic_consts.py

   // constants for 24 bit wide phase
   localparam 	       c00 = 23'd2097152;
   localparam 	       c01 = 23'd1238021;
   localparam 	       c02 = 23'd654136;
   localparam 	       c03 = 23'd332050;
   localparam 	       c04 = 23'd166669;
   localparam 	       c05 = 23'd83416;
   localparam 	       c06 = 23'd41718;
   localparam 	       c07 = 23'd20860;
   localparam 	       c08 = 23'd10430;
   localparam 	       c09 = 23'd5215;
   localparam 	       c10 = 23'd2608;
   localparam 	       c11 = 23'd1304;
   localparam 	       c12 = 23'd652;
   localparam 	       c13 = 23'd326;
   localparam 	       c14 = 23'd163;
   localparam 	       c15 = 23'd81;
   localparam 	       c16 = 23'd41;
   localparam 	       c17 = 23'd20;
   localparam 	       c18 = 23'd10;
   localparam 	       c19 = 23'd5;
   localparam 	       c20 = 23'd3;
   localparam 	       c21 = 23'd1;
   localparam 	       c22 = 23'd1;
   localparam 	       c23 = 23'd0;

   always @(posedge clock)
     if(reset)
       begin
	  x0   <= 0; y0   <= 0;  z0   <= 0;  flag0 <= 0;
       end
     else// if(enable)
       begin
	  z0 <= zi[zwidth-2:0];
	  flag0 <= flag_in;
	  case (zi[zwidth-1:zwidth-2])
	    2'b00, 2'b11 : 
	      begin
		 x0 <= xi_ext;
		 y0 <= yi_ext;
	      end
	    2'b01, 2'b10 :
	      begin
		 x0 <= -xi_ext;
		 y0 <= -yi_ext;
	      end
	  endcase // case(zi[zwidth-1:zwidth-2])
       end // else: !if(reset)
   
   // FIXME need to handle variable number of stages
   // This would be easier if arrays worked better in vlog...
   
   m_cordic_stage #(bitwidth+2,zwidth-1,0) cordic_stage0 (clock,reset,enable,x0,y0,z0,c00,flag0,x1,y1,z1,flag1);
   m_cordic_stage #(bitwidth+2,zwidth-1,1) cordic_stage1 (clock,reset,enable,x1,y1,z1,c01,flag1,x2,y2,z2,flag2);
   m_cordic_stage #(bitwidth+2,zwidth-1,2) cordic_stage2 (clock,reset,enable,x2,y2,z2,c02,flag2,x3,y3,z3,flag3);
   m_cordic_stage #(bitwidth+2,zwidth-1,3) cordic_stage3 (clock,reset,enable,x3,y3,z3,c03,flag3,x4,y4,z4,flag4);
   m_cordic_stage #(bitwidth+2,zwidth-1,4) cordic_stage4 (clock,reset,enable,x4,y4,z4,c04,flag4,x5,y5,z5,flag5);
   m_cordic_stage #(bitwidth+2,zwidth-1,5) cordic_stage5 (clock,reset,enable,x5,y5,z5,c05,flag5,x6,y6,z6,flag6);
   m_cordic_stage #(bitwidth+2,zwidth-1,6) cordic_stage6 (clock,reset,enable,x6,y6,z6,c06,flag6,x7,y7,z7,flag7);
   m_cordic_stage #(bitwidth+2,zwidth-1,7) cordic_stage7 (clock,reset,enable,x7,y7,z7,c07,flag7,x8,y8,z8,flag8);
   m_cordic_stage #(bitwidth+2,zwidth-1,8) cordic_stage8 (clock,reset,enable,x8,y8,z8,c08,flag8,x9,y9,z9,flag9);
   m_cordic_stage #(bitwidth+2,zwidth-1,9) cordic_stage9 (clock,reset,enable,x9,y9,z9,c09,flag9,x10,y10,z10,flag10);
   m_cordic_stage #(bitwidth+2,zwidth-1,10) cordic_stage10 (clock,reset,enable,x10,y10,z10,c10,flag10,x11,y11,z11,flag11);
   m_cordic_stage #(bitwidth+2,zwidth-1,11) cordic_stage11 (clock,reset,enable,x11,y11,z11,c11,flag11,x12,y12,z12,flag12);
   m_cordic_stage #(bitwidth+2,zwidth-1,12) cordic_stage12 (clock,reset,enable,x12,y12,z12,c12,flag12,x13,y13,z13,flag13);
   m_cordic_stage #(bitwidth+2,zwidth-1,13) cordic_stage13 (clock,reset,enable,x13,y13,z13,c13,flag13,x14,y14,z14,flag14);
   m_cordic_stage #(bitwidth+2,zwidth-1,14) cordic_stage14 (clock,reset,enable,x14,y14,z14,c14,flag14,x15,y15,z15,flag15);
   m_cordic_stage #(bitwidth+2,zwidth-1,15) cordic_stage15 (clock,reset,enable,x15,y15,z15,c15,flag15,x16,y16,z16,flag16);
   m_cordic_stage #(bitwidth+2,zwidth-1,16) cordic_stage16 (clock,reset,enable,x16,y16,z16,c16,flag16,x17,y17,z17,flag17);
   m_cordic_stage #(bitwidth+2,zwidth-1,17) cordic_stage17 (clock,reset,enable,x17,y17,z17,c17,flag17,x18,y18,z18,flag18);
   m_cordic_stage #(bitwidth+2,zwidth-1,18) cordic_stage18 (clock,reset,enable,x18,y18,z18,c18,flag18,x19,y19,z19,flag19);
   m_cordic_stage #(bitwidth+2,zwidth-1,19) cordic_stage19 (clock,reset,enable,x19,y19,z19,c19,flag19,x20,y20,z20,flag20);

   assign xo = x20[bitwidth:1];  
   assign yo = y20[bitwidth:1];
   assign zo = z20;		  
   assign flag_out = flag20;
		
endmodule // cordic

