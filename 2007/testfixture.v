`timescale 1ns/10ps
`define CYCLE    100           	        // Modify your clock period here
`define SDFFILE  "./lcd_ctrl.sdf"	// Modify your sdf file name
`define IMAGE    "./image1.dat"         // Modify your test image file: image1.dat or image2.dat
`define CMD      "./cmd1.dat"           // Modify your test cmd file: cmd1.dat or cmd2.dat
`define EXPECT   "./out_golden1.dat"    // Modify your output golden file: out_golden1.dat or out_golden2.dat

module test;
parameter IMAGE_N_PAT = 64;
parameter CMD_N_PAT = 45;
parameter OUT_LENGTH= 720;
parameter t_reset = `CYCLE*2;

reg           clk;
reg           reset;
reg   [7:0]   datain;
reg   [2:0]   cmd;
reg           cmd_valid;
wire  [7:0]   dataout;
wire          output_valid;
wire          busy;

reg   [7:0]   image_mem [0:IMAGE_N_PAT-1];
reg   [2:0]   cmd_mem   [0:CMD_N_PAT-1];
reg   [7:0]   out_mem   [0:OUT_LENGTH-1];
reg   [7:0]   out_temp;

reg           stop;
integer       i, j, out_f, err, pattern_num;
reg           over;

   LCD_CTRL top(.clk(clk), .reset(reset), .datain(datain), 
                .cmd(cmd), .cmd_valid(cmd_valid), .dataout(dataout), 
                .output_valid(output_valid), .busy(busy));          
   


//initial $sdf_annotate(`SDFFILE, top);

initial	$readmemh (`IMAGE,  image_mem);
initial	$readmemh (`CMD,    cmd_mem);
initial	$readmemh (`EXPECT, out_mem);

initial begin
   clk         = 1'b0;
   reset       = 1'b0;
   cmd_valid   = 1'b0;
   stop        = 1'b0;  
   over        = 1'b0;
   pattern_num = 0;
   err         = 0;    
end

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
$dumpfile("LCD_CTRL.vcd");
$dumpvars;
//$fsdbDumpfile("LCD_CTRL.fsdb");
//$fsdbDumpvars;

   out_f = $fopen("out.dat");
   if (out_f == 0) begin
        $display("Output file open error !");
        $finish;
   end
end


initial begin
   @(negedge clk)  reset = 1'b1;
   #t_reset        reset = 1'b0;
   
   @(negedge clk)    i=0;
   while (i <= CMD_N_PAT) begin               
      if(!busy) begin
        cmd = cmd_mem[i];
        cmd_valid = 1'b1;  
        
        if(cmd_mem[i] === 3'h1) begin    //cmd: Load data        
           for(j=0; j<=IMAGE_N_PAT; j=j+1)begin
              @(negedge clk) datain = image_mem[j];
                             cmd = 'hz; cmd_valid = 1'b0;
           end
           i = i+1;
        end
        else begin                      //cmd: other command
           @(negedge clk) datain='hz; cmd_valid = 1'b0; i = i+1;
        end       
      end 
      else begin
         datain='hz; cmd = 'hz;  cmd_valid = 0;
         @(negedge clk);
      end               
    end                                       
    stop = 1 ;      
end

always @(posedge clk)begin
   out_temp = out_mem[pattern_num];
   if(output_valid)begin
      $fdisplay(out_f,"%h", dataout);
      if(dataout !== out_temp) begin
         $display("ERROR at %d:output %h !=expect %h ",pattern_num, dataout, out_temp);
         err = err + 1 ;
      end
      pattern_num = pattern_num + 1;      
   end
   if(pattern_num === OUT_LENGTH)  over = 1'b1;
end


initial begin
      @(posedge stop)      
      if((over) || (pattern_num!='h0)) begin
         $display("---------------------------------------------\n");
         if (err == 0)  begin
            $display("All data have been generated successfully!\n");
            $display("-------------------PASS-------------------\n");
         end
         else 
            $display("There are %d errors!\n", err);
            $display("---------------------------------------------\n");
      end
      else begin
        $display("---------------------------------------------\n");
        $display("Error!!! There is no any data output ...!\n");
        $display("-------------------FAIL-------------------\n");
        $display("---------------------------------------------\n");
      end
      $finish;
end
   
endmodule









