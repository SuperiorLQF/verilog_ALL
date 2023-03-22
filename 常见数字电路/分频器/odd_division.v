module odd_division
#(
    parameter ODD_NUM=7
    )
(
    input clk_i,
    input rst_n,
    output clk_division
);

parameter BASE_NUM=(ODD_NUM-1)/2;
reg [9:0] pos_cnt;
reg [9:0] neg_cnt;

always@(posedge clk_i,negedge rst_n)begin
    if(~rst_n)
        pos_cnt<=0;
    else if(pos_cnt<ODD_NUM-1)
        pos_cnt<=pos_cnt+1;
    else
        pos_cnt<=0;
end

always@(negedge clk_i,negedge rst_n)begin
    if(~rst_n)
        neg_cnt<=0;
    else if(neg_cnt<ODD_NUM-1)
        neg_cnt<=neg_cnt+1;
    else
        neg_cnt<=0;
end

assign clk_division=((pos_cnt>BASE_NUM)||(neg_cnt>BASE_NUM));
endmodule