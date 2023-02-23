/*参考刘清帆CSDN:【SOC架构】（一）同步与异步信号*/
/*快时钟域控制信号同步到慢时钟域*/
/*测试*/
`timescale 1ns/1ns
`include "f2s_control.v"
module f2s_control_tb;
//************<端口声明>****************
reg         adat,
            rst,
            aclk,
            bclk;
wire        bdat;
//***********<模块例化>******************
f2s_control M1(
    adat,
    rst,
    aclk,
    bclk,
    bdat
);
initial begin
    $dumpfile("f2s_control.vcd");
    $dumpvars;
    aclk<=0;
    bclk<=0;
    rst<=0;
    adat<=0;
    #12 rst<=1;
    #20 @(posedge aclk)  adat<=1;
    @(posedge aclk)  adat<=0;
    #1000   $finish;
end
always #7 
    aclk<=~aclk;
always #10 
    bclk<=~bclk;
endmodule