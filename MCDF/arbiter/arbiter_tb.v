`timescale 1ns/1ns
`include "arbiter.v"
/*************************<端口声明>*********************/
module arbiter_tb;
reg             clk_i,
                rstn_i;
/********<control register 接口>*******/
reg     [1:0]   slv0_prio_i,
                slv1_prio_i,
                slv2_prio_i;
reg     [2:0]   slv0_pkglen_i,
                slv1_pkglen_i,
                slv2_pkglen_i;
/********<slave 接口>*********************/
reg     [31:0]  slv0_data_i,
                slv1_data_i,
                slv2_data_i;
reg             slv0_req_i,
                slv1_req_i,
                slv2_req_i,    
                slv0_val_i,
                slv1_val_i,
                slv2_val_i,
                
                slv0_end_i,
                slv1_end_i,
                slv2_end_i;

/********<formatter 接口>*********************/    
reg             f2a_id_req_i,       //formatter请求接收
                f2a_ack_i;
/********<slave 接口>*********************/    
wire            a2s0_ack_o,         //[-slv]f2a_ack_i
                a2s1_ack_o,
                a2s2_ack_o,
/********<formatter 接口>*********************/
                a2f_val_o;         //[-slv]slvx_val_i,包有效包络信号
wire    [1:0]   a2f_id_o;           //通道编号
wire    [31:0]  a2f_data_o;         //[-slv]slvx_data_i
wire    [2:0]   a2f_pkglen_sel_o;    //[-slv]slvx_pkglen_i

/********************<实例化arbiter>*********************/
arbiter ar1(
    clk_i,
    rstn_i,

    slv0_prio_i,
    slv1_prio_i,
    slv2_prio_i,
    slv0_pkglen_i,
    slv1_pkglen_i,
    slv2_pkglen_i,

    slv0_data_i,
    slv1_data_i,
    slv2_data_i,
    slv0_req_i,
    slv1_req_i,
    slv2_req_i,    
    slv0_val_i,
    slv1_val_i,
    slv2_val_i,

    slv0_end_i,
    slv1_end_i,
    slv2_end_i,

    f2a_id_req_i,   
    f2a_ack_i,

    a2s0_ack_o,     
    a2s1_ack_o,
    a2s2_ack_o,

    a2f_val_o,     
    a2f_id_o,       
    a2f_data_o,     
    a2f_pkglen_sel_o,
    
    a2f_end_o
);
initial begin
/*********<初始化>**********/
    clk_i<=0;
    rstn_i<=0;//

    slv0_end_i<=0;
    slv1_end_i<=0;
    slv2_end_i<=0;

    slv0_prio_i<=2'b11;//
    slv1_prio_i<=2'b01;//这个是最优先通道
    slv2_prio_i<=2'b01;//次优先通道
    slv0_pkglen_i<=2'b10;//
    slv1_pkglen_i<=2'b01;//数据长8
    slv2_pkglen_i<=2'b00;//数据长4

    slv0_data_i<=$random;
    slv1_data_i<=$random;
    slv2_data_i<=$random;
    slv0_req_i<=0;
    slv1_req_i<=0;
    slv2_req_i<=0; 
    slv0_val_i<=0;
    slv1_val_i<=0;
    slv2_val_i<=0;

    f2a_id_req_i<=0;//短时信号，在slvx_req_i就绪之后  
    f2a_ack_i<=0;//在slvx_req_i就绪之后
    $dumpfile("arbiter.vcd");
    $dumpvars;
/*********<生成波形>**********/
#25     rstn_i<=1;
#20     slv0_req_i<=1;
        slv1_req_i<=1;
        slv2_req_i<=1;
@(posedge clk_i)begin
    f2a_id_req_i<=1;//两个短时信号
end

@(posedge clk_i)begin
    f2a_id_req_i<=0;
    f2a_ack_i<=1;     
end

@(posedge clk_i)begin
    f2a_ack_i<=0;     
end
 
        repeat(8)begin
            @(posedge clk_i)begin
                slv0_data_i<=$random;
                slv1_data_i<=$random;
                slv2_data_i<=$random;
                slv0_val_i<=0;
                slv1_val_i<=1;
                slv2_val_i<=0;                
            end
        end
        slv0_end_i<=1;
        slv1_end_i<=1;
        slv2_end_i<=1; 
@(posedge clk_i)begin
    slv0_data_i<=$random;
    slv1_data_i<=$random;
    slv2_data_i<=$random;
    slv0_end_i<=0;
    slv1_end_i<=0;
    slv2_end_i<=0; 
    slv0_val_i<=0;
    slv1_val_i<=0;
    slv2_val_i<=0;
    slv0_req_i<=0;
    slv1_req_i<=0;
    slv2_req_i<=0;                
end
#2000   $finish;
end
always #10 clk_i<=~clk_i;
endmodule