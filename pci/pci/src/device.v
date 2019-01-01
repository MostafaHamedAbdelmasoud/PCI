`timescale 1us / 1ps

module Device_Controller(clk,reset,frame,AD,C_BE,irdy,trdy,DevSel,req,gnt,
force_request,ADTC,CB,Device_Address,init,trgt);
input clk,reset,gnt,force_request;
input [31:0] ADTC,Device_Address;
input [3:0] CB;
inout frame,irdy,trdy,DevSel;
output reg req,init,trgt;
inout [31:0] AD;
inout [3:0] C_BE;
reg frm,irdyB,trdyB,ds,rw;
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
					ADB <= {4{Device_Address[7:0]}};
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
					ADB <= {4{Device_Address[7:0]}};
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
					if(BE[1]==1'b1) begin
						memory[mp][15:8] <= data[15:8];
					end
					if(BE[2]==1'b1) begin
						memory[mp][23:16] <= data[23:16];
					end
					if(BE[3]==1'b1) begin
						memory[mp][31:24] <= data[31:24];
					end
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
