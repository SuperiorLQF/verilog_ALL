//用于上板测试，使发送模块重复发送数据。
module transmitter_gen(
    input tx_clk,
    input rst_n,
    output  enable,
    output  [7:0]   data_generated
);
reg [4:0]  gen_counter;//发送的周期可以放大点
assign data_generated=8'h78;
assign enable=(gen_counter==5'b11111)?1:0;
always @(posedge tx_clk,negedge rst_n) begin
    if(~rst_n)
            gen_counter<=0;
    else
            gen_counter<=gen_counter+1; 
end
endmodule