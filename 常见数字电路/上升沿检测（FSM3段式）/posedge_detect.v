//FPGA第一次作业T1，20230223
//!!!思考和整形法的上升沿检测略有不同，但是否可以先通过D触发器同步，然后使用整形法？
module posedge_detect#(
    parameter   S1=3'b001,      //one-hot encode state
                S2=3'b010,
                S3=3'b100
)
(
    input       rst_n   ,
                clk     ,
                i_pulse ,
                
    output  reg o_pulse
);
reg [2:0]   current_state   ,
            next_state      ;
//第一段：现态次态切换
always @(posedge clk,negedge rst_n) begin
    if(~rst_n)
        current_state<=S1;          //状态复位
    else
        current_state<=next_state;  //状态转换
end
//第二段:次态组合逻辑
always@(*)begin
    case (current_state)
        S1:
            next_state=(i_pulse==0)?S1:S2;
        S2:
            next_state=(i_pulse==0)?S1:S3;
        S3:
            next_state=(i_pulse==0)?S1:S3;
        default: 
            next_state=S1;
    endcase
end
//第三段:输出电路（可以是组合或者时序，根据mealy或者moore确定，时序电路可以避免输出随输入变化的毛刺，但是会比mealy慢一个时钟）
always@(*)begin
    o_pulse=(current_state==S2);
end
endmodule