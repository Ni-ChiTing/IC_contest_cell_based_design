`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output reg        busy;
output reg        valid;
output reg [127:0] iot_out;

reg [7:0] data [0:15];
reg [3:0] counter;
reg [2:0] in_num;
reg [3:0] flaglist;
integer i;
wire compare_result_s,compare_result_b;
reg [7:0] compare_1,compare_2,compare_3;

localparam MAX      = 3'b001;
localparam MIN      = 3'b010;
localparam AVG      = 3'b011;
localparam INCLUDE  = 3'b100;
localparam EXCLUDE  = 3'b101;
localparam PEAKMAX  = 3'b110;
localparam PEAKMIN  = 3'b111;
localparam INCLUDE_LOW  = 8'h6f; // <=
localparam INCLUDE_HIGH = 8'hb0;
localparam EXCLUDE_LOW  = 8'h7f; // <=
localparam EXCLUDE_HIGH = 8'hbf;
 
comparator_big cm_b(compare_1,compare_2,compare_result_b);  // compare_1 > compare_2 -> 1
comparator_small cm_s(compare_1,compare_3,compare_result_s); // compare_1 < compare_3 -> 1
always @ (*) begin
    if (fn_sel != AVG ) begin
        
        if ( fn_sel == INCLUDE ) begin
            compare_1 = data[0];
            compare_2 = INCLUDE_LOW;
            compare_3 = INCLUDE_HIGH;
        end
        else if ( fn_sel == EXCLUDE ) begin
            compare_1 = data[0];
            compare_2 = EXCLUDE_LOW;
            compare_3 = EXCLUDE_HIGH;
        end
        else begin
            compare_2 = iot_in;    
            compare_3 = iot_in;
            compare_1 = data[counter];
        end
        
    end
    else begin
        compare_1 = 8'd0;
        compare_2 = 8'd0;
        compare_3 = 8'd0;
    end
end

always @ ( posedge clk or posedge rst ) begin
    if (rst) begin
        flaglist <= 4'd0;
        counter <= 4'd0;
        for (i = 0 ; i < 16 ; i = i + 1 )
            data[i] <= 8'd0;
        busy <= 1'b0;
        in_num <= 3'd0;
        valid <= 1'b0;
        iot_out <= 128'd0;
    end
    else begin
        busy <= 1'b0;
        if (in_en) begin
            counter <= counter + 1;
            if ( counter == 4'd15)
                in_num <= in_num + 3'd1;
            else
                in_num <= in_num;
            case ( fn_sel )
                INCLUDE, EXCLUDE : begin
                    data[counter] <= iot_in;
                    flaglist[0] <= 1'b1;
                    
                    if ( counter == 0 ) begin
                        if (flaglist[2] && flaglist[0] ) begin
                            valid <= 1'b1;
                            iot_out <= {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7],data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15]};
                        end
                         flaglist[2] <= 1'b0;
                    end
                    else if ( counter == 1 ) begin
                        valid <= 1'b0;
                        //$display("%h,%h,%h",compare_result_s,compare_result_b, (!compare_result_s) || (!compare_result_b)); 
                         if ( ( compare_result_s && compare_result_b && fn_sel == INCLUDE ) ||  ( ( (!compare_result_s) || (!compare_result_b) ) && fn_sel == EXCLUDE ))
                            flaglist[2] <= 1'b1;
                    end
                    else begin
                        valid <= 1'b0;
                    end
                end
                AVG : begin
                    if ( in_num == 0 ) begin
                        data[counter] <= iot_in;
                        if ( flaglist[3] && counter == 1) begin
                            flaglist[3:0] <= 4'b0;
                            valid <= 1'b1;
                            iot_out <= ({flaglist[2:0],iot_out[127:3]});
                        end
                        else begin
                            valid <= 1'b0;
                        end
                    end
                    else if (in_num == 1) begin
                        case ( counter )
                            0:  iot_out[127:120] <= iot_in;
                            1:  iot_out[119:112] <= iot_in;
                            2:  iot_out[111:104] <= iot_in;
                            3:  iot_out[103:96]  <= iot_in;
                            4:  iot_out[95:88]   <= iot_in;
                            5:  iot_out[87:80]   <= iot_in;
                            6:  iot_out[79:72]   <= iot_in;
                            7:  iot_out[71:64]   <= iot_in;
                            8:  iot_out[63:56]   <= iot_in;
                            9:  iot_out[55:48]   <= iot_in;
                            10: iot_out[47:40]   <= iot_in;
                            11: iot_out[39:32]   <= iot_in;
                            12: iot_out[31:24]   <= iot_in;
                            13: iot_out[23:16]   <= iot_in;
                            14: iot_out[15:8]    <= iot_in;
                            default: iot_out[7:0]    <= iot_in;
                        endcase
                        if ( &counter) 
                            flaglist[3] <= 1'b1;
                    end
                    else begin
                        data[counter] <= iot_in;
                        
                    end
                    if ( counter == 0 && flaglist[3] ) begin
                        {flaglist[2:0],iot_out} <= ({flaglist[2:0],iot_out}) +  ({3'd0,data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7],data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15]});
                    end
                end
                default : begin
                    if ( !flaglist[3] ) begin
                        if ( in_num == 0 ) begin
                            data[counter] <= iot_in;
                            if (counter == 0 && flaglist[0]!=1'b0) begin
                                valid <= 1'b1;
                                iot_out <= {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7],data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15]};
                            end
                            else begin
                                valid <= 1'b0;
                            end
                            flaglist[0] <= 1'b1;
                            flaglist[2] <= 1'b1;  // equal
                            flaglist[1] <= 1'b0;  // large 
                        end
                        else begin
                            if ( ( compare_result_b && ( fn_sel==MAX ||  fn_sel==PEAKMAX ) ) || ( compare_result_s && ( fn_sel == MIN || fn_sel == PEAKMIN ))) begin // data > iot_data
                                flaglist[2] <= 1'b0;
                            end
                            if ( ( compare_result_s && flaglist[2] && ( fn_sel==MAX ||  fn_sel==PEAKMAX ) ) || ( compare_result_b && flaglist[2] && ( fn_sel == MIN || fn_sel == PEAKMIN ) )) begin
                                flaglist[1] <= 1'b1;
                            end
                            if ( ( flaglist[2] && compare_result_s && ( fn_sel==MAX ||  fn_sel==PEAKMAX ) ) || (flaglist[2] && compare_result_b && ( fn_sel == MIN || fn_sel == PEAKMIN )) || (flaglist[1])) begin
                                data[counter] <= iot_in;
                            end
                            valid <= 1'b0;
                            if ( &counter ) begin
                                flaglist[2] <= 1'b1;
                                flaglist[1] <= 1'b0;
                            end
                        end
                        if ( ( fn_sel==PEAKMAX || fn_sel==PEAKMIN ) && (&counter && &in_num) ) begin
                            flaglist[3] <= 1'b1;
                        end
                    end
                    else begin
                        if ( ( compare_result_b && (  fn_sel==PEAKMAX ) ) || ( compare_result_s && (  fn_sel == PEAKMIN ))) begin // data > iot_data
                            flaglist[2] <= 1'b0;
                        end
                        if ( ( compare_result_s && flaglist[2] && ( fn_sel==PEAKMAX ) ) || ( compare_result_b && flaglist[2] && (  fn_sel == PEAKMIN ) )) begin
                            flaglist[1] <= 1'b1;
                        end
                        if ( ( flaglist[2] && compare_result_s && ( fn_sel==PEAKMAX ) ) || ( flaglist[2] && compare_result_b && ( fn_sel == PEAKMIN )) || (flaglist[1])) begin
                            data[counter] <= iot_in;
                            flaglist[0] <= 1'b1;
                        end
                        if ( counter == 0 && flaglist[0]) begin
                            valid <= 1'b1;
                            iot_out <= {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7],data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15]};
                            flaglist[0] <= 1'b0;
                        end
                        else begin
                            valid <= 1'b0;
                        end
                        if ( &counter ) begin
                            flaglist[2] <= 1'b1;
                            flaglist[1] <= 1'b0;
                        end
                    end
                end
            endcase
        end
        else begin
            counter <= 4'd0;
            flaglist <= 4'd0;
            in_num <= 3'd0;
        end

    end
end

endmodule

module comparator_big(in_1,in_2,result);
    input [7:0] in_1;
    input [7:0] in_2;
    output result;
    assign result = ( in_1 > in_2 );
endmodule

module comparator_small(in_1,in_2,result);
    input [7:0] in_1;
    input [7:0] in_2;
    output result;
    assign result = ( in_1 < in_2 );
endmodule