`timescale 1ns/1ns
`include "memory.v"
module FIFO ( 
    input  wire 	   rst_n,  //低电平有效复位信号
    input  wire 	   clk,  //时钟信号
    input  wire [3:0] data_in, //输入数据
    output wire [3:0] data_out, //输出数据
    input  wire 	    rd,    //低电平有效读信号
		           		wr,    //低电平有效写信号
    output  wire 	   full,  //数据个数大于11 
		           empty //数据个数小于4
    ); 

reg			[7:0]	data_A;//写
reg			[7:0]	data_B;//读
wire		[4:0]	addr_A;
wire		[4:0]	addr_B;

//assign data_A={4'b0,data_in};
//assign data_out={data_B,4'b0};
assign addr_A={1'b0,wr_ptr_true};
assign addr_B={1'b0,wr_ptr_true};

Memory mem1(clk,data_A,addr_A,data_B,addr_B,rd,wr);

reg [4 : 0]        	wr_ptr;                     //写地址指针，位宽多一位   
reg [4 : 0]        	rd_ptr;                     //读地址指针，位宽多一位   
 
wire [3 : 0]   		wr_ptr_true;                //真实写地址指针
wire [3 : 0]   		rd_ptr_true;                //真实读地址指针
wire           		wr_ptr_msb;                 //写地址指针地址最高位
wire           		rd_ptr_msb;                 //读地址指针地址最高位
 
assign {wr_ptr_msb,wr_ptr_true} = wr_ptr;                       //将最高位与其他位拼接
assign {rd_ptr_msb,rd_ptr_true} = rd_ptr;                       //将最高位与其他位拼接
 
//读操作,更新读地址
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0)begin
        rd_ptr <= 'd0;
	end
    else if (rd_en && !empty)begin                              //读使能有效且非空
        {4'b0,data_out} <= data_B;
        rd_ptr <= rd_ptr + 1'd1;
    end
end
//写操作,更新写地址
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        wr_ptr <= 0;
    else if (!full && wr_en)begin                               //写使能有效且非满
        wr_ptr <= wr_ptr + 1'd1;
        data_A <= {4'b0,data_in};
    end 
end
 
assign	empty = ( wr_ptr < rd_ptr +4 ) ? 1'b1 : 1'b0;
//当最高位不同但是其他位相等时，写指针超过读指针一圈，FIFO被写满
assign	full  = ( (wr_ptr_msb != rd_ptr_msb ) && ( wr_ptr_true + 5 > rd_ptr_true ) )? 1'b1 : 1'b0;
 