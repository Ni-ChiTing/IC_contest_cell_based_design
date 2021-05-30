module LCD_CTRL(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output  [7:0]   dataout;
output          output_valid;
output          busy;


reg  [7:0]   dataout;
reg          output_valid;
reg          busy;

parameter state_bit = 4;

reg [ state_bit - 1 : 0 ]       cur_state;
reg [ state_bit - 1 : 0 ]       next_state;

localparam [ state_bit - 1 : 0 ]    CMD_IN      = 8;
localparam [ state_bit - 1 : 0 ]    LOAD_DATA   = 1;
localparam [ state_bit - 1 : 0 ]    ZOOM_IN     = 2;
localparam [ state_bit - 1 : 0 ]    ZOOM_OUT    = 3;
localparam [ state_bit - 1 : 0 ]    SHIFT_RIGHT = 4;
localparam [ state_bit - 1 : 0 ]    SHIFT_LEFT  = 5;
localparam [ state_bit - 1 : 0 ]    SHIFT_UP    = 6;
localparam [ state_bit - 1 : 0 ]    SHIFT_DOWN  = 7;
localparam [ state_bit - 1 : 0 ]    REFLASH     = 0;

reg [5:0] counter ; 
reg [7:0] datas[63:0];
reg [2:0] X;
reg [2:0] Y;
wire [2:0] y_two;
wire [2:0] x_two;
reg zoom;
integer i;

assign y_two = counter[3:2] << 1;
assign x_two = counter[1:0] << 1;

always @ ( posedge clk or posedge reset ) begin
    if ( reset ) begin
        cur_state <= CMD_IN;
        counter <= 0;
        X <= 0;
        Y <= 0;
        zoom <= 0;
        busy <= 0;
        for ( i = 0 ; i < 64 ; i = i + 1 ) begin
            datas[i] <= 0;
        end   
        output_valid <= 0;
    end
    else begin
        cur_state <= next_state;
        case ( cur_state )
            CMD_IN : begin
                output_valid <= 0;
                counter <= 0;

                if ( cmd == ZOOM_IN && cmd_valid ) begin
                    X <= 2;
                    Y <= 2;
                    zoom <= 1;
                end
                if ( ( cmd == ZOOM_OUT || cmd == LOAD_DATA ) && cmd_valid) begin
                    X <= 0;
                    Y <= 0;
                    zoom <= 0;
                end

                if ( cmd_valid )
                    busy <= 1;
            end
            LOAD_DATA : begin
                datas[63] <= datain;
                counter <= counter + 1;
                for ( i = 63 ; i > 0 ; i = i - 1 ) 
                    datas[ i - 1 ] <= datas[i];
            end
            ZOOM_IN : begin
                output_valid <= 1;
                counter <= counter + 1;
                if ( counter == 15 ) 
                    busy <= 0;
                dataout <= datas[ { ( Y + counter[3:2] ) , ( X + counter[1:0] ) } ];
            end
            ZOOM_OUT : begin
                output_valid <= 1;
                counter <= counter + 1;
                if ( counter == 15 ) 
                    busy <= 0;
                dataout <= datas[ { ( Y + y_two ) , ( X + x_two ) } ];
            end
            SHIFT_RIGHT : begin
                if ( X == 4 )
                    X <= 4;
                else if ( zoom )
                    X <= X + 1;
                else 
                    X <= X;
            end
            SHIFT_LEFT : begin
                if ( X == 0 )
                    X <= 0;
                else if (zoom)
                    X <= X - 1;
                else 
                    X <= X;
            end
            SHIFT_UP : begin
                if ( Y == 0 )
                    Y <= 0;
                else if ( zoom )
                    Y <= Y - 1;
                else 
                    Y <= Y;
            end
            SHIFT_DOWN : begin
                if ( Y == 4 )
                    Y <= 4;
                else if ( zoom ) 
                    Y <= Y + 1;
                else
                    Y <= Y;
            end
            REFLASH : begin
                output_valid <= 1;
                counter <= counter + 1;
                
                if ( counter == 15 ) 
                    busy <= 0;
                if (zoom)
                    dataout <= datas[ { ( Y + counter[3:2] ) , ( X + counter[1:0] ) } ];
                else
                    dataout <= datas[ { ( Y + y_two ) , ( X + x_two ) } ];
                
            end
        endcase
    end

end

always @ ( * ) begin
        case ( cur_state )
            CMD_IN : begin
                if ( cmd_valid ) begin
                    next_state = cmd;
                end
                else
                    next_state = CMD_IN;
            end
            LOAD_DATA : begin
                if ( counter == 63 )
                    next_state = REFLASH;
                else 
                    next_state = LOAD_DATA;
            end
            SHIFT_RIGHT : begin
                next_state = REFLASH;
            end
            SHIFT_LEFT : begin
                next_state = REFLASH;
            end
            SHIFT_UP : begin
                next_state = REFLASH;
            end
            SHIFT_DOWN : begin
                next_state = REFLASH;
            end
            default : begin
                if ( counter == 15 ) 
                    next_state = CMD_IN;
                else 
                    next_state = cur_state;
            end

        endcase
end
endmodule
