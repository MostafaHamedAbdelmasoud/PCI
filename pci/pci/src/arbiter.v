module STACK_ENHANCED (POP,CLK,IN,OUT);
  input CLK,POP;
  input [7:0] IN;
  output [7:0] OUT;
  assign OUT = stack[0];
  reg [7:0] SR=255;
  reg [2:0] SP = 0;
  reg [7:0] stack [0:7]; //including a history bit
  reg [2:0] i;

  always @ (posedge CLK) begin
    //$display("%b %b",SR,IN);
    if(IN[0] ==0 & SR[0] ==1) begin
        SR[0] <=0;
        stack[SP] <= 8'b11111110;
        SP<=SP+1;
    end
    else if(IN[1] ==0 & SR[1] ==1) begin
        SR[1] <=0;
        stack[SP] <= 8'b11111101;
        SP<=SP+1;
    end
    else if(IN[2] ==0 & SR[2] ==1) begin
        SR[2] <=0;
        stack[SP] <= 8'b11111011;
        SP<=SP+1;
    end
    else if(IN[3] ==0 & SR[3] ==1) begin
        SR[3] <=0;
        stack[SP] <= 8'b11110111;
        SP<=SP+1;
    end
    else if(IN[4] ==0 & SR[4] ==1) begin
        SR[4] <=0;
        stack[SP] <= 8'b11101111;
        SP<=SP+1;
    end
    else if(IN[5] ==0 & SR[5] ==1) begin
        SR[5] <=0;
        stack[SP] <= 8'b11011111;
        SP<=SP+1;
    end
    else if(IN[6] ==0 & SR[6] ==1) begin
        SR[6] <=0;
        stack[SP] <= 8'b10111111;
        SP<=SP+1;
    end
    else if(IN[7] ==0 & SR[7] ==1) begin
        SR[7] <=0;
        stack[SP] <= 8'b01111111;
        SP<=SP+1;
    end
  end

  always @ (negedge CLK) begin
    if(POP & SP>1) begin
      SR<=~OUT | SR;
      stack[0] <= stack[1];
      stack[1] <= stack[2];
      stack[2] <= stack[3];
      stack[3] <= stack[4];
      stack[4] <= stack[5];
      stack[5] <= stack[6];
      stack[6] <= stack[7];
      //stack[7] <= stack[8];
      SP=SP-1;
    end
    else if(SP==0) stack[0]=255;
  end
endmodule // STACK_ENHANCED


module STACK_ENH (POP,CLK,IN,OUT);
  input CLK,POP;
  input [7:0] IN;
  output reg [7:0] OUT;

  reg [7:0] OUT_POS;
  reg [7:0] SR=255;
  reg [2:0] SP = 0;
  reg [7:0] stack [0:7];
  reg [7:0] history ;
  reg state=0;
  parameter ready=0,pauseReq=1;
endmodule //

module PCI_ARBITER (CLK,REQ,FRAME,IRDY,GNT);
  input CLK,FRAME,IRDY;
  input [7:0] REQ;
  output [7:0] GNT;
  reg [1:0]state=1;
  reg POP = 0;
  STACK_ENHANCED stack(POP,CLK,REQ,GNT);
  parameter [1:0] justGranted=1,startedWorking=2,nextGrantedNotOnBus=3;
  always @ (posedge CLK) begin
    //
    // if(state==justGranted & (FRAME & IRDY)) begin
    //   state<=justGranted;
    // end
    if(state==justGranted & (FRAME & IRDY)) begin
      state<=justGranted;
    end
    else if(state==justGranted & ~(FRAME & IRDY)) begin
      state<=startedWorking;
      POP<=1;
    end
    else if(state==startedWorking & (FRAME & IRDY)) begin
      state<=justGranted;
      POP<=1;
    end
  end
  always @ (negedge CLK) begin
     POP<=0;
  end
endmodule // PCI_ARBITER
