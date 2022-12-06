/***************<MCDF 整形器 formatter>*********************/
`timescale 1ns/100ps
/***************<端口声明>*********************/
module formatter
(
    input   wire            clk_i,
                            rstn_i,

    input   wire            a2f_val_i,
    input   wire    [1:0]   a2f_id_i,
    input   wire    [31:0]  a2f_data_i,
    input   wire    [2:0]   a2f_pkglen_sel_i,

    input   wire            fmt_grant_i,
    
    input   wire            a2f_end_i,//增加的信号，在arbiter中判断end更方便
    
    output  wire            f2a_ack_o,
    output  reg             fmt_id_req_o,

    output  wire    [1:0]   fmt_child_o,
    output  reg     [5:0]   fmt_length_o,
    output  wire            fmt_req_o,
    output  wire    [31:0]  fmt_data_o,
    output  reg             fmt_start_o,
    output  wire            fmt_end_o

);
/***************<中间信号>*********************/
reg fmt_end_d1;//end信号时延一个周期

/***************<时序电路>*********************/
// >>>fmt_end_d1用于产生fmt_id_req_o,并保证两次发送之间的时隙
//end信号时延一个周期
always @(posedge clk_i or negedge rstn_i) begin
    if(~rstn_i)
        fmt_end_d1<=0;
    else
        fmt_end_d1<=fmt_end_o;
end
// >>>fmt_id_req_o<<<
//1产生向下握手信号 fmt_id_req_o，等待优先通道不为11
always @(posedge clk_i or negedge rstn_i) begin
    if(~rstn_i)begin
        fmt_id_req_o<=1;//复位时没有发送占用，因此可以向下级握手
    end
    else if(fmt_end_d1)begin//因为end和start并不会重合，所以谁先谁后判断不影响
        fmt_id_req_o<=1;
    end
    else if(fmt_grant_i)begin
        fmt_id_req_o<=0;
    end
    else
        fmt_id_req_o<=fmt_id_req_o;
end
// >>> fmt_start_o
always @(posedge clk_i or negedge rstn_i) begin
    if(~rstn_i)
        fmt_start_o<=0;
    else if(fmt_grant_i)
        fmt_start_o<=1;
    else
        fmt_start_o<=0;
end
/***************<组合电路>*********************/
// >>>fmt_req_o<<<
//等待优先通道不为11，产生 fmt_req_o,表示下级就绪,当出现 fmt_grant_i 时再置低
//采用 波形变换 方式实现 优先通道不为11&fmt_id_req_o,参考时序参考图
assign  fmt_req_o=fmt_id_req_o & (a2f_id_i!=2'b11);
//波形变换，ack信号，在通道联通后，直送给slave
assign  f2a_ack_o=fmt_grant_i & fmt_req_o;
//一些直连信号
assign  fmt_end_o=a2f_end_i;//直连arbiter中的end信号（这个信号是另加的，因为arbiter中判断end更容易）
assign  fmt_data_o=a2f_data_i;
assign  fmt_child_o=a2f_id_i;
always @(*) begin//数据包长度译码（在slave_FIFO里面时用求幂实现）
    case(a2f_pkglen_sel_i) 
        3'b000:fmt_length_o<=6'd4;
        3'b001:fmt_length_o<=6'd8;
        3'b010:fmt_length_o<=6'd16;
        3'b011:fmt_length_o<=6'd32;
        default: 
            fmt_length_o<=6'd32;
    endcase
end

endmodule
