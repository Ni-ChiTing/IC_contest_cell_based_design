`timescale 1ns/10ps
`define CYCLE    100           	        // Modify your clock period here
`define SDFFILE  "./LCD_CTRL.sdf"	      // Modify your sdf file name
`define IMAGE    "./image1.dat"         // Modify your test image file: image1.dat or image2.dat
`define CMD      "./cmd1.dat"           // Modify your test cmd file: cmd1.dat or cmd2.dat
`define EXPECT   "./out_golden1.dat"    // Modify your output golden file: out_golden1.dat or out_golden2.dat

module test;
parameter IMAGE_N_PAT = 108;
parameter CMD_N_PAT = 130;
parameter OUT_LENGTH= 2080;
parameter t_reset = `CYCLE*2;

reg           clk;
reg           reset;
reg   [7:0]   datain;
reg   [3:0]   cmd;
reg           cmd_valid;
wire  [7:0]   dataout;
wire          output_valid;
wire          busy;

reg   [7:0]   image_mem [0:IMAGE_N_PAT-1];
reg   [3:0]   cmd_mem   [0:CMD_N_PAT-1];
reg   [7:0]   out_mem   [0:OUT_LENGTH-1];
reg   [7:0]   out_temp;


reg   [5:0]   show;
reg   [5:0]   verify;
integer       i, j, out_f, err, pass, pattern_num;
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
   over        = 1'b0;
   pattern_num = 0;
   err         = 0;
   pass        = 0;             
   show        = 6'b111111;   
   verify      = 6'b0;
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
        
        if(cmd_mem[i] === 'd0) begin    //cmd: Load data        
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
end

always @(posedge clk)begin
   out_temp = out_mem[pattern_num];
   if(output_valid)begin
      $fdisplay(out_f,"%h", dataout);      
      if(dataout !== out_temp) begin
         $display("ERROR at %d:output %h !=expect %h ",pattern_num, dataout, out_temp);
         err = err + 1 ;          
      end            
      else if(dataout === out_temp)begin      
         pass = pass + 1 ;
      end      
      #1 pattern_num = pattern_num + 1;
   end
   if(pattern_num === OUT_LENGTH)  over = 1'b1;      
   
   if(show[0]==1 && pass=='d16   && i=='d1)begin
     show[0]=0;  verify[0]=1'b1;
     $display("-----------------------------------------------------\n");
     $display("Congratulations! The first  test you have passed!\n");   
     $display("-----------------------------------------------------\n");
   end
   if(show[1]==1 && pass=='d96  && i=='d6)begin
     show[1]=0; verify[1]=1'b1;
     $display("-----------------------------------------------------\n");
     $display("Congratulations! The second test you have passed!\n");   
     $display("-----------------------------------------------------\n");     
   end
   if(show[2]==1 && pass=='d176  && i=='d11)begin
     show[2]=0; verify[2]=1'b1;
     $display("-----------------------------------------------------\n");
     $display("Congratulations! The third  test you have passed!\n");   
     $display("-----------------------------------------------------\n");     
   end      
   if(show[3]==1 && pass=='d368  && i=='d23)begin
     show[3]=0; verify[3]=1'b1;
     $display("-----------------------------------------------------\n");
     $display("Congratulations! The fourth test you have passed!\n");   
     $display("-----------------------------------------------------\n");     
   end
   if(show[4]==1 && pass=='d1968  && i=='d123)begin
     show[4]=0; verify[4]=1'b1;
     $display("-----------------------------------------------------\n");   
     $display("Congratulations! The fifth test you have passed!\n");   
     $display("-----------------------------------------------------\n");     
   end
   if(show[5]==1 && pass=='d2080  && i=='d130)begin
     show[5]=0; verify[5]=1'b1;
     $display("-----------------------------------------------------\n");   
     $display("Congratulations! The sixth  test you have passed!\n");   
     $display("-----------------------------------------------------\n");     
   end
end


initial begin
      @(posedge over)      
      if(pass === 'd2080) begin
         $display("-----------------------------------------------------\n");
         $display("Congratulations! All data have been generated successfully!\n");
         $display("-------------------------PASS------------------------\n");
      end
      else begin
            $display("-----------------------------------------------------\n");
            $display("There are %d errors!\n", err);
            $display("-----------------------------------------------------\n");

            $display("---------------------SUMMARY-------------------------\n");
            if(!(|verify))   $display("All test you have no passed!\n");
            else begin
               if(verify[0]) $display("Congratulations! The first  test you have passed!\n");
               if(verify[1]) $display("Congratulations! The second test you have passed!\n"); 
               if(verify[2]) $display("Congratulations! The third  test you have passed!\n"); 
               if(verify[3]) $display("Congratulations! The fourth test you have passed!\n"); 
               if(verify[4]) $display("Congratulations! The fifth  test you have passed!\n"); 
               if(verify[5]) $display("Congratulations! The sixth  test you have passed!\n"); 
            end
            $display("-----------------------------------------------------\n");
      end
      $finish;
end

initial begin
  #(`CYCLE*50000);
      $display("---------------------WARRNING------------------------\n");
      $display("Simulation STOP! Maybe your circuit has some problem!\n");
      $display("Please check your ciruit again ...                   \n");
      $display("-----------------------------------------------------\n");
      $finish;
end
   
endmodule
