
`timescale 1ns/10ps

module  CONV(
	//system input
	clk,
	reset,
	busy,	
	ready,	
	//image data read	
	iaddr,
	idata,	
	//conv mem write
	cwr,
	caddr_wr,
	cdata_wr,
	//conv mem read
	crd,
	caddr_rd,
	cdata_rd,
	//select mem
	csel,
	state
	);

//define input and output
input			clk;
input			reset;
output			busy;	
input			ready;			
output [11:0]	iaddr;
input  [19:0]	idata;	
output	 		cwr;
output [11:0]	caddr_wr;
output [19:0]	cdata_wr;
output	 		crd;
output [11:0]	caddr_rd;
input  [19:0] 	cdata_rd;
output [2:0]	csel;
output [3:0]	state;

reg 			busy; 		//ready to high 
wire [11:0] 	iaddr; 		// pixel addr V
reg 			crd; 		// conv read mem if 1 V 
wire [11:0] 	caddr_rd; 	//conv read mem addr 
reg 			cwr; 		//comv write enable if 1 V
wire [19:0] 	cdata_wr; 	// write data 4 bit int and 16 bit float V 
reg [11:0] 		caddr_wr; 	// write addr V
reg [2:0]		csel; 		// 0 --> none 1 ---> layer 0 kernel 0 2 ---> layer 0 kernel 1 3 ---> layer 1 kernel 0 4 ---> layer 1 kernel 1 5 ---> layer2 flatten
wire [3:0] 		state;


//define register to store data
wire [39:0] 		conv_tmp1;
wire [39:0] 		conv_tmp2;
wire [19:0]			max_pool;
reg [5:0] 			x;
reg [5:0] 			y;
reg signed [39:0]	img_data1;
reg signed [39:0]	img_data2;
reg signed [19:0]	conv1_result;
reg signed [19:0]	conv2_result;
reg signed [19:0]	now_kernel1;
reg signed [19:0]	now_kernel2;
reg [3:0]			cur_state;
reg [3:0]			next_state;
//reg [3:0]			counter;
reg [1:0]			row;
reg [1:0]			col;
wire signed [19:0]	read_buf;
integer i;
wire [5:0]			x_plus1;
//define state mechine
localparam READ_IMG_DATA			= 4'd0;
localparam INIT 					= 4'd1;
localparam CONV 					= 4'd2;
localparam STORE_CONV1 				= 4'd3;
localparam STORE_CONV2 				= 4'd4;
localparam READ_CONV1_DATA 			= 4'd5;
localparam MAX_POOLING_AND_STORE_1	= 4'd6;
localparam READ_CONV2_DATA 			= 4'd7;
localparam MAX_POOLING_AND_STORE_2	= 4'd8;
localparam DONE						= 4'd9;
localparam FLATTEN_1				= 4'd10;
localparam FLATTEN_2				= 4'd11;


parameter signed kernel000 	= 20'h0A89E;
parameter signed kernel001 	= 20'h092D5;
parameter signed kernel002 	= 20'h06D43;
parameter signed kernel010 	= 20'h01004;
parameter signed kernel011 	= 20'hF8F71;
parameter signed kernel012 	= 20'hF6E54;
parameter signed kernel020 	= 20'hFA6D7;
parameter signed kernel021 	= 20'hFC834;
parameter signed kernel022 	= 20'hFAC19;
parameter signed bias0 		= 20'h01310;

parameter signed kernel100 	= 20'hFDB55;
parameter signed kernel101 	= 20'h02992;
parameter signed kernel102 	= 20'hFC994;
parameter signed kernel110 	= 20'h050FD;
parameter signed kernel111 	= 20'h02F20;
parameter signed kernel112	= 20'h0202D;
parameter signed kernel120 	= 20'h03BD7;
parameter signed kernel121 	= 20'hFD369;
parameter signed kernel122 	= 20'h05E68;
parameter signed bias1 		= 20'hF7295;

assign read_buf = ( ( row  + { 1'b0 , y } ) == 7'd0 || ( { 1'b0 , x } + col ) == 7'd0 || ( row  + { 1'b0 , y } ) == 7'd65 || ( { 1'b0 , x } + col ) == 7'd65 ) ? 20'd0 : idata; //zero padding when x at 0 or x at 65 or y = 0 or y = 65
assign iaddr =  { ( ( { 4'b0000 , row } + y ) - 6'd1 ) , ( ( { 4'b0000 , col } + x ) - 6'd1 ) };
//assign cdata_wr = ( cur_state == STORE_CONV1 ) ? conv1_result : conv2_result;
assign cdata_wr = ( cur_state == STORE_CONV1 || cur_state == MAX_POOLING_AND_STORE_1 || cur_state == FLATTEN_1 ) ? conv1_result : conv2_result;
assign caddr_rd =  { ( { 4'b0000 , row } + y ) , ( { 4'b0000 , col } + x ) };
assign conv_tmp1 = read_buf * now_kernel1;
assign conv_tmp2 = read_buf * now_kernel2;
assign max_pool = (cur_state == READ_CONV1_DATA ) ? ( ( conv1_result > cdata_rd ) ? conv1_result : cdata_rd ) : ( ( conv2_result > cdata_rd ) ? conv2_result : cdata_rd );
assign x_plus1 = x + 1;
assign state = cur_state;

always @ (*) begin
	case ( (row << 1 ) + ( row + col ) )
		4'd0 : begin
			now_kernel1 = kernel000;
			now_kernel2 = kernel100;
		end
		4'd1 : begin
			now_kernel1 = kernel001;
			now_kernel2 = kernel101;
		end
		4'd2 : begin
			now_kernel1 = kernel002;
			now_kernel2 = kernel102;
		end
		4'd3 : begin
			now_kernel1 = kernel010;
			now_kernel2 = kernel110;
		end
		4'd4 : begin
			now_kernel1 = kernel011;
			now_kernel2 = kernel111;
		end
		4'd5 : begin
			now_kernel1 = kernel012;
			now_kernel2 = kernel112;
		end
		4'd6 : begin
			now_kernel1 = kernel020;
			now_kernel2 = kernel120;
		end
		4'd7 : begin
			now_kernel1 = kernel021;
			now_kernel2 = kernel121;
		end
		4'd8 : begin
			now_kernel1 = kernel022;
			now_kernel2 = kernel122;
		end
		default : begin
			now_kernel1 = kernel000;
			now_kernel2 = kernel100;
		end
	endcase
end


always @ ( posedge clk or posedge reset ) begin
	if ( reset ) begin
		//counter <= 4'd0;
		x <= 6'd0;
		y <= 6'd0;
		cur_state <= INIT;
		img_data1 <= 40'd0;
		img_data2 <= 40'd0;
		col <= 0;
		row <= 0;
		conv1_result <= 20'd0;
		conv2_result <= 20'd0;
		busy <= 1'b0;
	end
	else begin
		case (cur_state)
			INIT: begin
				cur_state <= next_state;
				busy <= 1'b0;
			end
			READ_IMG_DATA : begin
				busy <= 1'b1;
				//counter <= counter + 1'b1;
				cur_state <= next_state;
				if ( col == 2'd0 && row == 2'd0 ) begin
					img_data1 <= conv_tmp1 + {4'b0000,bias0,16'b0};
					img_data2 <= conv_tmp2 + {4'b1111,bias1,16'b0};
				end
				else begin
					img_data1 <= img_data1 + conv_tmp1;
					img_data2 <= img_data2 + conv_tmp2;
				end
				if ( col == 2'd2 ) begin
					row <= row + 2'd1;
					col <= 2'd0;
				end
				else begin
					row <= row;
					col <= col + 2'd1;
				end
			end
			CONV : begin
				busy <= 1'b1;
				cur_state <= next_state;
				//counter <= 0;
				row <= 0;
				col <= 0;
				conv1_result <= ( img_data1[39] == 1'b1 ) ? 20'b0 : img_data1[35:16] + img_data1[15];
				conv2_result <= ( img_data2[39] == 1'b1 ) ? 20'b0 : img_data2[35:16] + img_data2[15];
			end
			STORE_CONV1 : begin
				busy <= 1'b1;
				cur_state <= next_state;
			end
			STORE_CONV2 : begin
				busy <= 1'b1;
				cur_state <= next_state;
				x <= x + 6'd1;
				if ( x == 6'd63 ) 
					y <= y + 6'd1;
				else 
					y <= y;
			end
			READ_CONV1_DATA : begin
				busy <= 1'b1;
				//counter <= counter + 1'b1;
				if ( col == 0 && row == 0) 
					conv1_result <= cdata_rd;
				else 
					conv1_result <= max_pool;  
				cur_state <= next_state;
				if ( col == 2'd1 ) begin
					row <= row + 2'd1;
					col <= 2'd0;
				end
				else begin
					row <= row;
					col <= col + 2'd1;
				end
			end
			MAX_POOLING_AND_STORE_1 : begin
				busy <= 1'b1;
				cur_state <= next_state;
			end
			FLATTEN_1 : begin
				busy <= 1'b1;
				x <= x + 6'd2;
				if ( x == 6'd62 ) 
					y <= y + 6'd2;
				else 
					y <= y;
				col <= 2'd0;
				row <= 2'd0;
				cur_state <= next_state;
			end
			READ_CONV2_DATA : begin
				busy <= 1'b1;
				if ( col == 0 && row == 0) 
					conv2_result <= cdata_rd;
				else 
					conv2_result <= max_pool;  
				cur_state <= next_state;
				if ( col == 2'd1 ) begin
					row <= row + 2'd1;
					col <= 2'd0;
				end
				else begin
					row <= row;
					col <= col + 2'd1;
				end
				cur_state <= next_state;
			end
			MAX_POOLING_AND_STORE_2 : begin
				busy <= 1'b1;
				cur_state <= next_state;
			end
			FLATTEN_2 : begin
				busy <= 1'b1;
				x <= x + 6'd2;
				if ( x == 6'd62 ) 
					y <= y + 6'd2;
				else 
					y <= y;
				col <= 2'd0;
				row <= 2'd0;
				cur_state <= next_state;
			end
			DONE : begin
				cur_state <= next_state;
				busy <= 1'b0;
			end
			default : begin
				row <= 2'd0;
				col <= 2'd0;
				cur_state <= next_state;
				x <= 6'd0;
				y <= 6'd0;

			end	
		endcase
	end

end


always@ ( * ) begin
	case (cur_state)
		INIT: begin
			if ( ready )
				next_state = READ_IMG_DATA;
			else
				next_state = INIT;
		end
		READ_IMG_DATA : begin
			if ( row == 2'd2 && col == 2'd2 )
				next_state = CONV;
			else
				next_state = READ_IMG_DATA;
		end
		CONV : begin
			next_state = STORE_CONV1;
		end
		STORE_CONV1 : begin
			next_state = STORE_CONV2;
		end
		STORE_CONV2 : begin
			if ( x == 6'd63 && y == 6'd63 )
				next_state = READ_CONV1_DATA;
			else
				next_state = READ_IMG_DATA;
		end
		READ_CONV1_DATA : begin
			if ( col == 2'd1 && row == 2'd1 )
				next_state = MAX_POOLING_AND_STORE_1;
			else
				next_state = READ_CONV1_DATA;
		end
		MAX_POOLING_AND_STORE_1 : begin
			next_state = FLATTEN_1;
		end
		READ_CONV2_DATA : begin
			if ( col == 2'd1 && row == 2'd1 )
				next_state = MAX_POOLING_AND_STORE_2;
			else
				next_state = READ_CONV2_DATA;
		end
		MAX_POOLING_AND_STORE_2 : begin
			next_state = FLATTEN_2;
		end
		FLATTEN_1 : begin
			if ( x == 6'd62 && y == 6'd62 )
				next_state = READ_CONV2_DATA;
			else
				next_state = READ_CONV1_DATA;
		end
		FLATTEN_2 : begin
			if ( x == 6'd62 && y == 6'd62 )
				next_state = DONE;
			else
				next_state = READ_CONV2_DATA;
		end
		DONE : begin
			next_state = DONE;
		end
		default : begin
			next_state = INIT;
		end	
	endcase
end

always @ ( * ) begin
	//busy = 1'b1;
	case (cur_state)
		INIT: begin
			//busy = 1'b0;
			crd = 1'b0;
			csel = 3'b000;
			caddr_wr = 12'd0;
			cwr = 1'b0;
		end
		READ_IMG_DATA : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b000;
			caddr_wr = 12'd0;
			cwr = 1'b0;
		end
		CONV : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b000;
			caddr_wr = 12'd0;
			cwr = 1'b0;
		end
		STORE_CONV1 : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b001;
			caddr_wr = { y , x };
			cwr = 1'b1;
		end
		STORE_CONV2 : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b010;
			caddr_wr = { y , x };
			cwr = 1'b1;
		end
		READ_CONV1_DATA : begin
			//busy = 1'b1;
			crd = 1'b1;
			csel = 3'b001;
			caddr_wr = 12'd0;
			cwr = 1'b0;
		end
		MAX_POOLING_AND_STORE_1 : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b011;
			caddr_wr = { { 2'b00 , y[5:1] , x[5:1] } };
			cwr = 1'b1;
		end
		READ_CONV2_DATA : begin
			//busy = 1'b1;
			crd = 1'b1;
			csel = 3'b010;
			caddr_wr = 12'd0;
			cwr = 1'b0;
		end
		MAX_POOLING_AND_STORE_2 : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b100;
			caddr_wr = { { 2'b00 , y[5:1] , x[5:1] } };
			cwr = 1'b1;
		end
		FLATTEN_1 : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b101;
			caddr_wr = { 1'b0 , y[5:1] , x };
			cwr = 1'b1;
		end
		FLATTEN_2 : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b101;
			caddr_wr = { 1'b0 , y[5:1] , x_plus1 };
			cwr = 1'b1;
		end
		DONE : begin
			//busy = 1'b0;
			crd = 1'b0;
			csel = 3'b000;
			cwr = 1'b0;
			caddr_wr = 12'd0;
		end
		default : begin
			//busy = 1'b1;
			crd = 1'b0;
			csel = 3'b000;
			cwr = 1'b0;
			caddr_wr = 12'd0;
			
		end	
	endcase
end

endmodule




