module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;
// reg match;
// reg [4:0] match_index;
// reg valid;

parameter state_bit = 3;
reg [ state_bit - 1 : 0 ] cur_state;
reg [ state_bit - 1 : 0 ] next_state;

localparam [ state_bit - 1 : 0 ] ReadData         = 0;
localparam [ state_bit - 1 : 0 ] CompareString      = 2;
localparam [ state_bit - 1 : 0 ] StarState          = 3;
localparam [ state_bit - 1 : 0 ] Done               = 5;
localparam [ state_bit - 1 : 0 ] Rest               = 6;

localparam [6:0] HEAD = 7'd94;
localparam [6:0] FINISH = 7'd36;
localparam [6:0] POINT = 7'd46;
localparam [6:0] STAR = 7'd42;
localparam [6:0] SPACE = 7'd32;
reg [4:0] match_index;
reg valid;
reg [6:0] patterns [7:0];
reg [6:0] strings [31:0];
reg [3:0] pattern_pointer;
reg [5:0] string_pointer;
reg [3:0] pattern_len;
reg [5:0] string_len;
reg [5:0] string_len_temp;
reg star_tag;
reg [3:0] start_pos;
reg match;



always @ ( posedge clk or posedge reset ) begin
    if (reset) begin
        cur_state <= ReadData ;
        pattern_len <= 0;
        string_len <= 0;
        pattern_pointer <= 0;
        string_pointer <= 0;
        match_index <= 0;
        valid <= 0;
        star_tag <= 1;
        start_pos <= 0;
        string_len_temp <= 0;
        match <= 0;
    end
    else begin
        cur_state <= next_state;
        case ( cur_state )
            ReadData: begin
                if ( isstring ) begin
                    string_len <= string_len + 1;
                    string_len_temp <= string_len + 1;
                    strings[string_len] <= chardata;
                end
                valid <= 0;
                if ( ispattern ) begin
                    string_len <= string_len_temp;
                    pattern_len <= pattern_len + 1;
                    patterns[pattern_len] <= chardata;
                end
                string_pointer <= 0;
                pattern_pointer <= 0;
            end
            CompareString : begin
                if ( string_pointer < string_len && pattern_pointer < pattern_len) begin
                    if ( patterns [ pattern_pointer ] == HEAD ) begin 
                        if ( string_pointer == 0 || strings[ string_pointer ] == SPACE ) begin
                            pattern_pointer <= pattern_pointer + 1;
                            if ( string_pointer != 0 )
                                string_pointer <= string_pointer + 1;
                            if ( strings[ string_pointer ] == SPACE )
                                match_index <= string_pointer[4:0] + 1;
                        end
                        else begin
                            string_pointer <= string_pointer + 1;
                        end
                    end
                    else if ( patterns [ pattern_pointer ] == FINISH ) begin  // pattern == Finish
                        if ( strings[ string_pointer ] == SPACE ) begin
                            pattern_pointer <= pattern_pointer + 1;
                            string_pointer <= string_pointer + 1;
                        end
                        else begin
                            pattern_pointer <= 0;
                            string_pointer <= string_pointer + 1;
                        end
                    end
                    else if ( patterns [ pattern_pointer ] == STAR ) begin
                        pattern_pointer <= pattern_pointer + 1;
                    end
                    else begin
                        if ( patterns[ pattern_pointer ] == POINT ) begin
                            string_pointer <= string_pointer + 1;
                            pattern_pointer <= pattern_pointer + 1;
                            if ( pattern_pointer == 0) 
                                match_index <= string_pointer[4:0];
                        end
                        else begin
                            if ( patterns [ pattern_pointer ] == strings[string_pointer] ) begin
                                if ( pattern_pointer == 0) 
                                    match_index <= string_pointer[4:0];
                                
                                string_pointer <= string_pointer + 1;
                                pattern_pointer <= pattern_pointer + 1;
                            end
                            else begin
                                if ( patterns[ 0 ] == POINT ) begin
                                    pattern_pointer <= (star_tag)?pattern_pointer : 1;
                                    string_pointer <= string_pointer + 1;
                                    //if ( pattern_pointer == 0) 
                                    match_index <= (star_tag)?match_index:string_pointer[4:0] ;
                                end
                                else begin
                                    if ( star_tag )
                                        pattern_pointer <= start_pos;
                                    else
                                        pattern_pointer <= 0;
                                    string_pointer <= string_pointer + 1;
                                end
                            end
                        end
                    end
                end
            end
            Done: begin
                valid <= 1;
                string_len <= 0;
                pattern_len <= 0;
                if ( pattern_pointer == pattern_len || (string_len == string_pointer && patterns[pattern_pointer] == FINISH )) begin
                    match <= 1;
                end
                else begin
                    match <= 0;
                end
                star_tag <= 0;
            end
            StarState : begin
                star_tag <= 1;
                start_pos <= pattern_pointer;
            end
        endcase
    end

end
always @ (*) begin
    case (cur_state)
        ReadData : begin
            if ( ~ispattern && ~isstring )
                next_state = CompareString;
            else
                next_state = ReadData;
        end
        CompareString : begin
            if ( pattern_pointer == pattern_len) 
                next_state = Done;
            else if ( string_pointer == string_len ) begin
                next_state = Done;
            end
            else begin
                if ( patterns[pattern_pointer] == STAR )
                    next_state = StarState;
                else if ( patterns [ pattern_pointer ] == HEAD ) begin
                    next_state = CompareString;
                end
                else if (patterns [ pattern_pointer ] == FINISH ) begin
                    next_state = CompareString; 
                end
                else  
                    next_state = CompareString;
            end
        end
        StarState : begin
            next_state = CompareString;
        end
        default : begin
            next_state = ReadData;
        end
    endcase 
end

endmodule
