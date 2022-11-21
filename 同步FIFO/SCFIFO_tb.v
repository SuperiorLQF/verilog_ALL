`timescale 1ns/1ns
`include "SCFIFO.v"
module SCFIFO_tb;
//************<端口声明>****************
reg             clk,
                reset_n;
reg     [3:0] data_in;
reg             rd,
                wr;
wire    [3:0] data_out;
wire            full,
                empty;   
//***********<模块例化>******************
SCFIFO FIFO1
(
    .clk(clk),
    .reset_n(reset_n),
    .data_in(data_in),
    .rd(rd),
    .wr(wr),

    .data_out(data_out),
    .full(full),
    .empty(empty)
);
initial begin
    $dumpfile("SCFIFO.vcd");
    $dumpvars;
    reset_n<=0;
    clk<=0;
    data_in='b0;
    rd<=0;
    wr<=0;
    #35 reset_n<=1'b1;
    repeat(32)begin
      @(negedge clk)
      begin
        rd<=0;
        wr<=0;
        data_in<=$random;
      end
    end
    #1000 $finish;
end
initial begin
  repeat(64)
    #10 clk<=~clk;
end

endmodule
