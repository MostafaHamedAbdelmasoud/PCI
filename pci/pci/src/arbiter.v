`timescale 1us / 1ps

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
