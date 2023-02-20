`timescale 1ns/100ps
`include "gray_inc.v"
module  gray_inc_tb;
parameter   SIZE=5,
            INC=1;
reg     clk,
        rst_n;
wire    [SIZE-1:0]    gray;
//*********<模块例化>*************
gray_inc
#(
    SIZE,
    INC
)
 g1
(
    clk,
    rst_n,
    gray
);
initial begin
    $dumpfile("gray_inc.vcd");
    $dumpvars;
    rst_n<=0;
    clk<=0;
    #25     rst_n<=1;
    #1000   $finish;
end
always #10
    clk<=~clk;
endmodule