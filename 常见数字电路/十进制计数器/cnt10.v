//计数溢出后自动复位的十进制计数器
module cnt10(
    input               clk ,
    input               clr ,   //清零信号
    input               en  ,   //计数使能
    output              c   ,   //溢出标志
    output  reg[3:0]    out     //计数输出
);
always @(posedge clk,negedge clr) begin
    if(~clr)
        out<=4'b0;
    else if(en)
        if(out>=4'd9)
            out<=4'b0;//如果不自动复位，out<=4'd9
        else
            out<=out+1;
    else
        out<=out;    
end
assign c=out[3] & out[0];
endmodule