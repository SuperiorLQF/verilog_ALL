/***************<MCDF 顶层文件>*********************/
`timescale 1ns/100ps
`include "../slave_FIFO/slave_FIFO.v"
`include "../control_register/control_register.v"
`include "../arbiter/arbiter.v"
`include "../formatter/formatter.v"
/***************<MCDF 顶层文件端口>*********************/
module MCDF
(
    input                   clk         ,
                            rst_n       ,
// >>slave接口(3*3)
    input   wire    [31:0]  ch0_data    ,
    input                   ch0_valid   ,
    output                  ch0_ready   ,

    input   wire    [31:0]  ch1_data    ,
    input                   ch1_valid   ,
    output                  ch1_ready   ,

    input   wire    [31:0]  ch2_data    ,
    input                   ch2_valid   ,
    output                  ch2_ready   ,
// >>formatter接口(7)
    input                   fmt_grant   ,
    output  wire    [1:0]   fmt_child   ,
    output  wire    [5:0]   fmt_length  ,
    output                  fmt_req     ,
    output  wire    [31:0]  fmt_data    ,
    output                  fmt_start   ,
    output                  fmt_end     ,

// >>control_register接口(4)    
    input   wire    [1:0]   cmd         ,
    input   wire    [5:0]   cmd_addr    ,
    input   wire    [31:0]  cmd_data_i  ,
    output  wire    [31:0]  cmd_data_o
);
/***************<中间信号>*********************/
wire    [5:0]   slv0_margin,//slv->cr
                slv1_margin,
                slv2_margin;
wire            slv0_en,    //cr->slv
                slv1_en,
                slv2_en;
wire    [1:0]   slv0_prio,  //cr->arbiter
                slv1_prio,
                slv2_prio;
wire    [2:0]   slv0_pkglen, //cr->slv
                slv1_pkglen,
                slv2_pkglen;
wire            a2s0_ack,   //arbiter->slv
                a2s1_ack,
                a2s2_ack;
wire    [31:0]  slv0_data,  //slv->arbiter
                slv1_data,
                slv2_data;
wire            slv0_val,   //slv->arbiter
                slv1_val,
                slv2_val;
wire            slv0_req,   //slv->arbiter
                slv1_req,
                slv2_req;
wire            slv0_end,   //slv->arbiter
                slv1_end,
                slv2_end;
wire            f2a_id_req          ,//formatter->arbiter 
                f2a_ack             ;           
wire            a2f_val             ,//arbiter->formatter-    
                a2f_end             ;
wire    [1:0]   a2f_id              ;         
wire    [31:0]  a2f_data            ;      
wire    [2:0]   a2f_pkglen_sel      ;    
/***************<实例化模块>*********************/
//控制寄存器
control_register cr0(
    .clk_i          (clk),
    .rstn_i         (rst_n),
    .cmd_i          (cmd),
    .cmd_addr_i     (cmd_addr),        
    .cmd_data_i     (cmd_data_i),         
    .slv0_margin_i  (slv0_margin),    
    .slv1_margin_i  (slv1_margin),    
    .slv2_margin_i  (slv2_margin),    
    .slv0_en_o      (slv0_en),    
    .slv1_en_o      (slv1_en),    
    .slv2_en_o      (slv2_en),    
    .cmd_data_o     (cmd_data_o),        
    .slv0_prio_o    (slv0_prio),    
    .slv1_prio_o    (slv1_prio),        
    .slv2_prio_o    (slv2_prio),        
    .slv0_pkglen_o  (slv0_pkglen),        
    .slv1_pkglen_o  (slv1_pkglen),        
    .slv2_pkglen_o  (slv2_pkglen)        
);
//接收器
slave_FIFO slave0(
    .clk_i         (clk),      
    .rstn_i        (rst_n),            
    .chx_valid_i   (ch0_valid),       
    .a2sx_ack_i    (a2s0_ack),            
    .slvx_en_i     (slv0_en),            
    .chx_data_i    (ch0_data),         
    .slvx_pkglen_i (slv0_pkglen),         
    .chx_ready_o   (ch0_ready),             
    .margin_o      (slv0_margin),            
    .slvx_data_o   (slv0_data),          
    .slvx_val_o    (slv0_val),            
    .slvx_req_o    (slv0_req),       
    .slvx_end_o    (slv0_end)
);
slave_FIFO slave1(
    .clk_i         (clk),      
    .rstn_i        (rst_n),            
    .chx_valid_i   (ch1_valid),       
    .a2sx_ack_i    (a2s1_ack),            
    .slvx_en_i     (slv1_en),            
    .chx_data_i    (ch1_data),         
    .slvx_pkglen_i (slv1_pkglen),         
    .chx_ready_o   (ch1_ready),             
    .margin_o      (slv1_margin),            
    .slvx_data_o   (slv1_data),          
    .slvx_val_o    (slv1_val),            
    .slvx_req_o    (slv1_req),       
    .slvx_end_o    (slv1_end)    
);
slave_FIFO slave2(
    .clk_i         (clk),      
    .rstn_i        (rst_n),            
    .chx_valid_i   (ch2_valid),       
    .a2sx_ack_i    (a2s2_ack),            
    .slvx_en_i     (slv2_en),            
    .chx_data_i    (ch2_data),         
    .slvx_pkglen_i (slv2_pkglen),         
    .chx_ready_o   (ch2_ready),             
    .margin_o      (slv2_margin),            
    .slvx_data_o   (slv2_data),          
    .slvx_val_o    (slv2_val),            
    .slvx_req_o    (slv2_req),       
    .slvx_end_o    (slv2_end)    
);
//仲裁器
arbiter arb0(
    .clk_i             (clk),           
    .rstn_i            (rst_n),       
    .slv0_prio_i       (slv0_prio),      
    .slv1_prio_i       (slv1_prio),  
    .slv2_prio_i       (slv2_prio),  
    .slv0_pkglen_i     (slv0_pkglen),      
    .slv1_pkglen_i     (slv1_pkglen),      
    .slv2_pkglen_i     (slv2_pkglen),      
    .slv0_data_i       (slv0_data),      
    .slv1_data_i       (slv1_data),      
    .slv2_data_i       (slv2_data),  
    .slv0_req_i        (slv0_req),  
    .slv1_req_i        (slv1_req),  
    .slv2_req_i        (slv2_req),   
    .slv0_val_i        (slv0_val),      
    .slv1_val_i        (slv1_val),      
    .slv2_val_i        (slv2_val),  
          
    .slv0_end_i        (slv0_end),      
    .slv1_end_i        (slv1_end),       
    .slv2_end_i        (slv2_end),      
    .f2a_id_req_i      (f2a_id_req),        
    .f2a_ack_i         (f2a_ack),      
    .a2s0_ack_o        (a2s0_ack),            
    .a2s1_ack_o        (a2s1_ack),  
    .a2s2_ack_o        (a2s2_ack),  
    .a2f_val_o         (a2f_val),        
    .a2f_id_o          (a2f_id),             
    .a2f_data_o        (a2f_data),       
    .a2f_pkglen_sel_o  (a2f_pkglen_sel),      
    .a2f_end_o         (a2f_end)         
);
//整形器
formatter fm0(
    .clk_i             (clk),  
    .rstn_i            (rst_n),  
    .a2f_val_i         (a2f_val),  
    .a2f_id_i          (a2f_id),  
    .a2f_data_i        (a2f_data),  
    .a2f_pkglen_sel_i  (a2f_pkglen_sel),  
    .fmt_grant_i       (fmt_grant),  
    .a2f_end_i         (a2f_end),  
    .f2a_ack_o         (f2a_ack),      
    .fmt_id_req_o      (f2a_id_req),      
    .fmt_child_o       (fmt_child),  
    .fmt_length_o      (fmt_length),      
    .fmt_req_o         (fmt_req),      
    .fmt_data_o        (fmt_data),  
    .fmt_start_o       (fmt_start),  
    .fmt_end_o         (fmt_end) 
);
endmodule