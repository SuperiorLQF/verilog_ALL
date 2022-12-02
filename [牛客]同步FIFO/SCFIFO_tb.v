`timescale 1ns/1ns
`include "SCFIFO.v"
module  SCFIFO_tb;
/*****************<端口声明>******************/
parameter	WIDTH = 8;
parameter 	DEPTH = 16;
reg     			clk		;
reg        			rst_n	;
reg        			winc	;
reg        	 		rinc	;
reg     [WIDTH-1:0]	wdata	;
wire	    		wfull	;
wire    	    	rempty	;

wire    [WIDTH-1:0]	rdata   ;
/*****************<模块例化>******************/
sfifo
#(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
)
sfifo_inst1(
    .clk(clk),
    .rst_n(rst_n),
    .winc(winc),
    .rinc(rinc),
    .wdata(wdata),
    .wfull(wfull),
    .rempty(rempty),
    
    .rdata(rdata)
);
initial begin
    $dumpfile("SCFIFO_tb.vcd");
    $dumpvars;
    clk<='b0;
    rst_n<='b0;
    winc<='b1;
    rinc<='b0;
    wdata<='b0;
    #35 rst_n<=1'b1;
    repeat(18)begin
        @(negedge clk)
        wdata<=$random;
    end
    winc<=1'b0;
    rinc<=1'b1;
    repeat(18)begin
        @(negedge clk)
        wdata<=$random;
    end
    #1000 $finish;
end
always #10 clk=~clk;
endmodule