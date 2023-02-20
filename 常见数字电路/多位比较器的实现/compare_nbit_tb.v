`timescale 1ns/100ps
`include "compare_nbit.v"
module  compare_nbit_tb;
parameter   N=8;
reg [N-1:0]     A, B;
wire            Go, Eo, Lo;
//*********<模块例化>*************
cmp_n 
#(
    .N(N)
)
cmp_8
(
    .A(A),
    .B(B),
    
    .Go(Go),
    .Eo(Eo),
    .Lo(Lo)
);
initial begin
    $dumpfile("cmp_n.vcd");
    $dumpvars;
    A='b0;
    B='b0;
    repeat(20)  begin
      #10   A=$random;B=$random;
    end
    #500 $finish;
end



endmodule