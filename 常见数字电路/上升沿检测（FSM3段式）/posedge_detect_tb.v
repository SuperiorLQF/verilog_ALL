`timescale 1ns/1ps
`include "posedge_detect.v"
module posedge_detect_tb;
parameter   S1=3'b001,      //one-hot encode state
            S2=3'b010,
            S3=3'b100;

reg         rst_n   ,
            clk     ,
            i_pulse ;
            
wire        o_pulse ;

//模块例化
posedge_detect p1(
            rst_n   ,
            clk     ,
            i_pulse ,
                    
            o_pulse 
);
//激励
initial begin
            $dumpfile("posedge_detect.vcd");
            $dumpvars;
            
            clk<=0;
            rst_n<=0;
            i_pulse<=0;

    #15     rst_n<=1;
    #20     i_pulse<=1;
    #60     i_pulse<=0;

    #1000   $finish;
end
//时钟生成
always #10
    clk=~clk;
endmodule