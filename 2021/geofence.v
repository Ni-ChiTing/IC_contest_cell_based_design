module geofence ( clk,reset,X,Y,R,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
input [10:0] R;
output valid;
output is_inside;
reg valid;
reg is_inside;

reg [9:0] X_reg [0:5];
reg [9:0] Y_reg [0:5];
reg [3:0] counter;
reg [2:0] counter_2,counter_3;
reg signed [39:0] x1,y1,x2,y2;
reg signed [39:0] result;
reg signed [39:0] mult_1,mult_2;
reg [39:0] result_temp;
reg signed [24:0] Hex_Area;
reg signed [59:0] Tri_Area;
reg [11:0] S;
reg [10:0] R_cal;
reg [10:0] R_reg [0:5];
wire [9:0] root;
reg [9:0] root_temp;
reg [5:0] counter_deug;
integer i ;

localparam GetPoint         = 4'd0;
localparam SortPoint        = 4'd1;
localparam CalHexArea       = 4'd2;
localparam CalArea_part1    = 4'd3;
localparam CalArea_part2    = 4'd4;
localparam CalArea_part3    = 4'd5;
localparam CalArea_part4    = 4'd6;
localparam CalArea_part5    = 4'd7;
localparam CalArea_part6    = 4'd8;
localparam CalPos           = 4'd9;
localparam Pause            = 4'd10;

reg [3:0] cur_state,next_state;

always @ (posedge clk or posedge reset) begin
    if (reset) 
        cur_state <= GetPoint;
    else begin
        cur_state <= next_state;
    end
end

always @ (*) begin
    case (cur_state)
        GetPoint : begin
            if ( counter == 4'd5 )
                next_state = SortPoint;
            else
                next_state = GetPoint;
        end
        SortPoint : begin
            if ( counter == 4'd9 )
                next_state = CalHexArea;
            else
                next_state = SortPoint;
        end
        CalHexArea : begin
            if ( counter == 4'd5 )
                next_state = CalArea_part1;
            else
                next_state = CalHexArea;
        end
        CalArea_part1 : begin
            if ( counter == 4'd7 )
                next_state = CalArea_part2;
            else
                next_state = CalArea_part1;
        end
        CalArea_part2 : begin
            if ( counter == 4'd7 )
                next_state = CalArea_part3;
            else
                next_state = CalArea_part2;
        end
        CalArea_part3 : begin
            if ( counter == 4'd7 )
                next_state = CalArea_part4;
            else
                next_state = CalArea_part3;
        end
        CalArea_part4 : begin
            if ( counter == 4'd7 )
                next_state = CalArea_part5;
            else
                next_state = CalArea_part4;
        end
        CalArea_part5 : begin
            if ( counter == 4'd7 )
                next_state = CalArea_part6;
            else
                next_state = CalArea_part5;
        end
        CalArea_part6 : begin
            if ( counter == 4'd7 )
                next_state = CalPos;
            else
                next_state = CalArea_part6;
        end
        CalPos : begin
            next_state = Pause;
        end
        default : begin
            next_state = GetPoint;
        end
    endcase
end

always @ ( posedge clk or posedge reset ) begin
    if (reset) begin
        valid <= 1'd0;
        is_inside <= 1'd0;
        counter <= 4'd0;
        counter_2 <= 3'd1;
        counter_3 <= 3'd2;
        Hex_Area  <= 20'd0;
        S <= 11'd0;
        counter_deug <= 6'd0;
        result_temp <= 40'd0;
    end
    else begin
        case ( cur_state )
            GetPoint : begin
                if ( counter == 4'd5 )
                    counter <= 4'd0;
                else
                    counter <= counter + 4'd1;
                X_reg[counter] <= X;
                Y_reg[counter] <= Y;
                R_reg[counter] <= R;
                Hex_Area <= 20'd0;
                valid <= 1'd0;
                is_inside <= 1'd0;
            end
            SortPoint : begin
                if ( counter == 4'd9 )
                    counter <= 4'd0;
                else
                    counter <= counter + 4'd1;
                case (counter)
                    4'd0 : begin
                        counter_2 <= 3'd1;
                        counter_3 <= 3'd3;

                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin
                            X_reg[2] <= X_reg[1];
                            Y_reg[2] <= Y_reg[1];
                            R_reg[2] <= R_reg[1];

                            //X_reg[3] <= X_reg[2];
                            //Y_reg[3] <= Y_reg[2];
                            //R_reg[3] <= R_reg[2];

                        end
                    end
                    4'd1 : begin
                        counter_2 <= 3'd2;
                        counter_3 <= 3'd3;

                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin
                            
                            X_reg[2] <= X_reg[1];
                            Y_reg[2] <= Y_reg[1];
                            R_reg[2] <= R_reg[1];

                            X_reg[3] <= X_reg[2];
                            Y_reg[3] <= Y_reg[2];
                            R_reg[3] <= R_reg[2];

                        end
                    end
                    4'd2 : begin
                        counter_2 <= 3'd1;
                        counter_3 <= 3'd4;

                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin

                            X_reg[3] <= X_reg[2];
                            Y_reg[3] <= Y_reg[2];
                            R_reg[3] <= R_reg[2];

                            

                        end
                    end
                    4'd3 : begin
                        counter_2 <= 3'd2;
                        counter_3 <= 3'd4;

                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin

                            X_reg[2] <= X_reg[1];
                            Y_reg[2] <= Y_reg[1];
                            R_reg[2] <= R_reg[1];

                            X_reg[3] <= X_reg[2];
                            Y_reg[3] <= Y_reg[2];
                            R_reg[3] <= R_reg[2];

                            X_reg[4] <= X_reg[3];
                            Y_reg[4] <= Y_reg[3];
                            R_reg[4] <= R_reg[3];

                            

                        end
                    end
                    4'd4 : begin
                        counter_2 <= 3'd3;
                        counter_3 <= 3'd4;
                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin

                            X_reg[3] <= X_reg[2];
                            Y_reg[3] <= Y_reg[2];
                            R_reg[3] <= R_reg[2];

                            X_reg[4] <= X_reg[3];
                            Y_reg[4] <= Y_reg[3];
                            R_reg[4] <= R_reg[3];

                            

                        end
                    end
                    4'd5 : begin
                        counter_2 <= 3'd1;
                        counter_3 <= 3'd5;

                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin

                            X_reg[4] <= X_reg[3];
                            Y_reg[4] <= Y_reg[3];
                            R_reg[4] <= R_reg[3];

                            

                        end
                    end
                    4'd6 : begin
                        counter_2 <= 3'd2;
                        counter_3 <= 3'd5;

                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin

                            X_reg[2] <= X_reg[1];
                            Y_reg[2] <= Y_reg[1];
                            R_reg[2] <= R_reg[1];

                            X_reg[3] <= X_reg[2];
                            Y_reg[3] <= Y_reg[2];
                            R_reg[3] <= R_reg[2];

                            X_reg[4] <= X_reg[3];
                            Y_reg[4] <= Y_reg[3];
                            R_reg[4] <= R_reg[3];

                            X_reg[5] <= X_reg[4];
                            Y_reg[5] <= Y_reg[4];
                            R_reg[5] <= R_reg[4];

                            

                        end
                    end
                    4'd7 : begin
                        counter_2 <= 3'd3;
                        counter_3 <= 3'd5;

                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin

                            X_reg[3] <= X_reg[2];
                            Y_reg[3] <= Y_reg[2];
                            R_reg[3] <= R_reg[2];

                            X_reg[4] <= X_reg[3];
                            Y_reg[4] <= Y_reg[3];
                            R_reg[4] <= R_reg[3];

                            X_reg[5] <= X_reg[4];
                            Y_reg[5] <= Y_reg[4];
                            R_reg[5] <= R_reg[4];

                            

                        end
                    end
                    4'd8 : begin
                        counter_2 <= 3'd4;
                        counter_3 <= 3'd5;

                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin

                            X_reg[4] <= X_reg[3];
                            Y_reg[4] <= Y_reg[3];
                            R_reg[4] <= R_reg[3];

                            X_reg[5] <= X_reg[4];
                            Y_reg[5] <= Y_reg[4];
                            R_reg[5] <= R_reg[4];

                            

                        end
                    end
                    default : begin
                        counter_2 <= 3'd0;
                        counter_3 <= 3'd1;
                        if ( result < 0 ) begin // 1,2
                            X_reg[counter_2] <= X_reg[counter_3];
                            Y_reg[counter_2] <= Y_reg[counter_3];
                            R_reg[counter_2] <= R_reg[counter_3];
                            //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin

                            X_reg[5] <= X_reg[4];
                            Y_reg[5] <= Y_reg[4];
                            R_reg[5] <= R_reg[4];

                        end
                    end
                endcase
                //if ( result < 0 ) begin // 1,2
                //    X_reg[counter_2] <= X_reg[counter_3];
                //    Y_reg[counter_2] <= Y_reg[counter_3];
                //    R_reg[counter_2] <= R_reg[counter_3];
                //    //for ( i = counter_2 ; i < counter_3 ; i = i + 1 ) begin
                //    //    X_reg[i+1] <= X_reg[i];
                //    //    Y_reg[i+1] <= Y_reg[i];
                //    //    R_reg[i+1] <= R_reg[i];
                //    //end

                //end
            end
            CalHexArea : begin
                if ( counter == 4'd5 )
                    counter <= 4'd0;
                else
                    counter <= counter + 4'd1;
                case (counter)
                        4'd0 : begin
                            counter_2 <= 3'd1;
                            counter_3 <= 3'd2;
                        end
                        4'd1 : begin
                            counter_2 <= 3'd2;
                            counter_3 <= 3'd3;
                        end
                        4'd2 : begin
                            counter_2 <= 3'd3;
                            counter_3 <= 3'd4;
                        end
                        4'd3 : begin
                            counter_2 <= 3'd4;
                            counter_3 <= 3'd5;
                        end
                        4'd4 : begin
                            counter_2 <= 3'd5;
                            counter_3 <= 3'd0;
                        end
                        default : begin
                            counter_2 <= 3'd0;
                            counter_3 <= 3'd1;
                        end
                endcase
                Hex_Area <= Hex_Area + result;
            end
            CalArea_part1 : begin
                if ( counter == 4'd7 ) begin
                    counter <= 4'd0;
                    counter_2 <= 3'd1;
                    counter_3 <= 3'd2;
                end
                else begin
                    counter <= counter + 4'd1;
                    counter_2 <= 3'd0;
                    counter_3 <= 3'd1;
                end
                if ( counter == 4'd2) begin
                    S <= result[12:1];
                end
                else begin
                    S <= S;
                end
                if ( counter == 4'd1 ) begin
                    R_cal <= result;
                end
                else begin
                    R_cal <= R_cal;
                end
                if ( counter == 4'd4 )
                    root_temp <= result;
                else
                    root_temp <= root_temp;
                result_temp <= result;
                Tri_Area <= result;
            end
            CalArea_part2 : begin
                if ( counter == 4'd7 ) begin
                    counter <= 4'd0;
                    counter_2 <= 3'd2;
                    counter_3 <= 3'd3;
                end
                else begin
                    counter <= counter + 4'd1;
                    counter_2 <= 3'd1;
                    counter_3 <= 3'd2;
                end
                if ( counter == 4'd2) begin
                    S <= result[12:1];
                end
                else begin
                    S <= S;
                end
                if ( counter == 4'd1 ) begin
                    R_cal <= result;
                end
                else begin
                    R_cal <= R_cal;
                end
                if ( counter == 4'd4 )
                    root_temp <= result;
                else
                    root_temp <= root_temp;
                result_temp <= result;
                if (counter == 4'd7)
                    Tri_Area <= Tri_Area + result;
                else begin
                    Tri_Area <= Tri_Area;
                end
            end
            CalArea_part3 : begin
                if ( counter == 4'd7 ) begin
                    counter <= 4'd0;
                    counter_2 <= 3'd3;
                    counter_3 <= 3'd4;
                end
                else begin
                    counter <= counter + 4'd1;
                    counter_2 <= 3'd2;
                    counter_3 <= 3'd3;
                end
                if ( counter == 4'd2) begin
                    S <= result[12:1];
                end
                else begin
                    S <= S;
                end
                if ( counter == 4'd1 ) begin
                    R_cal <= result;
                end
                else begin
                    R_cal <= R_cal;
                end
                if ( counter == 4'd4 )
                    root_temp <= result;
                else
                    root_temp <= root_temp;
                result_temp <= result;
                if (counter == 4'd7)
                    Tri_Area <= Tri_Area + result;
                else begin
                    Tri_Area <= Tri_Area;
                end
            end
            CalArea_part4 : begin
                if ( counter == 4'd7 ) begin
                    counter <= 4'd0;
                    counter_2 <= 3'd4;
                    counter_3 <= 3'd5;
                end
                else begin
                    counter <= counter + 4'd1;
                    counter_2 <= 3'd3;
                    counter_3 <= 3'd4;
                end
                if ( counter == 4'd2) begin
                    S <= result[12:1];
                end
                else begin
                    S <= S;
                end
                if ( counter == 4'd1 ) begin
                    R_cal <= result;
                end
                else begin
                    R_cal <= R_cal;
                end
                if ( counter == 4'd4 )
                    root_temp <= result;
                else
                    root_temp <= root_temp;
                result_temp <= result;
                if (counter == 4'd7)
                    Tri_Area <= Tri_Area + result;
                else begin
                    Tri_Area <= Tri_Area;
                end
            end
            CalArea_part5 : begin
                if ( counter == 4'd7 ) begin
                    counter <= 4'd0;
                    counter_2 <= 3'd5;
                    counter_3 <= 3'd0;
                end
                else begin
                    counter <= counter + 4'd1;
                    counter_2 <= 3'd4;
                    counter_3 <= 3'd5;
                end
                if ( counter == 4'd2) begin
                    S <= result[12:1];
                end
                else begin
                    S <= S;
                end
                if ( counter == 4'd1 ) begin
                    R_cal <= result;
                end
                else begin
                    R_cal <= R_cal;
                end
                result_temp <= result;
                if ( counter == 4'd4 )
                    root_temp <= result;
                else
                    root_temp <= root_temp;
                if (counter == 4'd7)
                    Tri_Area <= Tri_Area + result;
                else begin
                    Tri_Area <= Tri_Area;
                end
            end
            CalArea_part6 : begin
                if ( counter == 4'd7 ) begin
                    counter <= 4'd0;
                    counter_2 <= 3'd0;
                    counter_3 <= 3'd0;
                end
                else begin
                    counter <= counter + 4'd1;
                    counter_2 <= 3'd5;
                    counter_3 <= 3'd0;
                end
                if ( counter == 4'd2) begin
                    S <= result[12:1];
                end
                else begin
                    S <= S;
                end
                if ( counter == 4'd1 ) begin
                    R_cal <= result;
                end
                else begin
                    R_cal <= R_cal;
                end
                result_temp <= result;
                if ( counter == 4'd4 )
                    root_temp <= result;
                else
                    root_temp <= root_temp;
                if (counter == 4'd7)
                    Tri_Area <= Tri_Area + result;
                else begin
                    Tri_Area <= Tri_Area;
                end
            end
            CalPos : begin
                valid <= 1'd1;
                is_inside <= ( Hex_Area >= ( Tri_Area << 1 ) ) ? 1'd1 : 1'd0;
                counter_2 <= 3'd1;
                counter_3 <= 3'd2;
                counter_deug <= counter_deug + 1'd1;
            end
            default : begin
                counter <= 4'd0;
                valid <= 1'd0;
                is_inside <= 1'd0;
            end
        endcase
    end
end

always @ (*) begin
    if ( cur_state == SortPoint ) begin
        x1 = {1'd0,X_reg[counter_2]} - {1'd0,X_reg[0]};
        x2 = {1'd0,X_reg[counter_3]} - {1'd0,X_reg[0]};
        y1 = {1'd0,Y_reg[counter_2]} - {1'd0,Y_reg[0]};
        y2 = {1'd0,Y_reg[counter_3]} - {1'd0,Y_reg[0]};
        result = mult_1 - mult_2;
    end
    else if ( cur_state == CalHexArea) begin
        x1 = {1'd0,X_reg[counter_2]};
        x2 = {1'd0,X_reg[counter_3]};
        y1 = {1'd0,Y_reg[counter_2]};
        y2 = {1'd0,Y_reg[counter_3]};
        result = mult_1 - mult_2;
    end
    else begin // paary
        if ( counter == 4'd0 ) begin
            if ( Y_reg[counter_2] > Y_reg[counter_3] )
                y1 = {1'd0,Y_reg[counter_2]} - {1'd0,Y_reg[counter_3]};
            else
                y1 = {1'd0,Y_reg[counter_3]} - {1'd0,Y_reg[counter_2]};
            if ( X_reg[counter_2] > X_reg[counter_3] )
                x1 = {1'd0,X_reg[counter_2]} - {1'd0,X_reg[counter_3]};
            else
                x1 = {1'd0,X_reg[counter_3]} - {1'd0,X_reg[counter_2]};
            y2 = x1;
            x2 = y1;
            result = mult_1 + mult_2;
        end
        else if ( counter == 4'd1 ) begin
            result = {20'd0,root};
            x1 = 40'd0;
            x2 = 40'd0;
            y1 = 40'd0;
            y2 = 40'd0;
        end
        else if ( counter == 4'd2 ) begin
            result = ( (R_cal + R_reg[counter_2] + R_reg[counter_3]) );
            x1 = 40'd0;
            x2 = 40'd0;
            y1 = 40'd0;
            y2 = 40'd0;
        end
        else if ( counter == 4'd3 ) begin
            x1 = S;
            if ( S > R_reg[counter_2] )
                y2 = S - R_reg[counter_2];
            else 
                y2 = R_reg[counter_2] - S;
            result = mult_1;
            y1 = 40'd0;
            x2 = 40'd0;
        end
        else if ( counter == 4'd4 ) begin
            result = root;
            x1 = 40'd0;
            x2 = 40'd0;
            y1 = 40'd0;
            y2 = 40'd0;
        end
        else if ( counter == 4'd5 ) begin
            if ( S > R_reg[counter_3] )
                y2 = S - R_reg[counter_3];
            else 
                y2 = R_reg[counter_3] - S;
            if ( S > R_cal)
                x1 = S - R_cal;
            else
                x1 = R_cal - S;
            result = mult_1;
            y1 = 40'd0;
            x2 = 40'd0;
        end
        else if ( counter == 4'd6) begin
            result = {20'd0,root};
            x1 = 40'd0;
            x2 = 40'd0;
            y1 = 40'd0;
            y2 = 40'd0;
        end
        else begin
            result = root_temp * result_temp;
            x1 = 40'd0;
            x2 = 40'd0;
            y1 = 40'd0;
            y2 = 40'd0;
        end
    end
    
end

always @ (*) begin
    mult_1 = x1*y2; // 0.875*x
    mult_2 = x2*y1; // 0.5*y
end
DW_sqrt_inst sqrt(result_temp[19:0],root);
//sqrt s1 #(60)(clk,1'b1,);
endmodule

module DW_sqrt_inst (radicand, square_root);
    parameter radicand_width = 20;
    parameter tc_mode        = 0;
  
    input  [radicand_width-1 : 0]       radicand;
    output [(radicand_width+1)/2-1 : 0] square_root;
    // Please add +incdir+$SYNOPSYS/dw/sim_ver+ to your verilog simulator 
    // command line (for simulation).
  
    // instance of DW_sqrt
    DW_sqrt #(radicand_width, tc_mode) 
      U1 (.a(radicand), .root(square_root));
endmodule