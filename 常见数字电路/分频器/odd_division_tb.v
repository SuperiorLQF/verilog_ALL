`include "odd_division.v"
`timescale 1ns/1ps
module odd_division_tb;
reg    clk_i;
reg    rst_n;
wire   clk_division;

odd_division#(.ODD_NUM(7)) od1(
    clk_i,
    rst_n,
    clk_division
);
initial begin
    $dumpfile("odd_division.vcd");
    $dumpvars;
    rst_n<=0;
    clk_i<=0;
    #32     rst_n<=1;
    #1000 $finish;
end
always #5 clk_i=~clk_i;

endmodule