`timescale 1ns/1ns	//时间单位/精度
 `include "SCFIFO2.v"
//------------<模块及端口声明>----------------------------------------
module SCFIFO2_tb();
 
parameter   DATA_WIDTH = 'd32  ;			//FIFO位宽
parameter   DATA_DEPTH = 'd64 ;				//FIFO深度
 
reg									clk		;
reg									rst_n	;
reg		[DATA_WIDTH-1:0]			data_in	;
reg									rd_en	;
reg									wr_en	;
						
wire	[DATA_WIDTH-1:0]			data_out;	
wire								empty	;	
wire								full	;

wire [5:0]                          FIFO_margin_o;   //FIFO通道余量64也算作63
 
//------------<例化被测试模块>----------------------------------------
SCFIFO2
#(
	.DATA_WIDTH	(DATA_WIDTH),			//FIFO位宽
    .DATA_DEPTH	(DATA_DEPTH)			//FIFO深度
)
SCFIFO2_inst(
	.clk		(clk		),
	.rst_n		(rst_n		),
	.data_in	(data_in	),
	.rd_en		(rd_en		),
	.wr_en		(wr_en		),
                 
	.data_out	(data_out	),	
	.empty		(empty		),	
	.full		(full		),
	.FIFO_margin_o(FIFO_margin_o)		
);
 
//------------<设置初始测试条件>----------------------------------------
initial begin
	clk = 1'b0;							//初始时钟为0
	rst_n <= 1'b0;						//初始复位
	data_in <= 'd0;		
	wr_en <= 1'b0;		
	rd_en <= 1'b0;
    $dumpfile("SCFIFO2.vcd");
    $dumpvars;
//重复8次写操作，让FIFO写满 	
	repeat(10) begin		
		@(negedge clk)begin		
			rst_n <= 1'b1;				
			wr_en <= 1'b1;		
			data_in <= $random;			//生成8位随机数
		end
	end
//重复8次读操作，让FIFO读空	
	repeat(10) begin
		@(negedge clk)begin		
			wr_en <= 1'b0;
			rd_en <= 1'd1;
		end
	end
//重复4次写操作，写入4个随机数据	
	repeat(4) begin
		@(negedge clk)begin		
			wr_en <= 1'b1;
			data_in <= $random;	//生成8位随机数
			rd_en <= 1'b0;
		end
	end
// //持续同时对FIFO读写，写入数据为随机数据	
// 	forever begin
// 		@(negedge clk)begin		
// 			wr_en <= 1'b1;
// 			data_in <= $random;	//生成8位随机数
// 			rd_en <= 1'b1;
// 		end
// 	end
    #1000 $finish;
end
 
//------------<设置时钟>----------------------------------------------
always #10 clk = ~clk;			//系统时钟周期20ns
 
endmodule