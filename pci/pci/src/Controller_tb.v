`timescale 1us / 1ps

module tb_controller();

	// Inputs
	reg clk;
	reg reset;
	reg [3:0] force_request;
	reg [31:0] ADTC;
	reg [3:0] CB;
	reg [31:0] Device_Address_A;
	reg [31:0] Device_Address_B;
	reg [31:0] Device_Address_C;
	reg [31:0] Device_Address_D;

	// Outputs
	wire [3:0] req;
	wire [3:0] gnt;
	wire init_A,init_B,init_C,init_D;
	wire trgt_A,trgt_B,trgt_C,trgt_D;

	// Bidirs
	wire frame;
	wire [31:0] AD;
	wire [3:0] C_BE;
	wire irdy;
	wire trdy;
	wire DevSel;
	
	// arbiter
	arbiter arbt (clk,req,gnt);
	
	// Instantiate the Unit Under Test (UUT)
	Device_Controller Device_A (clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req[0],gnt[0],force_request[0], 
		ADTC,CB,Device_Address_A,init_A,trgt_A);
	Device_Controller Device_B (clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req[1],gnt[1],force_request[1], 
		ADTC,CB,Device_Address_B,init_B,trgt_B);
	Device_Controller Device_C (clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req[2],gnt[2],force_request[2], 
		ADTC,CB,Device_Address_C,init_C,trgt_C);
	Device_Controller Device_D (clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req[3],gnt[3],force_request[3], 
		ADTC,CB,Device_Address_D,init_D,trgt_D);
	
	assign frame = (!init_A && !init_B && !init_C && !init_D)? 1'b1:1'bz;
	assign irdy = (!init_A && !init_B && !init_C && !init_D)? 1'b1:1'bz;
	assign trdy = (!trgt_A && !trgt_B && !trgt_C && !trgt_D)? 1'b1:1'bz;
	assign DevSel = (!trgt_A && !trgt_B && !trgt_C && !trgt_D)? 1'b1:1'bz;

	initial begin
		// Initialize Inputs
		Device_Address_A = {{24{1'b0}},{2{4'b1010}}};
		Device_Address_B = {{24{1'b0}},{2{4'b1011}}};
		Device_Address_C = {{24{1'b0}},{2{4'b1100}}};
		Device_Address_D = {{24{1'b0}},{2{4'b1101}}};
		force_request = 4'b1111;
		clk = 1;
		reset = 1;
		#1
		reset = 0;
		#0.5
		force_request = 4'b1110;
		ADTC = {{24{1'b0}},{2{4'b1011}}};
		#1
		force_request = 4'b1111;
		#1
		CB = 4'b0101;
		#1
		CB = 4'b1111;
		#1
		force_request = 4'b1101;
		ADTC = {{24{1'b0}},{2{4'b1010}}};
		#1
		force_request = 4'b1111;
		#2
		CB = 4'b0011;
		#1
		CB = 4'b1111;
		#1
		force_request = 4'b1010;
		#1
		force_request = 4'b1011;
		#1
		force_request = 4'b1111;
		ADTC = {{24{1'b0}},{2{4'b1100}}};
		CB = 4'b0011;
		#1
		CB = 4'b1111;
		#3
		ADTC = {{24{1'b0}},{2{4'b1010}}};
		CB = 4'b0001;
		#1
		CB = 4'b1111;
		#2
		ADTC = {{24{1'b0}},{2{4'b1011}}};
		CB = 4'b0001;
		#1
		CB = 4'b1111;
	end
	
	always begin
		#0.5 clk = ~clk;
	end
      
endmodule

