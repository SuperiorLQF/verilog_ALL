/****************<slave_FIFO的64深度同步FIFO，指针方式实现>*********************/
`timescale 1ns/100ps
module	SCFIFO2
#(
	parameter   DATA_WIDTH = 'd32  ,							//FIFO位宽
    parameter   DATA_DEPTH = 'd64 								//FIFO深度
)
(
	input										clk		,		//系统时钟
	input										rst_n	,       //低电平有效的复位信号
	input	[DATA_WIDTH-1:0]					data_in	,       //写入的数据
	input										rd_en	,       //读使能信号，高电平有效
	input										wr_en	,       //写使能信号，高电平有效
						                                        
	output	reg	[DATA_WIDTH-1:0]				data_out,	    //输出的数据
	output										empty	,	    //空标志，高电平表示当前FIFO已被写满
	output										full,		    //满标志，高电平表示当前FIFO已被读空
    
    output  wire [5:0]                          FIFO_margin_o   //FIFO通道余量64也算作63
);                                                              
 
//reg define
//用二维数组实现RAM
reg [DATA_WIDTH - 1 : 0]			fifo_buffer[DATA_DEPTH - 1 : 0];	
reg [$clog2(DATA_DEPTH) : 0]		wr_ptr;						//写地址指针，位宽多一位	
reg [$clog2(DATA_DEPTH) : 0]		rd_ptr;						//读地址指针，位宽多一位	
 
//wire define
wire [$clog2(DATA_DEPTH) - 1 : 0]	wr_ptr_true;				//真实写地址指针
wire [$clog2(DATA_DEPTH) - 1 : 0]	rd_ptr_true;				//真实读地址指针
wire								wr_ptr_msb;					//写地址指针地址最高位
wire								rd_ptr_msb;					//读地址指针地址最高位
 
assign {wr_ptr_msb,wr_ptr_true} = wr_ptr;						//将最高位与其他位拼接
assign {rd_ptr_msb,rd_ptr_true} = rd_ptr;						//将最高位与其他位拼接

assign FIFO_margin_o=(~empty)?('d64-(wr_ptr-rd_ptr)):'b11_1111;
//读操作,更新读地址
always @ (posedge clk or negedge rst_n) begin
	if (rst_n == 1'b0)
		rd_ptr <= 'd0;//读地址清零
	else if (rd_en && !empty)begin								//读使能有效且非空
		data_out <= fifo_buffer[rd_ptr_true];
		rd_ptr <= rd_ptr + 1'd1;
	end
end
//写操作,更新写地址
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n)
		wr_ptr <= 0;//写地址清零
	else if (!full && wr_en)begin								//写使能有效且非满
		wr_ptr <= wr_ptr + 1'd1;
		fifo_buffer[wr_ptr_true] <= data_in;
	end	
end
 
//更新指示信号
//当所有位相等时，读指针追到到了写指针，FIFO被读空
assign	empty = ( wr_ptr == rd_ptr ) ? 1'b1 : 1'b0;
//当最高位不同但是其他位相等时，写指针超过读指针一圈，FIFO被写满
assign	full  = ( (wr_ptr_msb != rd_ptr_msb ) && ( wr_ptr_true == rd_ptr_true ) )? 1'b1 : 1'b0;
 
endmodule