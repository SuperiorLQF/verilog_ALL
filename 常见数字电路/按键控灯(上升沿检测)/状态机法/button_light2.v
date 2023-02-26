//按键控灯练习，见https://blog.csdn.net/SuperiorEE/article/details/128880282
//波形变换法，使用moore机
module button_light2#(
    parameter   S1=3'b001,      //one-hot encode state
                S2=3'b010,
                S3=3'b100
)
(
    input       clk     ,
                button  ,
                rst_n   ,
                
    output  reg light
);
reg [2:0]   current_state   ,
            next_state      ;
reg         button_d1       ,
            button_d2        ;
/*同步器，用于同步输入，避免亚稳态*/
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        {button_d2,button_d1}<=2'b00;
    else
        {button_d2,button_d1}<={button_d1,button};
end
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
            next_state=(button_d2==0)?S1:S2;
        S2:
            next_state=(button_d2==0)?S1:S3;
        S3:
            next_state=(button_d2==0)?S1:S3;
        default: 
            next_state=S1;
    endcase
end
//第三段:输出电路（可以是组合或者时序，根据mealy或者moore确定，时序电路可以避免输出随输入变化的毛刺，但是会比mealy慢一个时钟）
always@(posedge clk,negedge rst_n)begin
    if(~rst_n)
        light<=0;
    else if(current_state==S2)
        light<=~light;
        
end
endmodule