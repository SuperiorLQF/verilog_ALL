`timescale 1ns/100ps
`include "memory.v"
module  SCFIFO
#(
    parameter   W=4,//位宽
                L=4//地址
)
(
    input   clk,
            reset_n,
    input   wire [W-1:0] data_in,
    input   rd,
            wr,
    output  wire [W-1:0] data_out,
    output  full,
            empty            
);
reg    [L:0]       rd_addr;
reg    [L:0]       wr_addr;
wire    [L-1:0]     rd_addr_true;
wire    [L-1:0]     wr_addr_true;
wire    rd_addr_msb;
wire    wr_addr_msb;
wire    [3:0]   NULL_port;
assign  {rd_addr_msb,rd_addr_true}=rd_addr;
assign  {wr_addr_msb,wr_addr_true}=wr_addr;

memory memory1
(
    .clk(clk), 
    .data_A({4'b0,data_in}), //写数据
    .addr_A({1'b0,wr_addr_true}), 
    
    .data_B({NULL_port,data_out}), //读数据
    .addr_B({1'b0,rd_addr_true}), 
    .rd(rd),     //读信号，低有效
	.wr(rd)      //写信号，低有效
);
always @(posedge clk or negedge reset_n) begin//读
    if(~reset_n)
        rd_addr<='b0;
    else if(~rd&&~empty)begin//可读
        rd_addr<=rd_addr+1'b1;
    end   
end
always @(posedge clk or negedge reset_n) begin//写
    if(~reset_n)
        wr_addr<='b0;
    else if(~wr&&~full)begin//可写
        wr_addr<=wr_addr+1'b1;
    end    
end
assign empty=((rd_addr_msb==wr_addr_msb) && (rd_addr_true+'d4 > wr_addr_true))?1'b1:1'b0;//读空
assign full=((rd_addr_msb!=wr_addr_msb) && (rd_addr_true + 'd11 < wr_addr_true))?1'b1:1'b0;//写满
endmodule
