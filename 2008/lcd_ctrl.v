
module LCD_CTRL(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [3:0]   cmd;
input           cmd_valid;
output  [7:0]   dataout;
output          output_valid;
output          busy;

reg  [7:0]   dataout;
reg          output_valid;
reg          busy;

parameter state_bit = 4;
localparam [ state_bit - 1 : 0 ]    CMD_IN          = 10;
localparam [ state_bit - 1 : 0 ]    LOAD_DATA       = 0;
localparam [ state_bit - 1 : 0 ]    ROTATE_LEFT     = 1;
localparam [ state_bit - 1 : 0 ]    ROTATE_RIGHT    = 2;
localparam [ state_bit - 1 : 0 ]    ZOOM_IN         = 3;
localparam [ state_bit - 1 : 0 ]    ZOOM_OUT        = 4;
localparam [ state_bit - 1 : 0 ]    SHIFT_RIGHT     = 5;
localparam [ state_bit - 1 : 0 ]    SHIFT_LEFT      = 6;
localparam [ state_bit - 1 : 0 ]    SHIFT_UP        = 7;
localparam [ state_bit - 1 : 0 ]    SHIFT_DOWN      = 8;
localparam [ state_bit - 1 : 0 ]    REFLASH         = 9;
reg [ state_bit - 1 : 0 ]       cur_state;
reg [ state_bit - 1 : 0 ]       next_state;

reg [7:0]       datas[107:0];
reg [6:0]       counter;
reg [3:0]       X;
reg [2:0]       Y;
reg             zoom;
reg [1:0]       rotate;
wire [2:0]      y_two;
wire [3:0]      x_two;
wire [6:0]       addr;
wire [6:0]       addr2;
integer i;

assign y_two = counter[3:2] << 1;
assign x_two = ( counter[1:0] << 1 ) + counter[1:0];
assign addr = ( ( ( {3'b000,Y} + {3'b000,counter[3:2]} ) << 3 ) + ( ( {3'b000,Y} + {3'b000,counter[3:2]} ) << 2 ) )+ ( X + { 1'b0,counter[1:0] } );
assign addr2 = ( ( ( {3'b000,Y} + {3'b000,y_two} ) << 3 ) + ( ( {3'b000,Y} + {3'b000,y_two} ) << 2 ) )+ ( X + { 1'b0,x_two } );

always @ ( posedge clk or posedge reset ) begin
    if ( reset ) begin
        zoom <= 0; //zoom in --> 1 else 0
        rotate <= 1; // 1 ---> mid 0 ---> left 2 ---> right
        X <= 4;
        Y <= 3; 
        counter <= 0;
        busy <= 0;
        output_valid <= 0;
        dataout <= 0;
        for ( i = 0 ; i < 108 ; i = i + 1 ) 
            datas[i] <= 0;
        cur_state <= CMD_IN;
    end
    else begin
        cur_state <= next_state;
        case ( cur_state )
            CMD_IN : begin
                output_valid <= 0;
                if ( cmd == ZOOM_IN && cmd_valid ) begin
                    X <= 4;
                    Y <= 3;
                    zoom <= 1;
                end
                if ( cmd == ZOOM_OUT && cmd_valid ) begin
                    X <= 1;
                    Y <= 1;
                    zoom <= 0;
                end
                if ( cmd == LOAD_DATA && cmd_valid ) begin
                    X <= 1;
                    Y <= 1;
                    zoom <= 0;
                    rotate <= 1;
                    counter <= 0;
                end
                else begin
                    case ( rotate )
                    0 : //left
                        counter <= 3;
                    1 : //mid
                        counter <= 0;
                    default : //right
                        counter <= 12;
                endcase
                end
                if ( ~zoom && cmd_valid && cmd == ROTATE_LEFT ) 
                    rotate <= rotate - 1;
                if ( ~zoom && cmd_valid && cmd == ROTATE_RIGHT ) 
                    rotate <= rotate + 1;
                if ( cmd_valid )
                    busy <= 1;

            end
            LOAD_DATA : begin
                datas[ counter ] <= datain;
                if ( counter == 107 )
                    counter <= 0;
                else
                    counter <= counter + 1;
            end
            ROTATE_LEFT : begin
                case ( rotate )
                    0 : //left
                        counter <= 3;
                    1 : //mid
                        counter <= 0;
                    default : //right
                        counter <= 12;
                endcase
            end
            ROTATE_RIGHT : begin
                case ( rotate )
                    0 : //left
                        counter <= 3;
                    1 : //mid
                        counter <= 0;
                    default : //right
                        counter <= 12;
                endcase
            end
            SHIFT_UP : begin
                if ( zoom ) begin
                    case ( rotate )
                        0 : begin
                            if ( X < 8 )
                                X <= X + 1;
                        end
                        1 : begin
                            if ( Y > 0 )
                                Y <= Y - 1;
                        end
                        default : begin
                            if ( X > 0 )
                                X <= X - 1;
                        end
                    endcase
                end
            end
            SHIFT_DOWN : begin
                if ( zoom ) begin
                    case ( rotate )
                        0 : begin
                            if ( X > 0 )
                                X <= X - 1;
                        end
                        1 : begin
                            if ( Y < 5 )
                                Y <= Y + 1;
                        end
                        default : begin
                            if ( X < 8 )
                                X <= X + 1;
                        end
                    endcase
                end
            end
            SHIFT_LEFT : begin
                if ( zoom ) begin
                    case ( rotate )
                        0 : begin
                            if ( Y > 0 )
                                Y <= Y - 1;
                        end
                        1 : begin
                            if ( X > 0 )
                                X <= X - 1;
                        end
                        default : begin
                            if ( Y < 5 )
                                Y <= Y + 1;
                        end
                    endcase
                end
            end
            SHIFT_RIGHT : begin
                if ( zoom ) begin
                    case ( rotate )
                        0 : begin
                            if ( Y < 5 )
                                Y <= Y + 1;
                        end
                        1 : begin
                            if ( X < 8 )
                                X <= X + 1;
                        end
                        default : begin
                            if ( Y > 0 )
                                Y <= Y - 1;
                        end
                    endcase
                end
            end
            default : begin
            output_valid <= 1;
                case ( rotate )
                    0 : begin
                        if ( zoom )
                            dataout <= datas[ addr ];
                        else
                            dataout <= datas[ addr2 ];
                        
                        counter[3:2] <= counter[3:2] + 2'b01;
                        if ( counter[3:2] == 2'b11 ) begin
                            counter[3:2] <= 2'b00;
                            counter[1:0] <= counter[1:0] - 2'b01;
                        end

                        if ( counter == 12 )
                            busy <= 0;
                    end
                    1 : begin
                        if ( zoom )
                            dataout <= datas[ addr ];
                        else
                            dataout <= datas[ addr2 ];
                        counter <= counter + 1;
                        if ( counter == 15 )
                            busy <= 0;
                    end
                    default : begin
                        if ( zoom )
                            dataout <= datas[ addr ];
                        else
                            dataout <= datas[ addr2 ];
                        counter[3:2] <= counter[3:2] - 2'b01;
                        if ( counter[3:2] == 0 ) begin
                            counter[3:2] <= 2'b11;
                            counter[1:0] <= counter[1:0] + 1'b01;
                        end
                        if ( counter == 3 )
                            busy <= 0;
                    end
                endcase
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
            if ( counter == 107 )
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
        ROTATE_RIGHT : begin
            next_state = REFLASH;
        end
        ROTATE_LEFT : begin
            next_state = REFLASH;
        end
        default : begin
            case ( rotate )
                0 : begin //LEFT
                    if ( counter == 12 )
                        next_state = CMD_IN;
                    else
                        next_state = cur_state;
                end
                1 : begin //MID
                    if ( counter == 15 ) 
                        next_state = CMD_IN;
                    else 
                        next_state = cur_state;
                end
                default : begin // RIGHT
                    if ( counter == 3 ) 
                        next_state = CMD_IN;
                    else 
                        next_state = cur_state;
                end
            endcase
        end
    endcase
end



endmodule
