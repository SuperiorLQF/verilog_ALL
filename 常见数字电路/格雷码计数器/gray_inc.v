//2023年2月20日19:14:55
//格雷码计数器，由二进制计时器和二进制转换格雷码组成
//解析见刘清帆 CSDN
module gray_inc
#(
    parameter SIZE=4,   //位宽
    parameter INC=1     //增量
)
(
    input   wire    clk,
                    rst_n,
    output  reg     [SIZE-1:0]  gray
);
            reg     [SIZE-1:0]  bin;
always @(posedge clk or negedge rst_n) begin//二进制计数器
    if(~rst_n)  
        bin<=0;
    else
        bin<=bin+INC;
end
always @(*) begin
    gray<=(bin>>1)^bin;   
end


endmodule