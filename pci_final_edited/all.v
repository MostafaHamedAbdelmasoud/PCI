`timescale 1us / 1ps

module Device(clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req,gnt,
force_request,ADTC,CB,Device_Address,F_DATA,init,trgt);
//comes from tb
input clk,reset,force_request;
input [31:0] ADTC,Device_Address,F_DATA;
input [3:0] CB;//{[0] -> 0 write 1 read ---[1:3] num of data transaction }at first then it work bit enable 

// come frome other dev
input gnt;
inout frame,irdy,trdy,DevSel;
inout [31:0] AD;
inout [3:0] C_BE;

output reg req,init,trgt;//init & target to see which one device set as iniator&target
// internal reg
reg frm,irdyB,trdyB,ds,rw;// frame - irdy-trdy-devsel-readword 
reg [3:0] CMD,BE;
reg [31:0] ADB,data;
reg [1:0] role;
reg [2:0] state,previous_state,counter,DPh;
reg [31:0] memory [0:7];  //for storing entry
reg [2:0] mp;             //memmory pointer

parameter
	target=2'b00,
	initiator=2'b01,
	none=2'b11;

parameter[2:0] 
	idle=3'b000,
	bus_granted=3'b001,
	device_select=3'b010,
	RDY=3'b011,
	Check=3'b100,
	transaction=3'b101;

assign frame = frm;
assign irdy = irdyB;
assign trdy = trdyB;
assign DevSel = ds;
assign AD = ADB;
assign C_BE = CMD;
//////////////part1
always @(force_request, reset, state, previous_state)
begin
	if(reset) begin
		req <= 1'b1;
		role <= none;
	end
	else if(!force_request) begin
		req <= 1'b0;	
	end
	else if(previous_state == bus_granted && counter==3'b001) begin
		req <= 1'b1;
	end
	if(state == bus_granted) begin
		role <= initiator;
	end
	else if(state == device_select) begin
		role <= target;
	end
	else if(gnt && frame && irdy && previous_state == idle) begin
		role <= none;
	end
end
///part 2
always @(posedge clk)
begin
	if(reset) begin
		counter <= 3'b000;
	end
	else if(!force_request && role == initiator && previous_state == transaction && DPh==3'b000) begin     
      counter <= counter; 
	end
	else if(!force_request) begin     
      counter <= counter + 3'b001; 
	end
	else if(role == initiator && previous_state == transaction && DPh==3'b000 && counter!=3'b000) begin
		counter <= counter - 3'b001;
	end
	if(!gnt && frame && irdy && (previous_state == transaction || previous_state == idle || role == none)) begin
		state <= bus_granted;
	end
	else if(AD == Device_Address && !frame && irdy && (previous_state == idle || role == none)) begin
		state <= device_select;
		rw <= C_BE[0];
		DPh <= C_BE[3:1];
	end
	else if(previous_state == bus_granted || (previous_state == device_select && rw==1'b0)) begin
		state <= RDY;
		if(init) begin
			rw <= CMD[0];
			DPh <= CMD[3:1];
		end
	end
	else if(rw==1'b0 && previous_state == RDY && init) begin
		state <= Check;
	end
	else if(!irdy && !trdy) begin
		if((init && !rw) || (trgt && rw)) begin
			data <= AD;
			if(trgt && rw) begin
				BE <= C_BE;
			end
		end
		if(previous_state == Check || previous_state == RDY || (previous_state == device_select && rw==1'b1)) begin
			state <= transaction;
		end
		else if(DPh!=3'b000) begin
			DPh <= DPh - 3'b001;
		end
	end
	else if(gnt && frame && irdy && previous_state == transaction) begin
		state <= idle;
	end
end
////part3
always @(negedge clk)
begin
	if(role == initiator)
	begin
		case(state)
			idle: begin
				frm <= 1'bz;
				irdyB <= 1'bz;
				init <= 1'b0;
			end
			bus_granted: begin
				init <= 1'b1;
				trgt <= 1'b0;
				trdyB <= 1'bz;
				ds <= 1'bz;
				frm <= 1'b0;
				irdyB <= 1'b1;
				ADB <= ADTC;
				CMD <= CB;
			end
			RDY: begin
				irdyB <= 1'b0;
				CMD <= CB;
				if(rw==1'b0) begin
					ADB <= {32{1'bz}};
				
				end
				else if(rw==1'b1) begin
					ADB <= F_DATA;
					
					if(DPh==3'b000) begin
						frm <= 1'b1;
					end
				end
			end
			Check: begin
				if(DPh==3'b000) begin
					frm <= 1'b1;
				end
			end
			transaction: begin
				CMD <= CB;
				if(DPh==3'b001) begin
					frm <= 1'b1;
				end
				else if(DPh==3'b000) begin
					irdyB <= 1'b1;
					ADB <= {32{1'bz}};
					CMD <= 4'bzzzz;
					mp <= 3'b000;
				end
				if(rw==1'b0) begin
					memory[mp] <= data;
					if(DPh!=3'b000) begin
						mp <= mp + 3'b001;
					end
				end
			end
		endcase
	end
	else if(role == target)
	begin
		case(state)
			idle: begin
				trdyB <= 1'bz;
				ds <= 1'bz;
				trgt <= 1'b0;
			end
			device_select: begin
				trgt <= 1'b1;
				init <= 1'b0;
				frm <= 1'bz;
				irdyB <= 1'bz;
				ds <= 1'b0;
				if(rw==1'b1) begin
					trdyB <= 1'b0;
				end
				else if(rw==1'b0) begin
					trdyB <= 1'b1;
				end
			end
			RDY: begin
				if(rw==1'b0) begin
					ADB <= F_DATA;
					trdyB <= 1'b0;
				end
				else if(rw==1'b1) begin
					ADB <= {32{1'bz}};
				end
			end
			transaction: begin
				if(DPh==3'b000) begin
					trdyB <= 1'b1;
					ds <= 1'b1;
					ADB <= {32{1'bz}};
					mp <= 3'b000;
				end
				if(rw==1'b1) begin
					if(BE[0]==1'b1) begin
						memory[mp][7:0] <= data[7:0];
						
					end
					else memory[mp][7:0]<=8'hzz;
					if(BE[1]==1'b1) begin
						memory[mp][15:8] <= data[15:8];
					end
					else memory[mp][15:8]<=8'hzz;
					if(BE[2]==1'b1) begin
						memory[mp][23:16] <= data[23:16];
					end
					else memory[mp][23:16]<=8'hzz;
					if(BE[3]==1'b1) begin
						memory[mp][31:24] <= data[31:24];
					end
					else memory[mp][31:24]<=8'hzz;
					if(DPh!=3'b000) begin
						mp <= mp + 3'b001;
					end
				end
			end
		endcase
	end
	else if(role == none) begin
		frm <= 1'bz;
		irdyB <= 1'bz;
		trdyB <= 1'bz;
		ds <= 1'bz;
		ADB <= {32{1'bz}};
		CMD <= 4'bzzzz;
		init <= 1'b0;
		trgt <= 1'b0;
		mp <= 3'b000;
	end
	previous_state <= state;
end

endmodule


module arbiter(clk,req,gnt);
input clk;
input [3:0] req;
output reg [3:0] gnt;
reg [3:0] wgnt;

always @(posedge clk)
begin
	if(req[0]==0) begin
		wgnt <= 4'b1110;
	end
	else if (req[1]==0) begin
		wgnt <= 4'b1101;
	end
	else if (req[2]==0) begin
		wgnt <= 4'b1011;
	end
	else if (req[3]==0) begin
		wgnt <= 4'b0111;
	end
	else begin
		wgnt <= 4'b1111;
	end
end

always @(negedge clk) begin
	gnt <= wgnt;
end

endmodule



module tb();

	// Inputs
	reg clk;
	reg reset;
	reg [3:0] force_request;
	reg [31:0] ADTC;
	reg [3:0] CB;
	reg [31:0] Device_Address_A,F_DATAA;
	reg [31:0] Device_Address_B,F_DATAB;
	reg [31:0] Device_Address_C,F_DATAC;


	// Outputs
	wire [3:0] req;
	wire [3:0] gnt;
	wire init_A,init_B,init_C;
	wire trgt_A,trgt_B,trgt_C;

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
	Device Device_A (clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req[0],gnt[0],force_request[0], 
		ADTC,CB,Device_Address_A,F_DATAA,init_A,trgt_A);
	Device Device_B (clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req[1],gnt[1],force_request[1], 
		ADTC,CB,Device_Address_B,F_DATAB,init_B,trgt_B);
	Device Device_C (clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req[2],gnt[2],force_request[2], 
		ADTC,CB,Device_Address_C,F_DATAC,init_C,trgt_C);
		
	assign frame = (!init_A && !init_B && !init_C )? 1'b1:1'bz;
	assign irdy = (!init_A && !init_B && !init_C )? 1'b1:1'bz;
	assign trdy = (!trgt_A && !trgt_B && !trgt_C )? 1'b1:1'bz;
	assign DevSel = (!trgt_A && !trgt_B && !trgt_C )? 1'b1:1'bz;

	initial begin
		// Initialize Inputs
		F_DATAA=32'hAAAAAAAA;
		F_DATAB=32'hBBBBBBBB;
		F_DATAC=32'hCCCCCCCC;
		Device_Address_A = {{24{1'b0}},{2{4'b1010}}};
		Device_Address_B = {{24{1'b0}},{2{4'b1011}}};
		Device_Address_C = {{24{1'b0}},{2{4'b1100}}};
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
		
		
		// for bit enable 
	
			#2
		force_request = 4'b1110;//dev a
		ADTC = {{24{1'b0}},{2{4'b1100}}};//connect to dev c
		
		F_DATAA=32'hFFFFFFFF;
		#1
			force_request = 4'b1111;
			#1
		CB = 4'b0001;//write one word 
		#1
		CB = 4'b1001; // at byte 0 and 3
		
			/*
		//for read
	
		
			#2
		force_request = 4'b1110;//dev a
		ADTC = {{24{1'b0}},{2{4'b1011}}};//connect to dev b
		
		F_DATAA=32'hzzzzzzzz;
		#1
			force_request = 4'b1111;
			#1
		CB = 4'b0000;//read one word 
		#1
		CB = 4'b1111; // at byte 0 and 3
	*/
			
	end
	
	always begin
		#0.5 clk = ~clk;
	end
      
endmodule

