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
                            
    input   wire            slv0_end_i,           //!!!增加的信号
    input   wire            slv1_end_i,           //!!!增加的信号
    input   wire            slv2_end_i,           //!!!增加的信号
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
    output  reg     [2:0]   a2f_pkglen_sel_o,    //[-slv]slvx_pkglen_i

    output  reg             a2f_end_o           //!!!增加的信号
);
/*****************<中间信号>*********************/
wire    [3:0]   ch0_prio_syn,//各通道综合优先级，计算方法见下
                ch1_prio_syn,
                ch2_prio_syn;
reg     [5:0]   channel_prio;//通道优先级综合排序寄存器[5:4最高优先级通道序号][3：2次高优先级通道序号][1：0最低优先级通道序号]
wire    [2:0]   slvx_req;//输入请求集中,!!!写成向量比数组更好，向量可以查看值，防止出错
assign  slvx_req[0]=slv0_req_i;
assign  slvx_req[1]=slv1_req_i;
assign  slvx_req[2]=slv2_req_i;
/*****************<综合优先级生成电路：组合逻辑>*********************/
assign ch0_prio_syn=({2'b0,slv0_prio_i}<<2)+'d0;//[3:2是设置prio][1：0是自有prio，3：2相等时才起作用]
assign ch1_prio_syn=({2'b0,slv1_prio_i}<<2)+'d1;
assign ch2_prio_syn=({2'b0,slv2_prio_i}<<2)+'d2;
/*****************<优先级整合逻辑>*********************/
//根据综合优先级得出最优先通道（数值最小）
always @(*) begin//综合优先级生成电路保证不可能相等
    if(ch0_prio_syn>ch1_prio_syn)begin
        if(ch1_prio_syn>ch2_prio_syn)
            channel_prio<=6'b10_01_00;
        else begin
            if(ch0_prio_syn>ch2_prio_syn)
                channel_prio<=6'b01_10_00;
            else
                channel_prio<=6'b01_00_10;
        end
    end
    else begin
        if(ch1_prio_syn<ch2_prio_syn)
            channel_prio<=6'b00_01_10;
        else begin
            if(ch0_prio_syn<ch2_prio_syn)
                channel_prio<=6'b00_10_01;
            else
                channel_prio<=6'b10_00_01;
        end        
    end
end
/*****************<时序电路>*********************/
//用于产生仲裁信号 a2f_id_o !!!如果都没准备号，就发送11
always @(posedge clk_i or negedge rstn_i) begin
    if(~rstn_i)begin//输出全部置0
        a2f_id_o<=2'b11;//进入default间接置0
    end
    else if(f2a_id_req_i)begin//当上级(formatter)命令可以发送包!!!f2a_id_req_i应当时单周期信号，不能持续
        if(slvx_req[channel_prio[5:4]])//先查看优先级最高的slave是否请求发送
            a2f_id_o<=channel_prio[5:4];
        else if(slvx_req[channel_prio[3:2]])
            a2f_id_o<=channel_prio[3:2];
        else if(slvx_req[channel_prio[1:0]])
            a2f_id_o<=channel_prio[1:0];
        else
            a2f_id_o<=2'b11;
    end
    else
        a2f_id_o<=a2f_id_o;
end

/*****************<多路选择器部分>*********************/
always @(*) begin
    case(a2f_id_o)
    2'b00:begin
        a2f_val_o=slv0_val_i;
        a2f_data_o=slv0_data_i;  
        a2f_pkglen_sel_o=slv0_pkglen_i;
        
        a2s0_ack_o=f2a_ack_i;
        a2s1_ack_o=0;
        a2s2_ack_o=0;

        a2f_end_o=slv0_end_i;
    end

    2'b01:begin
        a2f_val_o=slv1_val_i;
        a2f_data_o=slv1_data_i; 
        a2f_pkglen_sel_o=slv1_pkglen_i; 
        
        a2s0_ack_o=0;
        a2s1_ack_o=f2a_ack_i;
        a2s2_ack_o=0;

        a2f_end_o=slv1_end_i;
    end

    2'b10:begin
        a2f_val_o=slv2_val_i;
        a2f_data_o=slv2_data_i; 
        a2f_pkglen_sel_o=slv2_pkglen_i;
        
        a2s0_ack_o=0;
        a2s1_ack_o=0;
        a2s2_ack_o=f2a_ack_i;

        a2f_end_o=slv2_end_i;
    end

    2'b11:begin//default
        a2f_val_o=0;
        a2f_data_o=0; 
        a2f_pkglen_sel_o=0;
        
        a2s0_ack_o=0;
        a2s1_ack_o=0;
        a2s2_ack_o=0;

        a2f_end_o=0;
    end
    endcase
end
endmodule
