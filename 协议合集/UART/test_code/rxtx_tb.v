`timescale 1ns/1ps
`include "transmitter.v"
`include "transmitter_gen.v"
`include "receiver.v"
module rxtx_tb;
parameter data_width = 8;

reg tx_clk,rx_clk;
reg rst_n;

wire [data_width-1:0] data_source;
wire [data_width-1:0] rx_out;
wire enable;
wire tx_out;
//***************<模块实例化>******************
transmitter tm1(
    tx_clk,
    rst_n,
    data_source,
    enable,

    tx_out
);

transmitter_gen tg1(
    tx_clk,
    rst_n,
    
    enable,
    data_source
);

receiver rv1(
    rx_clk,
    rst_n,
    tx_out,

    rx_out
);

// initial begin
//     tx_clk<=1'b0;
//     rst_n<=1'b0;
//     data_in<=$random;
//     enable<=0;
//     $dumpfile("transmitter.vcd");
//     $dumpvars;
//     #45 rst_n<=1;
//     repeat(10)begin
//         data_in<=$random;
//        @(posedge tx_clk)    enable<=1;
//        @(posedge tx_clk)    enable<=0; 
//     #400;
//     end

//     #1000 $finish;
// end
initial begin
    tx_clk<=1'b0;
    rx_clk<=1'b0;
    rst_n<=1'b0;
    $dumpfile("rttx.vcd");
    $dumpvars;
    #45 rst_n<=1;
    #10000 $finish;
end

always #60
    tx_clk<=~tx_clk;
always #5
    rx_clk<=~rx_clk;
endmodule