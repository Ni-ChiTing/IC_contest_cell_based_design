`timescale 1ns/10ps

module SAO ( clk, reset, in_en, din, sao_type, sao_band_pos, sao_eo_class, sao_offset, lcu_x, lcu_y, lcu_size, busy, finish);
input   clk;
input   reset;
input   in_en;
input   [7:0]  din;
input   [1:0]  sao_type;
input   [4:0]  sao_band_pos;
input          sao_eo_class;
input   [15:0] sao_offset;
input   [2:0]  lcu_x;
input   [2:0]  lcu_y;
input   [1:0]  lcu_size;
output reg  busy;
output reg  finish;

localparam READONEDATA      = 3'd0;
localparam PROCESS_BO       = 3'd1;
localparam PROCESS_EO_VER   = 3'd2;
localparam PROCESS_EO_HOR   = 3'd3;
localparam WAIT_VER         = 3'd4;
localparam WRITELAST        = 3'd6;
localparam DONE             = 3'd5;
reg [5:0] in_counter_x;
reg [5:0] in_counter_y;
reg [5:0] write_locate_y;
reg [5:0] write_locate_x;
reg [13:0] Addr;
reg [7:0] pixels [0:127];
reg [2:0] cur_state;
reg [2:0] next_state;
reg [8:0] SAO_result;
integer i;
reg sram_cen,sram_wen;
reg [5:0] cu_size;
reg [4:0] band;
reg [7:0] a,b,c;
reg [2:0] category;
reg out_range;
reg [7:0] reg_din;
reg [8:0] offset;
reg sign;
always @ (*) begin
  case( lcu_size )
     2'd0 : begin
      cu_size = 6'd15;
      Addr = {lcu_y,write_locate_y[3:0],lcu_x,write_locate_x[3:0]}; // 16x16
     end
     2'd1 : begin
      cu_size = 6'd31;
      Addr = {lcu_y[1:0],write_locate_y[4:0],lcu_x[1:0],write_locate_x[4:0]}; // 32x32
     end 
     default : begin 
      cu_size = 6'd63;
      Addr = {lcu_y[0],write_locate_y[5:0],lcu_x[0],write_locate_x[5:0]}; //64x64
     end
  endcase
end

always @ (negedge clk or posedge reset ) begin
    if ( reset ) begin
        reg_din <= 8'd0;
    end
    else begin
      if (in_en)
        reg_din <= din;
    end
end
always @ ( posedge clk or posedge reset ) begin
  if (reset) begin
    for ( i = 0 ; i < 128 ; i = i + 1)
      pixels[i] <= 8'h0;
  end
  else begin
    if ( cur_state == PROCESS_EO_VER) begin
        if ( in_counter_y > 6'd1 ) begin
            pixels[({1'b1,(in_counter_x)})] <= reg_din;
            pixels[(in_counter_x)] <= pixels[({1'b1,(in_counter_x)}) ]; // shift up
        end
        else begin
            pixels[({in_counter_y[0],in_counter_x})] <= reg_din;
        end
    end
    else if ( cur_state == PROCESS_EO_HOR ) begin // HOR 
        if ( in_counter_y > 6'd0 || in_counter_x > 6'd2 ) begin
            pixels[0] <= pixels[1];
            pixels[1] <= pixels[2];
            pixels[2] <= reg_din;
        end
        else begin
            pixels[({in_counter_y[0],in_counter_x})] <= reg_din;
        end
    end
    else begin
        pixels[({in_counter_y[0],in_counter_x})] <= reg_din;
    end
  end
end

always @ (*) begin
  if ( sao_eo_class ) begin // ver
      a = pixels[({1'b0, write_locate_x})];
      if ( write_locate_y == 6'd0 )
        c = reg_din;
      else
        c = pixels[({1'b1, write_locate_x})];
      b = reg_din;
  end
  else begin                // hor
    a = pixels[0];
    if ( ( write_locate_x == 6'd0 && write_locate_y == 6'd0 ) || ( write_locate_x == cu_size && write_locate_y == cu_size ))
      c = reg_din;
    else 
      c = pixels[1];
    
    b = pixels[2];
  end
  band = ( reg_din >> 8'd3 );
  if ( sao_eo_class  && ( write_locate_y == 6'd0 || write_locate_y == cu_size )) begin // ver
    out_range = 1'b1;
  end
  else if ( !sao_eo_class && ( write_locate_x == 6'd0 || write_locate_x == cu_size )) begin
    out_range = 1'b1;
  end
  else begin
    out_range = 1'b0;
  end
  if ( out_range ) begin
    category = 3'd4;
  end
  else begin
    if ( c < a && c < b ) begin
      category = 3'd0;
    end
    else if (  (c<a && c==b) || (c<b && c==a) ) begin
      category = 3'd1;
    end
    else if ( (c>a && c==b) || (c>b && c==a) ) begin
      category = 3'd2;
    end
    else if (  c > a && c > b ) begin
      category = 3'd3;
    end
    else begin
      category = 3'd4;
    end
  end
  if ( ( sao_band_pos + 5'd3 ) == band || ( (sao_type == 2) && category == 3'd3 ) ) begin
    sign = sao_offset[3];
    offset = ({{5{sao_offset[3]}},sao_offset[3:0]});
  end
  else if ( ( sao_band_pos + 5'd2 ) == band || ( (sao_type == 2) && category == 3'd2 )) begin
    sign = sao_offset[7];
    offset = {{5{sao_offset[7]}},sao_offset[7:4]};
  end
  else if ( ( sao_band_pos + 5'd1 ) == band || ( (sao_type == 2) && category == 3'd1 )) begin
    sign = sao_offset[11];
    offset = {{5{sao_offset[11]}},sao_offset[11:8]};
  end
  else if ( ( sao_band_pos  ) == band || ( (sao_type == 2) && category == 3'd0 )) begin
    sign =  sao_offset[15];
    offset = {{5{sao_offset[15]}},sao_offset[15:12]} ;
  end
  else begin
    sign = 1'b0;
    offset = 9'd0;
  end
end

always @ (posedge clk or posedge reset) begin
  if (reset) begin
    cur_state <= READONEDATA;
  end
  else begin
    cur_state <= next_state;
  end
end

always @ (*) begin
  case ( cur_state )
    READONEDATA : begin
      if (in_en) begin
        if (sao_type == 2'd2) begin
          if ( sao_eo_class )
            next_state = PROCESS_EO_VER;
          else
            next_state = PROCESS_EO_HOR;
        end
        else
          next_state = PROCESS_BO;
      end
      else
        next_state = READONEDATA;
    end
    PROCESS_BO : begin
      if ( write_locate_x == cu_size && write_locate_y == cu_size ) begin
        if ( &Addr )  
            next_state = DONE;
        else     
            next_state = READONEDATA;
      end
      else begin
        next_state = PROCESS_BO;
      end
    end
    PROCESS_EO_HOR : begin
        if ( in_counter_x == cu_size && in_counter_y == cu_size ) begin
          next_state = WRITELAST;
        end
        else begin
          next_state = PROCESS_EO_HOR;
        end
    end
    PROCESS_EO_VER : begin
      if ( in_counter_y == 6'd0 && in_counter_x == cu_size ) begin
        next_state = WAIT_VER;
      end
      else begin
        if ( in_counter_x == cu_size && in_counter_y == cu_size ) begin
          next_state = WRITELAST;
        end
        else begin
          next_state = PROCESS_EO_VER;
        end
      end
    end
    WAIT_VER : begin
        if ( in_counter_y == 6'd1 && in_counter_x == cu_size) begin
            next_state = PROCESS_EO_VER;
        end
        else begin
            next_state = WAIT_VER;
        end
    end
    WRITELAST : begin
      if ( write_locate_x == cu_size && write_locate_y == cu_size ) begin
          if ( &Addr )  
              next_state = DONE;
          else     
              next_state = READONEDATA;
      end
    end
    DONE : next_state = DONE;
    default : begin
      next_state = READONEDATA;
    end
  endcase
end
always@ (posedge clk or posedge reset) begin
  if (reset) begin
    write_locate_x <= 6'd0;
    write_locate_y <= 6'd0;
    in_counter_x <= 6'd0;
    in_counter_y <= 6'd0;
    busy <= 1'd0;
    finish <= 1'd0;
    sram_cen <= 1'd1;
    sram_wen <= 1'd1;
  end
  else begin
    if ( ( next_state == DONE ) ) begin
      sram_cen <= 1'd1;
      sram_wen <= 1'd1;
    end
    else begin
      sram_cen <= 1'd0;
      sram_wen <= 1'd0;
    end
    case ( cur_state )
      READONEDATA : begin
      busy <= 1'd0;
        if (in_en) begin
            if ( in_counter_x == cu_size ) begin
                in_counter_x <= 6'd0;
                if ( in_counter_y == cu_size ) begin
                    in_counter_y <= 6'd0;
                end
                else begin
                    in_counter_y <= in_counter_y + 6'd1;
                end
            end
            else begin
                in_counter_x <= in_counter_x + 6'd1;
            end
            if ( write_locate_x == cu_size ) begin
                write_locate_x <= 6'd0;
                if ( write_locate_y == cu_size ) begin
                    write_locate_y <= 6'd0;
                end
                else begin
                    write_locate_y <= write_locate_y + 6'd1;
                end
            end
            else begin
                write_locate_x <= write_locate_x + 6'd1;
            end
        end
        else begin
            write_locate_x <= 6'd0;
            write_locate_y <= 6'd0;
            in_counter_x <= 6'd0;
            in_counter_y <= 6'd0;
        end
        finish <= 1'd0;
      end
      PROCESS_BO : begin
        if ( in_counter_x == cu_size ) begin
            in_counter_x <= 6'd0;
            if ( in_counter_y == cu_size ) begin
                in_counter_y <= 6'd0;
            end
            else begin
                in_counter_y <= in_counter_y + 6'd1;
            end
        end
        else begin
            in_counter_x <= in_counter_x + 6'd1;
        end
        if ( write_locate_x == cu_size ) begin
            write_locate_x <= 6'd0;
            if ( write_locate_y == cu_size ) begin
                write_locate_y <= 6'd0;
            end
            else begin
                write_locate_y <= write_locate_y + 6'd1;
            end
        end
        else begin
            write_locate_x <= write_locate_x + 6'd1;
        end
        finish <= 1'd0;
        busy <= 1'b0;
      end
      PROCESS_EO_VER : begin
        if ( in_counter_x == cu_size ) begin
            in_counter_x <= 6'd0;
            if ( in_counter_y == cu_size ) begin
                in_counter_y <= 6'd0;
            end
            else begin
                in_counter_y <= in_counter_y + 6'd1;
            end
        end
        else begin
            in_counter_x <= in_counter_x + 6'd1;
        end
        if ( write_locate_x == cu_size ) begin
            write_locate_x <= 6'd0;
            if ( write_locate_y == cu_size ) begin
                write_locate_y <= 6'd0;
            end
            else begin
                write_locate_y <= write_locate_y + 6'd1;
            end
        end
        else begin
            write_locate_x <= write_locate_x + 6'd1;
        end
        finish <= 1'd0;
        if ( ( in_counter_x >= cu_size - 6'd1 ) && in_counter_y == cu_size )
          busy <= 1'b1;
        else 
          busy <= 1'b0;
      end
      WAIT_VER : begin
        if ( in_counter_x == cu_size ) begin
          in_counter_x <= 6'd0;
          in_counter_y <= in_counter_y + 6'd1;
        end
        else begin
            in_counter_x <= in_counter_x + 6'd1;
        end
        write_locate_x <= write_locate_x;
        write_locate_y <= write_locate_y;
        finish <= 1'd0;
        busy <= 1'b0;
      end
      PROCESS_EO_HOR : begin
        if ( in_counter_x == cu_size ) begin
          in_counter_x <= 6'd0;
          if ( in_counter_y == cu_size ) begin
              in_counter_y <= 6'd0;
          end
          else begin
              in_counter_y <= in_counter_y + 6'd1;
          end
        end
        else begin
          in_counter_x <= in_counter_x + 6'd1;
        end
        if ( write_locate_x == cu_size ) begin
          write_locate_x <= 6'd0;
          if ( write_locate_y == cu_size ) begin
            write_locate_y <= 6'd0;
          end
          else begin
            write_locate_y <= write_locate_y + 6'd1;
          end
        end
        else begin
          if ( ( in_counter_x == 6'd1 || in_counter_x == 6'd2 ) && in_counter_y == 6'd0 ) begin
            write_locate_x <= write_locate_x;
          end
          else begin
            write_locate_x <= write_locate_x + 6'd1;
          end
        end
        if ( ( in_counter_x >= cu_size - 6'd1 ) && in_counter_y == cu_size )
          busy <= 1'b1;
        else 
          busy <= 1'b0;
        finish <= 1'd0;
      end
      WRITELAST : begin
        if ( write_locate_x == cu_size ) begin
            write_locate_x <= 6'd0;
            if ( write_locate_y == cu_size ) begin
                write_locate_y <= 6'd0;
            end
            else begin
                write_locate_y <= write_locate_y + 6'd1;
            end
        end
        else begin
            write_locate_x <= write_locate_x + 6'd1;
        end
        if ( write_locate_x >= ( cu_size - 6'd1) && write_locate_y == cu_size)
          busy <= 1'b0;
        else
          busy <= 1'b1;
        finish <= 1'd0;
      end
      DONE : begin
        write_locate_x <= 6'd0;
        write_locate_y <= 6'd0;
        in_counter_x <= 6'd0;
        in_counter_y <= 6'd0;
        finish <= 1'd1;
        busy <= 1'b0;
      end
    endcase
  end
end

always @ (*) begin
  case (sao_type)
    2'd0 : begin
      SAO_result = {1'd0,reg_din};
    end
    2'd1 : begin
      SAO_result = offset + {1'd0,reg_din};
      if ( SAO_result[8] ) begin
        if ( sign )
          SAO_result = 9'd0;
        else
          SAO_result = 9'd255;
      end
    end
    2'd2 : begin
      SAO_result = offset + {1'd0,c};
      if ( SAO_result[8] ) begin
        if ( sign )
          SAO_result = 9'd0;
        else
          SAO_result = 9'd255;
      end
    end
    default : begin
      SAO_result = 9'd0;
    end
  endcase
end

sram_16384x8 golden_sram(.Q(), .CLK(clk), .CEN(sram_cen), .WEN(sram_wen), .A( Addr ), .D( SAO_result[7:0] )); // cen->0 enable wen -> 1 read 0 write
     
endmodule