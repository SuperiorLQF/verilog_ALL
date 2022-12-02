/*************************<MCDF控制寄存器>*********************/
//存储器仅在时钟周期完成读或写，并不完成同时读写
`timescale 1ns/100ps
/*************************<端口声明>*********************/
module control_register
#(
    parameter   CTRL_REG_DEFAULT='b111,
                STATE_REG_DEFAULT='d64 //FIFO深度
              
)
(
    input                   clk_i,
                            rstn_i,
    input   wire    [1:0]   cmd_i ,
    input   wire    [5:0]   cmd_addr_i,
    input   wire    [31:0]  cmd_data_i,    
    input   wire    [5:0]   slv0_margin_i,
                            slv1_margin_i,
                            slv2_margin_i,


    output                  slv0_en_o,
                            slv1_en_o,
                            slv2_en_o,    
    output  reg     [31:0]  cmd_data_o,
    output  wire    [1:0]   slv0_prio_o,
                            slv1_prio_o,
                            slv2_prio_o,
    output  wire    [2:0]   slv0_pkglen_o,
                            slv1_pkglen_o,
                            slv2_pkglen_o
);
/*************************<中间信号>*********************/
reg     [31:0]   Register    [5:0];//6个寄存器构成的存储单元
integer i;
/*************************<时序电路>*********************/
always @(posedge clk_i or negedge rstn_i) begin
    if(!rstn_i)begin//给寄存器赋复位值
        for(i=0;i<3;i=i+1)begin
            Register[i]<=CTRL_REG_DEFAULT;
        end
        for(i=4;i<6;i=i+1)begin
            Register[i]<=STATE_REG_DEFAULT;
        end
    end
    else begin
        case (cmd_i)
        //!!!这里没有加入状态寄存器不能写的约束，所有寄存器均可读写，并且读取的通道余量是延迟一个时钟的
            01:Register[cmd_addr_i>>4]<=cmd_data_i;//RD
            10:cmd_data_o<=Register[cmd_addr_i>>4];//WR
            default: //IDLE
                ;//不做任何操作但是要加上，防止综合出锁存器
        endcase
        //锁存更新通道余量
        Register[0][5:3]<=slv0_margin_i;
        Register[1][5:3]<=slv1_margin_i;
        Register[2][5:3]<=slv2_margin_i;        
    end
end
/*************************<组合逻辑电路>*********************/
//通道使能信号
assign slv0_en_o=Register[0][0];
assign slv1_en_o=Register[1][0];
assign slv2_en_o=Register[2][0];
//通道优先级
assign slv0_prio_o=Register[0][2:1];
assign slv1_prio_o=Register[1][2:1];
assign slv2_prio_o=Register[2][2:1];
//数据包长度
assign slv0_pkglen_o=Register[0][5:3];
assign slv1_pkglen_o=Register[1][5:3];
assign slv2_pkglen_o=Register[2][5:3];
endmodule