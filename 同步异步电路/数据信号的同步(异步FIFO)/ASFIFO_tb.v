`timescale 1ns/1ps
`include "ASFIFO.v"
module ASFIFO_tb;
parameter DEPTH = 16;
parameter WIDTH = 8;
/************端口声明****************/
reg			    wclk	,
			    rclk	,
			    wrstn	,
			    rrstn	,
			    winc	,
	 		    rinc	;
reg [WIDTH-1:0]	wdata	;
wire			wfull	,
			    rempty	;
wire[WIDTH-1:0]	rdata   ;
/************模块例化****************/
asyn_fifo a1
(   
    wclk    ,
    rclk    ,
    wrstn   ,
    rrstn   ,
    winc    ,
    rinc    ,
    wdata   ,
    
    wfull   ,
    rempty  ,
    rdata   
);
/************激励****************/
initial begin
    $dumpfile("ASFIFO.vcd");
    $dumpvars;
    wclk<=0;
    rclk<=0;
    wrstn<=0;
    rrstn<=0;
    winc<=1;
    rinc<=0;
    wdata<=$random;
    
    #35
    wrstn<=1;
    rrstn<=1;
    repeat(10)begin
        @(negedge wclk)
            wdata<=$random;
    end
    #6
    rinc<=1;
     repeat(20)begin
        @(negedge wclk)
            wdata<=$random;
    end   
    winc<=0;
    #1000 $finish;
end
/************时钟****************/
always #10 
    wclk=~wclk;
always #3
    rclk=~rclk;
endmodule