/*******************<MCDF测试1>*********************/
`timescale 1ns/100ps
`include "MCDF.v"
/*************************<端口声明>*********************/
module MCDF_tb1;
reg                     clk         ,
                        rst_n       ;
// >>slave接口(3*3)
reg             [31:0]  ch0_data    ;
reg                     ch0_valid   ;
wire                    ch0_ready   ;

reg             [31:0]  ch1_data    ;
reg                     ch1_valid   ;
wire                    ch1_ready   ;

reg             [31:0]  ch2_data    ;
reg                     ch2_valid   ;
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

/*************************<初始化>*********************/
initial begin
    clk<=0;
    rst_n<=0;
        $dumpfile("MCDF_tb1.vcd");
        $dumpvars;
/*************************<驱动信号>*********************/

#2000   $finish;
end
always #10 clk<=~clk;
endmodule