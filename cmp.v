module cmp8 (
input wire [7:0] A, B,
output wire Go, Eo, Lo
);
//*********<例化>*************

cmp cmp1(
    0, 0, 0,
    A[i], B[i],
    Gi[1], Ei[1], Li[1]
    );
generate
    genvar i;
    for(i=0;i<7;i=i+1)begin
        cmp cmp2(
            Gi[i], Ei[i], Li[i],
            A[i], B[i],
            Gi[i+1], Ei[i+1], Li[i+1]
            );
            
    end
endgenerate
endmodule

