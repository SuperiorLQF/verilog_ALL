`timescale 1ns/100ps
`include "compare_1bit.v"
//*********<端口声明>*************
module cmp_n#
(
    parameter N=8
)
(
input   wire[N-1:0]     A, B,
output  wire            Go, Eo, Lo
);
//*********<中间信号>*************
wire [N:0]  Gi,Ei;
assign  Gi[0]=1'b0;
assign  Ei[0]=1'b1;
assign  Go=Gi[N];
assign  Eo=Ei[N];
assign  Lo=(~Go)&&(~Eo);
//*********<模块例化>*************
generate
    genvar i;
    for(i=0;i<8;i=i+1)begin
        cmp cmp2(
            Gi[i], Ei[i],
            A[i], B[i],
            Gi[i+1], Ei[i+1]
            );            
    end
endgenerate
endmodule

