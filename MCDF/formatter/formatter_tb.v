`timescale 1ns/100ps
`include "formatter.v"
/*************************<端口声明>*********************/
module formatter_tb;
reg             clk_i;
reg             rstn_i;
reg             a2f_val_i;
reg     [1:0]   a2f_id_i;
reg     [31:0]  a2f_data_i;
reg     [2:0]   a2f_pkglen_sel_i;
reg             fmt_grant_i;
reg             a2f_end_i;          //增加的

wire            f2a_ack_o;
wire            fmt_id_req_o;
wire    [1:0]   fmt_child_o;
wire    [5:0]   fmt_length_o;
wire            fmt_req_o;
wire    [31:0]  fmt_data_o;
wire            fmt_start_o;
wire            fmt_end_o;
/*************************<实例化>*********************/
formatter fm1(
    clk_i,
    rstn_i,
    a2f_val_i,
    a2f_id_i,
    a2f_data_i,
    a2f_pkglen_sel_i,
    fmt_grant_i,
    a2f_end_i,       
    
    f2a_ack_o,
    fmt_id_req_o,
    fmt_child_o,
    fmt_length_o,
    fmt_req_o,
    fmt_data_o,
    fmt_start_o,
    fmt_end_o
);
/*************************<信号产生>*********************/
initial begin
        clk_i<=0;
        rstn_i<=0;

        a2f_val_i<=0;           //这个信号没用到
        
        a2f_id_i<=2'b11;         //接通的通道
        a2f_data_i<=$random;    //接通通道的数据
        a2f_pkglen_sel_i<=0;    //与a2f_id_i同步变化
        fmt_grant_i<=0;
        a2f_end_i<=0;  
        $dumpfile("formatter.vcd");
        $dumpvars;
#15     rstn_i<=1;
#40 
@(posedge clk_i)    a2f_id_i<=2'b00;
#30
@(posedge clk_i)    fmt_grant_i<=1;
@(posedge clk_i)    fmt_grant_i<=1;
@(posedge clk_i)    fmt_grant_i<=0;
@(posedge clk_i)    fmt_grant_i<=0;
@(posedge clk_i)    a2f_end_i<=1;
@(posedge clk_i)    a2f_end_i<=0;
#500    $finish;
end
always @(posedge clk_i) begin
    a2f_data_i<=$random;
end
always #10 clk_i<=~clk_i;
always @(*) begin//模拟arbiter中的信号同步
    case(a2f_id_i)
        2'b00:a2f_pkglen_sel_i<=3'b000;
        2'b01:a2f_pkglen_sel_i<=3'b001;
        2'b10:a2f_pkglen_sel_i<=3'b010;
        2'b11:a2f_pkglen_sel_i<=3'b000;
    endcase
end
endmodule