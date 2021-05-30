
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	    clk;
input   	    reset;
output  [13:0] 	gray_addr;  //img addr
output         	gray_req;   //high --> get data
input   	    gray_ready; //high --> readt to get data
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;   
output  	    lbp_valid;  // if done ---> high
output  [7:0] 	lbp_data;
output  	    finish;
//====================================================================

reg  [13:0] 	lbp_addr;   
reg  	        lbp_valid;  // if done ---> high
reg  [7:0] 	    lbp_data;
reg  	        finish;
reg  [13:0] 	gray_addr;  //img addr
reg         	gray_req;   //high --> get data

reg [3:0]       cur_state;
reg [3:0]       next_state;
reg [13:0]      addr;
reg [7:0]       mid_value;

parameter       GetMidData  = 0;
parameter       LeftUP      = 1;
parameter       MidUp       = 2;
parameter       RightUp     = 3;
parameter       Left        = 4;
parameter       Right       = 5;
parameter       LeftDown    = 6;
parameter       MidDown     = 7;
parameter       RightDown   = 8;
parameter       WriteData   = 9;

always@ ( posedge clk or posedge reset ) begin
    if ( reset ) begin
        cur_state <= GetMidData;
        addr <= 14'd129;
        mid_value <= 0;
        finish <= 0;
        lbp_addr <= 14'd129;
        lbp_valid <= 0;
        gray_addr <= 14'd129;
        lbp_data <= 0;
        gray_req <= 1;
    end
    else begin
        if ( gray_ready ) begin
            cur_state <= next_state;
            case ( cur_state )
                GetMidData : begin
                    mid_value <= gray_data;
                    gray_addr <= gray_addr - 129;
                end
                LeftUP : begin
                    if ( gray_data >= mid_value )
                        lbp_data[0] <= 1'b1;
                    gray_addr <= gray_addr + 1;
                end
                MidUp : begin
                    if ( gray_data >= mid_value )
                        lbp_data[1] <= 1'b1;
                    gray_addr <= gray_addr + 1;
                end
                RightUp : begin
                    if ( gray_data >= mid_value )
                        lbp_data[2] <= 1'b1;
                    gray_addr <= gray_addr + 126;
                end
                Left : begin
                    if ( gray_data >= mid_value )
                        lbp_data[3] <= 1'b1;
                    gray_addr <= gray_addr + 2;
                end
                Right : begin
                    if ( gray_data >= mid_value )
                        lbp_data[4] <= 1'b1;
                    gray_addr <= gray_addr + 126;
                end
                LeftDown : begin
                    if ( gray_data >= mid_value )
                        lbp_data[5] <= 1'b1;
                    gray_addr <= gray_addr + 1;
                end
                MidDown : begin
                    if ( gray_data >= mid_value )
                        lbp_data[6] <= 1'b1;
                    gray_addr <= gray_addr + 1;
                end
                RightDown : begin
                    if ( gray_data >= mid_value )
                        lbp_data[7] <= 1'b1;
                    if (addr < 16255) 
                        lbp_valid <= 1;
                    lbp_addr <= addr;
                end
                WriteData : begin
                    if (addr >= 16255) begin
                        gray_req <= 0;
                        finish <= 1;
                    end
                    else begin
                        lbp_valid <= 0;
                        lbp_data <= 0;
                        if (addr[6:0] == 7'd126) begin
                            addr <= addr + 3;
                            gray_addr <= addr + 3;
                        end else begin
                            addr <= addr + 1;
                            gray_addr <= addr + 1;
                        end
                    end
                end
            endcase
        end
    end

end

always @ ( * ) begin
    case ( cur_state )
        GetMidData : 
            next_state = LeftUP;
        LeftUP :
            next_state = MidUp;
        MidUp :
            next_state = RightUp;
        RightUp :
            next_state = Left;
        Left :
            next_state = Right;
        Right :
            next_state = LeftDown;
        LeftDown : 
            next_state = MidDown;
        MidDown:
            next_state = RightDown;
        RightDown :
            next_state = WriteData;
        WriteData : begin
            if (addr >= 16255) 
                next_state = WriteData;
            else
                next_state = GetMidData;
        end
        default:
            next_state = GetMidData;
    endcase
end





//====================================================================
endmodule
