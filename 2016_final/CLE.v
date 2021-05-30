`timescale 1ns/10ps
module CLE ( clk, reset, rom_q, rom_a, sram_q, sram_a, sram_d, sram_wen, finish);
input         clk;
input         reset;
input  [7:0]  rom_q;
output [6:0]  rom_a;
input  [7:0]  sram_q;
output [9:0]  sram_a;
output [7:0]  sram_d;
output        sram_wen;
output        finish;

reg [2:0]   cur_state,next_state;
reg [3:0]   now_label;
reg [15:0]  equ_tabel[0:15];
reg [4:0]   rom_ly;
reg [1:0]   rom_lx;
reg [4:0]   lx,ly;
reg [0:7]   img;
reg [4:0]   label_temp[0:32];
reg finish;
integer i;
reg [9:0]   sram_a;
reg [3:0]   gold_label;//,gold_label_t1,gold_label_t2,gold_label_t3,gold_label_t4,gold_label_t5,gold_label_t6;
reg [3:0]   label_top_left;
reg [3:0]   label_top;
reg [3:0]   label_top_right;
reg [3:0]   label_left;
reg flag;
reg check_equ;
reg [1:0] t;

localparam WAITDATA     = 3'd0;
localparam FINISH_R1    = 3'd6;
localparam WAITDATA_3   = 3'd7;
localparam SCAN         = 3'd1;
localparam WAITDATA_2   = 3'd2;
localparam ADDEQU       = 3'd3;
localparam RELABEL      = 3'd4;
localparam RESCAN       = 3'd5;

assign rom_a  = {rom_ly,rom_lx};
assign sram_d = {3'd0,gold_label}; 
assign sram_wen = ( cur_state == SCAN ||  cur_state == RELABEL  ) ? 1'b0 : 1'b1;

always @ (posedge clk or posedge reset) begin
    if (reset) begin
        cur_state <= WAITDATA;
    end
    else begin
        cur_state <= next_state;
    end
end

always @ (*) begin
    if ( cur_state == SCAN || cur_state == RELABEL || cur_state == RESCAN) begin
        sram_a = {ly,lx};
    end
    else begin
        sram_a = 10'd0;
    end
end


always @ (*) begin
    label_top_left  = label_temp[lx-1];
    label_top       = label_temp[lx];
    label_top_right = label_temp[lx+1];
    label_left      = label_temp[32];
    if (img[lx[2:0]]) begin
        if ( cur_state == SCAN ) begin
            if ( label_left == 0 && label_top_left == 0 && label_top_right == 0 && label_top == 0 ) begin
                gold_label = now_label;
                flag = 1'b1;
                check_equ = 1'b0;
                t = 2'd0;
            end
            else begin
                flag = 1'b0;
                gold_label = now_label;
                if ( label_left < gold_label && label_left != 0 ) begin
                    gold_label = label_left;
                end
                if ( label_top_left < gold_label && label_top_left != 0 ) begin
                    gold_label = label_top_left;
                end
                if ( label_top_right < gold_label && label_top_right != 0 ) begin
                    gold_label = label_top_right;
                end
                if ( label_top < gold_label && label_top != 0 ) begin
                    gold_label = label_top;
                end
                if ( label_top_left != 0 && label_top_right != 0 && label_top_right != label_top_left ) begin
                    check_equ = 1'b1;
                    t = 2'd1;
                end
                else if ( label_top != 0 && label_left != 0 && label_top != label_left ) begin
                    check_equ = 1'b1;
                    t = 2'd2;
                end
                else if (  label_left != 0 && label_top_right != 0 && label_top_right != label_left ) begin
                    check_equ = 1'b1;
                    t = 2'd3;
                end
                else begin
                    check_equ = 1'b0;
                    t = 2'd0;
                end
            end
        end
        else begin
            check_equ = 1'b0;
            flag = 1'b0;
            t = 2'd0;
            if      (equ_tabel[label_temp[0]][0]) gold_label = 4'd0;
            else if (equ_tabel[label_temp[0]][1]) gold_label = 4'd1;
            else if (equ_tabel[label_temp[0]][2]) gold_label = 4'd2;
            else if (equ_tabel[label_temp[0]][3]) gold_label = 4'd3;
            else if (equ_tabel[label_temp[0]][4]) gold_label = 4'd4;
            else if (equ_tabel[label_temp[0]][5]) gold_label = 4'd5;
            else if (equ_tabel[label_temp[0]][6]) gold_label = 4'd6;
            else if (equ_tabel[label_temp[0]][7]) gold_label = 4'd7;
            else if (equ_tabel[label_temp[0]][8]) gold_label = 4'd8;
            else if (equ_tabel[label_temp[0]][9]) gold_label = 4'd9;
            else if (equ_tabel[label_temp[0]][10]) gold_label = 4'd10;
            else if (equ_tabel[label_temp[0]][11]) gold_label = 4'd11;
            else if (equ_tabel[label_temp[0]][12]) gold_label = 4'd12;
            else if (equ_tabel[label_temp[0]][13]) gold_label = 4'd13;
            else if (equ_tabel[label_temp[0]][14]) gold_label = 4'd14;
            else if (equ_tabel[label_temp[0]][15]) gold_label = 4'd15;
            else gold_label = label_temp[0];
        end
    end
    else begin
        flag = 1'b0;
        gold_label = 4'd0;
        check_equ = 1'b0;
        t = 2'd0;
    end
end

always @ ( posedge clk or posedge reset ) begin
    if (reset) begin
        lx <= 5'd0;
        ly <= 5'd0;
        rom_lx <= 2'd0;
        rom_ly <= 5'd0;
        now_label <= 4'd1;
        for ( i = 0 ; i < 33 ; i = i + 1)
            label_temp[i] <= 4'd0;
        for ( i = 0; i < 16 ; i= i + 1  )
            equ_tabel[i] <= 16'd0;
        img <= 8'd0;
        finish <= 1'b0;
    end
    else begin
        case ( cur_state )
            WAITDATA : begin
                img <= rom_q;
                rom_lx <= rom_lx + 2'b1;
            end
            SCAN : begin
                    if ( lx == 5'd31 )
                        lx <= ({(lx[4:3]+2'd1),3'd0});
                    else
                        lx <= lx + 5'd1;
                    if ( lx == 5'd31 ) 
                        ly <= ly + 5'd1;
                    else
                        ly <= ly;
                    if ( lx == 5'd0 ) begin
                        label_temp[32] <= 5'd0;
                        label_temp[lx - 5'd1] <= 5'd0;
                    end
                    else begin
                        label_temp[32] <= gold_label;
                        label_temp[lx - 5'd1] <= label_temp[32];
                    end
                if ( check_equ ) begin
                    if ( flag )
                        now_label <= now_label + 4'd1;   
                    case ( t )
                    2'd1 : begin // top left and top right
                        equ_tabel[label_top_left][label_top_right] <= 1'b1;
                        equ_tabel[label_top_right][label_top_left] <= 1'b1; 
                    end
                    2'd2 : begin // top and left
                        equ_tabel[label_left][label_top] <= 1'b1;
                        equ_tabel[label_top][label_left] <= 1'b1; 
                    end
                    default : begin // left and top right
                        equ_tabel[label_left][label_top_right] <= 1'b1;
                        equ_tabel[label_top_right][label_left] <= 1'b1;               
                    end
                    endcase
                end
                if ( lx[2:0] == 3'd7 ) begin
                    rom_lx <= rom_lx + 2'b1;
                    if ( rom_lx == 2'd3 )
                        rom_ly <= rom_ly + 5'b1;
                    else
                        rom_ly <= rom_ly;
                    img <= rom_q;
                end
                if ( flag )
                    now_label <= now_label + 4'd1;   
            end
            ADDEQU : begin
                lx <= lx + 5'd1;
                equ_tabel[1] <= equ_tabel[1][lx[3:0]] ? ( equ_tabel[1] | equ_tabel[lx[3:0]] ) : equ_tabel[1];
                equ_tabel[2] <= equ_tabel[2][lx[3:0]] ? ( equ_tabel[2] | equ_tabel[lx[3:0]] ) : equ_tabel[2];
                equ_tabel[3] <= equ_tabel[3][lx[3:0]] ? ( equ_tabel[3] | equ_tabel[lx[3:0]] ) : equ_tabel[3];
                equ_tabel[4] <= equ_tabel[4][lx[3:0]] ? ( equ_tabel[4] | equ_tabel[lx[3:0]] ) : equ_tabel[4];
                equ_tabel[5] <= equ_tabel[5][lx[3:0]] ? ( equ_tabel[5] | equ_tabel[lx[3:0]] ) : equ_tabel[5];
                equ_tabel[6] <= equ_tabel[6][lx[3:0]] ? ( equ_tabel[6] | equ_tabel[lx[3:0]] ) : equ_tabel[6];
                equ_tabel[7] <= equ_tabel[7][lx[3:0]] ? ( equ_tabel[7] | equ_tabel[lx[3:0]] ) : equ_tabel[7];
                equ_tabel[8] <= equ_tabel[8][lx[3:0]] ? ( equ_tabel[8] | equ_tabel[lx[3:0]] ) : equ_tabel[8];
                equ_tabel[9] <= equ_tabel[9][lx[3:0]] ? ( equ_tabel[9] | equ_tabel[lx[3:0]] ) : equ_tabel[9];
                equ_tabel[10] <= equ_tabel[10][lx[3:0]] ? ( equ_tabel[10] | equ_tabel[lx[3:0]] ) : equ_tabel[10];
                equ_tabel[11] <= equ_tabel[11][lx[3:0]] ? ( equ_tabel[11] | equ_tabel[lx[3:0]] ) : equ_tabel[11];
                equ_tabel[12] <= equ_tabel[12][lx[3:0]] ? ( equ_tabel[12] | equ_tabel[lx[3:0]] ) : equ_tabel[12];
                equ_tabel[13] <= equ_tabel[13][lx[3:0]] ? ( equ_tabel[13] | equ_tabel[lx[3:0]] ) : equ_tabel[13];
                equ_tabel[14] <= equ_tabel[14][lx[3:0]] ? ( equ_tabel[14] | equ_tabel[lx[3:0]] ) : equ_tabel[14];
                equ_tabel[15] <= equ_tabel[15][lx[3:0]] ? ( equ_tabel[15] | equ_tabel[lx[3:0]] ) : equ_tabel[15];
            end
            FINISH_R1 : begin
                lx <= 5'd0;
                ly <= 5'd1;
                rom_lx <= 2'd0;
                rom_ly <= 5'd1;
                now_label <= 4'd0;
            end
            WAITDATA_2 : begin
                img <= rom_q;
                rom_lx <= rom_lx + 2'b1;
            end
            RESCAN : begin
                if ( |img[0:3] == 0 && lx[2:0] == 3'd0 ) begin
                    lx <= {lx[4:3],3'd4};
                end
                else if ( |img[4:7] == 0 && lx[2:0] == 3'd4 ) begin
                    lx <= ({(lx[4:3]+2'd1),3'd0});
                    if ( lx == 5'd28 ) 
                        ly <= ly + 5'd1;
                    else
                        ly <= ly;
                    img <= rom_q;
                    rom_lx <= rom_lx + 2'b1;
                    if ( rom_lx == 2'd3 )
                        rom_ly <= rom_ly + 5'b1;
                    else
                        rom_ly <= rom_ly;
                end
                else begin
                    if ( !img[lx[2:0]] ) begin
                        if ( lx == 5'd31 )
                            lx <= ({(lx[4:3]+2'd1),3'd0});
                        else
                            lx <= lx + 5'd1;
                        if ( lx == 5'd31 ) 
                            ly <= ly + 5'd1;
                        else
                            ly <= ly;
                        if ( lx[2:0] == 3'd7 ) begin
                            rom_lx <= rom_lx + 2'b1;
                            if ( rom_lx == 2'd3 )
                                rom_ly <= rom_ly + 5'b1;
                            else
                                rom_ly <= rom_ly;
                            img <= rom_q;
                        end
                    end
                end
                if ( (lx == 5'd31 && ly == 5'd31) || ((|img[4:7] == 1'b0 ) && lx == 5'd28 && ly == 5'd31))
                    finish <= 1'b1;
                else
                    finish <= 1'b0;
            end
            WAITDATA_3 : begin
                label_temp[0] <= sram_q[3:0];
            end
            RELABEL : begin
                if ( lx == 5'd31 )
                    lx <= ({(lx[4:3]+2'd1),3'd0});
                else
                    lx <= lx + 5'd1;
                if ( lx == 5'd31 ) 
                    ly <= ly + 5'd1;
                else
                    ly <= ly;
                if ( lx[2:0] == 3'd7 ) begin
                    rom_lx <= rom_lx + 2'b1;
                    if ( rom_lx == 2'd3 )
                        rom_ly <= rom_ly + 5'b1;
                    else
                        rom_ly <= rom_ly;
                    img <= rom_q;
                end
            end
        endcase
    end
end 

always @ (*) begin
    case (cur_state)
        WAITDATA : begin
            next_state = SCAN;
        end
        FINISH_R1 : begin
            next_state = WAITDATA_2;
        end
        SCAN : begin
            if ( lx == 5'd31 && ly == 5'd31 )
                next_state = ADDEQU;
            else
                next_state = SCAN;
        end
        ADDEQU : begin
            if ( lx == 5'd15 )
                next_state = FINISH_R1;
            else
                next_state = ADDEQU;
        end
        RELABEL : begin
            next_state = RESCAN;
        end
        WAITDATA_3 : begin
            next_state = RELABEL;
        end
        WAITDATA_2 : begin
            next_state = RESCAN;
        end
        RESCAN : begin
            if ( img[lx[2:0]] ) begin
                next_state = WAITDATA_3;
            end
            else begin
                if ( (lx == 5'd31 && ly == 5'd31) || ((|img[4:7] == 1'b0 ) && lx == 5'd28 && ly == 5'd31))
                    next_state = WAITDATA;
                else
                    next_state = RESCAN;
            end
        end
        default : begin
            next_state = WAITDATA;
        end
    endcase
end

endmodule
