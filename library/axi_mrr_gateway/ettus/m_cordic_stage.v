// -*- verilog -*-
//
//  USRP - Universal Software Radio Peripheral
//
//  Copyright (C) 2003 Matt Ettus
//

//

module m_cordic_stage( clock, reset, enable, xi,yi,zi,constant,flag_in,xo,yo,zo,flag_out);
   parameter bitwidth = 16;
   parameter zwidth = 16;
   parameter shift = 1;
   
   input     clock;
   input     reset;
   input     enable;
   input     flag_in;
   input [bitwidth-1:0] xi,yi;
   input [zwidth-1:0] zi;
   input [zwidth-1:0] constant;
   output [bitwidth-1:0] xo,yo;
   output [zwidth-1:0] zo;
   output     flag_out;
   
   wire z_is_pos = ~zi[zwidth-1];

   reg [bitwidth-1:0] 	 xo,yo;
   reg [zwidth-1:0] zo;
   reg	     flag_out;
   
   always @(posedge clock)
     if(reset)
       begin
	  xo <= 0;
	  yo <= 0;
	  zo <= 0;
	  flag_out <= 0;
       end
     else //if(enable)
       begin
	  xo <= z_is_pos ?   
		xi - {{shift+1{yi[bitwidth-1]}},yi[bitwidth-2:shift]} :
		xi + {{shift+1{yi[bitwidth-1]}},yi[bitwidth-2:shift]};
	  yo <= z_is_pos ?   
		yi + {{shift+1{xi[bitwidth-1]}},xi[bitwidth-2:shift]} :
		yi - {{shift+1{xi[bitwidth-1]}},xi[bitwidth-2:shift]};
	  zo <= z_is_pos ?   
		zi - constant :
		zi + constant;
	  flag_out <= flag_in;
       end
endmodule
