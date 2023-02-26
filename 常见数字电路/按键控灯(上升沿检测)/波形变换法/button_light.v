//按键控灯练习，见https://blog.csdn.net/SuperiorEE/article/details/128880282
//波形变换法
module button_light
(
    input       clk     ,
                button  ,   //i_pulse
                rst_n   ,
    output  reg light       //o_pulse
);
reg     button_d1   ,
        button_d2   ,
        button_d3   ;           //button_d3用于波形变换
wire    pulse       ;
/*同步器，用于同步输入，避免亚稳态*/
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        {button_d3,button_d2,button_d1}<=3'b00;
    else
        {button_d3,button_d2,button_d1}<={button_d2,button_d1,button};
end

/*波形变换法实现上升沿检测*/
assign pulse=(~button_d3)&(button_d2);

//light根据pulse翻转逻辑
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        light<=0;
    else
        if(pulse)
            light<=~light;
end 
endmodule