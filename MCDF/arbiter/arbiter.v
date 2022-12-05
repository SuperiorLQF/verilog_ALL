/*************************<MCDF仲裁器>*********************/
`timescale 1ns/100ps
/*************************<端口声明>*********************/
module arbiter
(
//Input
    input   wire            clk_i,
                            rstn_i,
/*******************<control register 接口>*******/
    input   wire    [1:0]   slv0_prio_i,
                            slv1_prio_i,
                            slv2_prio_i,
    input   wire    [2:0]   slv0_pkglen_i,
                            slv1_pkglen_i,
                            slv2_pkglen_i,
/*******************<slave 接口>*********************/
    input   wire    [31:0]  slv0_data_i,
                            slv1_data_i,
                            slv2_data_i,
    input   wire            slv0_req_i,
                            slv1_req_i,
                            slv2_req_i,    
                            slv0_val_i,
                            slv1_val_i,
                            slv2_val_i,
/*******************<formatter 接口>*********************/    
    input   wire            f2a_id_req_i,       //formatter请求接收
                            f2a_ack_i,
//Output
/*******************<slave 接口>*********************/    
    output  reg             a2s0_ack_o,         //[-slv]f2a_ack_i
                            a2s1_ack_o,
                            a2s2_ack_o,
/*******************<formatter 接口>*********************/
                            a2f_val_o,          //[-slv]slvx_val_i,包有效包络信号
    output  reg     [1:0]   a2f_id_o,           //通道编号
    output  reg     [31:0]  a2f_data_o,         //[-slv]slvx_data_i
    output  reg     [2:0]   a2f_pkglen_sel_o    //[-slv]slvx_pkglen_i
);
/*****************<中间信号>*********************/


/*****************<时序电路>*********************/
always @(posedge clk_i or negedge rstn_i) begin
    if(~rstn_i)begin//输出全部置0
        a2s0_ack_o<=0;
        a2s1_ack_o<=0;
        a2s2_ack_o<=0;
        a2f_val_o<=0;
        a2f_id_o<=0;
        a2f_data_o<=0;
    end
end
endmodule
