/***************<MCDF 顶层文件>*********************/
`timescale 1ns/100ps
`include "../slave_FIFO/slave_FIFO.v"
`include "../control_register/control_register.v"
`include "../arbiter/arbiter.v"
`include "../formatter/formatter.v"
module MCDF
(
    input  a,
    output b
);
assign b=a;
endmodule