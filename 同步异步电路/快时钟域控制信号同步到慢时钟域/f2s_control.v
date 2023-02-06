/*参考刘清帆CSDN:【SOC架构】（一）同步与异步信号*/
/*快时钟域控制信号同步到慢时钟域*/
module f2s_control(
    input       adat,
                rst,
                aclk,
                bclk,
    output  reg bdat
);
reg     adat1,
        bdat1,  bdat2,  bdat3,
        abdat1, abdat2;
//实例化慢时钟域同步器
always @(posedge bclk or negedge rst) begin
    if(~rst)
        {bdat2,bdat1}<=2'b00;
    else
        {bdat2,bdat1}<={bdat1,adat1};
end
//实例化快时钟域同步器
always @(posedge aclk or negedge rst) begin
    if(~rst)
        {abdat2,abdat1}<=2'b00;
    else
        {abdat2,abdat1}<={abdat1,bdat2};
end
//实例化快时钟域同步慢时钟域方法:缩短
always @(posedge bclk or negedge rst) begin
    if(~rst)
        bdat3<=1'b0;
    else
        bdat3<=bdat2;
end
always @(bdat3,bdat2) begin
    bdat<=({bdat3,bdat2}==2'b01)?1'b1:1'b0;
end

//实例化慢时钟域同步快时钟域方法：反馈延时
always @(posedge aclk or negedge rst) begin
    if(~rst)
        adat1<=1'b0;
    else    //adat触发，abdat2关闭
        if(abdat2)
            adat1<=1'b0;
        else
            if(adat)
                adat1<=1'b1;
end
endmodule