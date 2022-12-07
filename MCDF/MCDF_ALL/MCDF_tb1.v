/*******************<MCDF测试1>*********************/
`timescale 1ns/100ps
`include "MCDF.v"
/*************************<端口声明>*********************/
module MCDF_tb1;
parameter               RD=2'b01;
parameter               WR=2'b10;
parameter               IDLE=2'b00;
reg                     clk         ,
                        rst_n       ;
// >>slave接口(3*3)
reg             [31:0]  ch0_data    ;
reg                     ch0_valid   ;//先不验证
wire                    ch0_ready   ;

reg             [31:0]  ch1_data    ;
reg                     ch1_valid   ;//先不验证
wire                    ch1_ready   ;

reg             [31:0]  ch2_data    ;
reg                     ch2_valid   ;//先不验证
wire                    ch2_ready   ;
// >>formatter接口(7)
reg                     fmt_grant   ;
wire            [1:0]   fmt_child   ;
wire            [5:0]   fmt_length  ;
wire                    fmt_req     ;
wire            [31:0]  fmt_data    ;
wire                    fmt_start   ;
wire                    fmt_end     ;

// >>control_register接口(4)    
reg             [1:0]   cmd         ;
reg             [5:0]   cmd_addr    ;
reg             [31:0]  cmd_data_i  ;
wire            [31:0]  cmd_data_o  ;
/*************************<实例化MCDF>*********************/
MCDF MCDF_inst0
(
     clk         ,
     rst_n       ,

     ch0_data    ,
     ch0_valid   ,
     ch0_ready   ,

     ch1_data    ,
     ch1_valid   ,
     ch1_ready   ,

     ch2_data    ,
     ch2_valid   ,
     ch2_ready   ,

     fmt_grant   ,
     fmt_child   ,
     fmt_length  ,
     fmt_req     ,
     fmt_data    ,
     fmt_start   ,
     fmt_end     ,

     cmd         ,
     cmd_addr    ,
     cmd_data_i  ,
     cmd_data_o
);
/*************************<任务>*********************/
//不能用任务因为不支持多条语句
/*************************<初始化>*********************/
initial begin
    clk<=0;
    rst_n<=0;
    ch0_data<=0;
    ch1_data<=0;
    ch2_data<=0;
    ch0_valid<=0;//等待通道配置完毕再发送数据
    ch1_valid<=0;
    ch2_valid<=0;
    fmt_grant<=0;//^^
    cmd      <=IDLE;
    cmd_addr <=6'b00_0000;
    cmd_data_i<=32'b001_001;//写入则打开
        $dumpfile("MCDF_tb1.vcd");
        $dumpvars;
/*************************<驱动信号>*********************/
#15 rst_n<=1;//启动
/**************control_register测试*********************/
//先给寄存器赋值
#40
@(posedge clk)begin//配置通道0
    cmd<=WR;
    cmd_addr<=6'h0;
    cmd_data_i<=32'b010_01_1;
end
@(posedge clk)begin//配置通道1
    cmd<=WR;
    cmd_addr<=6'h4;
    cmd_data_i<=32'b000_00_1;
end
@(posedge clk)begin//配置通道2
    cmd<=WR;
    cmd_addr<=6'h8;
    cmd_data_i<=32'b001_00_1;
end
//查询寄存器配置结果
@(posedge clk)begin
    cmd<=RD;
    cmd_addr<=6'h0;
end
repeat(5)begin
    @(posedge clk)
        cmd_addr<=cmd_addr+'d4;
end
#20
cmd_addr<='h10;
#20
/**************数据传输*********************/
@(posedge clk)begin
ch0_valid<=1;
ch1_valid<=1;
ch2_valid<=1;
end
//需要等待握手ack
#80
@(posedge clk)begin
    ch1_valid<=0;//关闭
end
#40
@(posedge clk)begin//这里可以给grant加入逻辑，在fmt_req之后降低
    fmt_grant<=1;
end
@(posedge clk)begin
    fmt_grant<=1;
end
@(posedge clk)begin
    fmt_grant<=0;
end
#120
@(posedge clk)begin
    fmt_grant<=1;
    ch2_valid<=0;//关闭ch2
end
@(posedge clk)begin
    fmt_grant<=1;
end
@(posedge clk)begin
    fmt_grant<=0;
end
#80
@(posedge clk)begin
    ch0_valid<=0;//关闭ch0
end
#120
@(posedge clk)begin//这里可以给grant加入逻辑，在fmt_req之后降低
    fmt_grant<=1;
end
@(posedge clk)begin
    fmt_grant<=1;
end
@(posedge clk)begin
    fmt_grant<=0;
end
#2000   $finish;
end
always #10 clk<=~clk;
always @(posedge clk) begin
    ch0_data<=$random;
    ch1_data<=$random;
    ch2_data<=$random;
end
endmodule