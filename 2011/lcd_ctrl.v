module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output IROM_EN;
output [5:0] IROM_A;
output IRB_RW;
output [7:0] IRB_D;
output [5:0] IRB_A;
output busy;
output done;
	
	reg [1:0]cs, ns;
	reg [5:0]counter, nextCounter;
	reg [2:0]x, nextX;
	reg [2:0]y, nextY;
	reg [2:0]command;
	
	reg busy, done, inputEn;
	reg [7:0]data[63:0];
	
	wire en;
	wire [5:0]addr0, addr1, addr2, addr3;
	wire [7:0]dout0, dout1, dout2, dout3;
	wire [7:0]din0, din1, din2, din3;
	wire [9:0]sum;
	wire [7:0]avg;
	
	integer i;
	
	parameter INPUT = 2'b00, CMD = 2'b01, OPER = 2'b10, WRITE = 2'b11;
	
	always@(*)
	begin
		case(cs)
		INPUT :
		begin
			ns = (&counter) ? CMD : INPUT;
			nextCounter = (!IROM_EN) ? counter + 1'd1 : counter;
			nextX = 3'd4;
			nextY = 3'd4;
		end
		CMD :
		begin
			ns = (cmd_valid) ? OPER : CMD;
			nextCounter = 6'd0;
			nextX = x;
			nextY = y;
		end
		OPER :
		begin
			ns = (command == 3'd0) ? WRITE : CMD;
			nextCounter = counter;
			nextX = ((command == 3'd3)&&(x != 3'd1)) ? x - 1'b1 :
			        ((command == 3'd4)&&(x != 3'd7)) ? x + 1'b1 : x;
			nextY = ((command == 3'd1)&&(y != 3'd1)) ? y - 1'b1 :
			        ((command == 3'd2)&&(y != 3'd7)) ? y + 1'b1 : y;
		end
		WRITE :
		begin
			ns = WRITE;
			nextCounter = counter + 1'd1;
			nextX = x;
			nextY = y;
		end
		endcase
	end
	
	assign addr0 = addr1 - 1'b1;
	assign addr1 = x+((y-1) << 3);
	assign addr2 = addr3 - 1'b1;
	assign addr3 = x+(y << 3);
	
	assign dout0 = data[addr0];
	assign dout1 = data[addr1];
	assign dout2 = data[addr2];
	assign dout3 = data[addr3];
	
	assign sum = (dout0 + dout1) + (dout2 + dout3);
	assign avg = sum >> 2;
	
	assign en = ((cs == OPER)&&((command == 3'd5)||(command == 3'd6)||(command == 3'd7)));
	assign din0 = (command == 3'd5) ? avg : 
	              (command == 3'd6) ? dout2 : dout1;
	assign din1 = (command == 3'd5) ? avg : 
	              (command == 3'd6) ? dout3 : dout0;
	assign din2 = (command == 3'd5) ? avg : 
	              (command == 3'd6) ? dout0 : dout3;
	assign din3 = (command == 3'd5) ? avg : 
	              (command == 3'd6) ? dout1 : dout2;
	
	assign IROM_A = counter;
	assign IROM_EN = ((cs != INPUT)&&(!reset));
	
	assign IRB_D = data[counter];
	assign IRB_A = counter;
	assign IRB_RW = 1'b0;
	
		always@(posedge clk or posedge reset)
	begin
		if(reset)
		begin
			cs <= INPUT;
			counter <= 6'b0;
			x <= 6'b0;
			y <= 6'b0;
			command <= 3'b0;
			
			busy <= 1'b1;
			done <= 1'b0;
			inputEn <= 1'b0;
		end
		else
		begin
			cs <= ns;
			counter <= nextCounter;
			x <= nextX;
			y <= nextY;
			command <= (cmd_valid) ? cmd : command;
			
			busy <= ((cs == CMD)&&(!cmd_valid)) ? 1'b0 : 1'b1;
			done <= ((cs == WRITE)&&(&counter));
			inputEn <= IROM_EN;
		end
	end
	
	always@(posedge clk or posedge reset)
	begin
		if(reset) for(i = 0; i < 64; i = i + 1) data[i] <= 8'b0;
		else
		begin
			if(!inputEn) data[counter-1'b1] <= IROM_Q;
			else if(en)
			begin
				data[addr0] <= din0;
				data[addr1] <= din1;
				data[addr2] <= din2;
				data[addr3] <= din3;
			end
		end
	end
	
endmodule

