`timescale 1ns/1ps
`include "transmitter.v"
`include "transmitter_gen.v"
module transmitter_tb;
parameter data_width = 8;
reg tx_clk;
reg rst_n;
wire [data_width-1:0] data_in;
wire enable;
wire tx_out;

transmitter tm1(
    tx_clk,
    rst_n,
    data_in,
    enable,

    tx_out
);

transmitter_gen tg1(
    tx_clk,
    rst_n,
    
    enable,
    data_in
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
    rst_n<=1'b0;
    $dumpfile("transmitter.vcd");
    $dumpvars;
    #45 rst_n<=1;
    #4000 $finish;
end

always #10
    tx_clk<=~tx_clk;
endmodule