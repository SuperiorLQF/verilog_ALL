`timescale 1ns/100ps
module cmp(
    input   Gi,
    Ei,
    input   Ai,
    Bi,
    output  Go,
    Eo
  );
  assign  Eo=Ei&&(Ai==Bi);
  assign  Go=(Ai>Bi)||(Ai==Bi)&&Gi;
  //assign  Lo=(~Eo)&&(~Go);//不大不相等那肯定是小
endmodule
