`timescale 1ns/100ps
`include "cnt10.v"
module  cnt10_tb;
reg              clk ;
reg              clr ;   //清零信号
reg              en  ;   //计数使能
wire             c   ;   //溢出标志
wire[3:0]        out ;    //计数输出
//*********<模块例化>*************
cnt10 c1
(
    clk,
    clr,
    en,
    c,
    out
);
initial begin
    $dumpfile("cnt10.vcd");
    $dumpvars;
    clr<=0;
    clk<=0;
    en<=1;
    #25     clr<=1;
    #235    en<=0;
    #50    en<=1;
    #1000   $finish;
end
always #10
    clk<=~clk;
endmodule