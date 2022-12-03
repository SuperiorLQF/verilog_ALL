/*************************<MCDF通道从端>*********************/
`timescale 1ns/100ps
`include "SCFIFO.v"
/*************************<端口声明>*********************/
module  slave_FIFO
#(
    parameter   DATA_DEPTH = 'd64 			//FIFO深度
)
(
    input                   clk_i,          //时钟
                            rstn_i,         //复位
                            chx_valid_i,    //外部信号有效信号
                            a2sx_ack_i,     //仲裁器允许读数据包
                            slvx_en_i,      //通道使能(来自寄存器)
    input   wire    [31:0]  chx_data_i,
    input   wire    [2:0]   slvx_pkglen_i,   //本通道数据包长度

    output  wire            chx_ready_o,    //允许接收外部信号(如果FIFO比较满就不接收)
    output  wire    [5:0]   margin_o,       //本通道FIFO余量
    output  wire    [31:0]  slvx_data_o,    //发送给仲裁器的数据
    output  reg             slvx_val_o,     //发送给仲裁器的数据有效
    output  wire            slvx_req_o      

);
/*************************<中间信号>*********************/
wire [5:0] pkglen;
integer i;
wire    wr_en,
        rd_en,
        rst_n;
assign wr_en=chx_valid_i&chx_ready_o;
assign chx_ready_o=(margin_o>='d32);//这里比较充裕，可以(margin_o<slvx_pkglen_i)
assign rst_n=rstn_i&slvx_en_i;
assign pkglen=2**(slvx_pkglen_i+'d2);//因为slvx_pkglen_i时[2:0]所以+2不会溢出
/*************************<实例化SCFIFO>*********************/
SCFIFO FIFO1(
    .clk(clk_i)		,	
    .rst_n(rst_n)	,    
    .data_in(chx_data_i)	,    
    .rd_en(rd_en)	,    
    .wr_en(wr_en)	,    
                 
    .data_out(slvx_data_o),	 
    .empty(),//保留	 
    .full(), //保留	
    .FIFO_margin_o(margin_o)
);
/*************************<时序电路>*********************/
always @(posedge clk_i or negedge rst_n) begin//产生输出长度i计数信号
    if(~rst_n)
        i<=0;
    else if(a2sx_ack_i==1)
        i<=1;
    else if(i>0 && i<pkglen)//^^C语言连续不等式是错误的
        i<=i+1;
    else
        i<=0;        
end
always @(posedge clk_i or negedge rst_n) begin
    if(~rst_n)
        slvx_val_o<=0;
    else
        slvx_val_o<=rd_en;
end
/*************************<组合电路>*********************/
assign rd_en=(i==0)?0:1;
assign slvx_req_o=(margin_o<=DATA_DEPTH-pkglen)?1:0;//如果FIFO使用量大于一个pkglen，则请求发送
endmodule
// always @(posedge clk_i or negedge rst_n) begin//注意连续性，接完一个数据包立马接下一个
//     if(~rst_n)
//         j<=0;
//     else if(j>=pkglen && wr_en==1)
//         j<=1;
//     else if(j>=pkglen && wr_en==0)
//         j<=0;
//     else if(j< pkglen && wr_en==1)
//         j<=j+1;
//     else//j< pkglen && wr_en==0
//         j<=j;
// end