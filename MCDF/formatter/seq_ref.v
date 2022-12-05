/********<MCDF重要信号时序参考:sequence_reference>*********/
`timescale 1ns/100ps
module seq_ref;
reg             clk_i;
reg             rst_n;
reg             fmt_grant;
wire            a2sx_ack,
                f2a_ack;//这三个信号为同一个信号，持续至少一个时钟周期，在开始发送后可以降低
assign  f2a_ack=fmt_grant;
assign  a2sx_ack=fmt_grant;

reg             fmt_id_req;//formatter空闲时为高
reg     [1:0]   a2f_id;//就绪通道信号
reg     [31:0]  fmt_data;//送出数据
reg             fmt_strat,
                fmt_req,
                fmt_end;//!!!end的产生可能与i息息相关         
initial begin
        clk_i<=0;
        rst_n<=0;
        fmt_grant<=0;
        fmt_id_req<=0;//
        a2f_id<=2'b11;//
        fmt_data<=0;
        fmt_strat<=0;
        fmt_end<=0;
        fmt_req<=0;   
        $dumpfile("seq_ref.vcd");
        $dumpvars;
#15     rst_n<=1;
@(posedge clk_i)    fmt_id_req<=1;
#40//等待下级就绪
@(posedge clk_i)    begin
    a2f_id<=2'b10;
    fmt_req<=1'b1;//表示就绪，等待grant
end
#30
@(posedge clk_i)    fmt_grant<=1;
@(posedge clk_i)    begin
    fmt_req<=0;
    fmt_data<=$random;
    fmt_strat<=1;   
end
@(posedge clk_i)begin
                    fmt_grant<=0;
                    fmt_data<=$random;
                    fmt_strat<=0;
                    fmt_id_req<=0; 
end
@(posedge clk_i)begin
                    fmt_strat<=0;
                    fmt_data<=$random;
end

@(posedge clk_i)begin
    fmt_end<=1;
    fmt_data<=$random;
end
@(posedge clk_i)begin
    fmt_end<=0;
    fmt_data<=$random;
end

#500    $finish;
end
always #10 clk_i=~clk_i;
endmodule