/*参考刘清帆CSDN:【SOC架构】（一）同步与异步信号*/
/*快时钟域控制信号同步到慢时钟域*/
//方法2：停时钟法
module f2s_control(
    input       adat,
                rst,
                aclk,
                bclk,
    output  reg bdat
);
reg     adat1,
        bdat1,
        bdat2,
        bdat3,
        abdat1,
        abdat2,
        stall;
wire    aclk_gt;
//双向同步器
always @(posedge aclk or negedge rst) begin
    if(~rst)
        {abdat2,abdat1}<=2'b00;
    else
        {abdat2,abdat1}<={abdat1,bdat2};
end
always @(posedge bclk or negedge rst) begin
    if(~rst)
        {bdat2,bdat1}<=2'b00;
    else
        {bdat2,bdat1}<={bdat1,adat1};
end
//慢同步到快波形变化
always @(posedge bclk or negedge rst) begin
    if(~rst)
        bdat3<=2'b00;
    else
        bdat3<=bdat2;
end
always @(*) begin
        bdat<=({bdat3,bdat2}==2'b01)?1:0;
end
//反馈组合逻辑
assign aclk_gt=aclk & stall;
always@(*)begin
    if(abdat2==1)
        stall<=1'b1;//重启时钟
    else if(adat1==1)
        stall<=1'b0;//停时钟
    else
        stall<=1'b1;
end
always @(posedge aclk_gt or negedge rst) begin
    if(~rst)
        adat1<=1'b0;
    else
        adat1<=adat;
end

endmodule