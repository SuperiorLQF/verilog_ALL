module pwm_breath
#(
    parameter   BRIGHT_division=1000,
    parameter   CLK_frequency=100_000_000//input clock freq
)
(
    input   clk_i,
    input   rst_n,
    output  [3:0] led_o
);
//******************<1us flag generator>********************************//
parameter   CLK_DIV_1u=CLK_frequency/1_000_000;//division coefficient
parameter   CNT_NUM_1u=CLK_DIV_1u-1;//cnt_1u upper limit
reg     [10:0]  cnt_1u;
wire    flag_1u;
always @(posedge clk_i or negedge rst_n) begin
    if(~rst_n)
        cnt_1u<=0;
    else 
        cnt_1u<=(cnt_1u<CNT_NUM_1u)?(cnt_1u+1):(0);
end
assign flag_1u=(cnt_1u==CNT_NUM_1u);
/////////////////////////////////////////


//******************<1us*BRIGHT_division flag generator>********************************//
parameter   CNT_NUM_1PWM=BRIGHT_division-1;//ONE PWM PAULSE period counter(CNT_NUM_1PWM*1us),counter upper limit stand for a pwm period
reg     [10:0]  cnt_1pwm;
wire    flag_1pwm;
always @(posedge clk_i or negedge rst_n) begin
    if(~rst_n)
        cnt_1pwm<=0;
    else if(flag_1u)
        cnt_1pwm<=(cnt_1pwm<CNT_NUM_1PWM)?(cnt_1pwm+1):(0);
    else
        cnt_1pwm<=cnt_1pwm;
end
assign flag_1pwm=(cnt_1pwm==CNT_NUM_1PWM)&(flag_1u);
//!!!note the flag_1pwm width is 1u rather than 1 clk_i
//!!!so we and it with signal flag_1u to slim it
//ensure every flag width is 1 clk_i period to avoid multiple trigger 
/////////////////////////////////////////


//******************<1us*BRIGHT_division**2 flag generator>********************************//
parameter   CNT_NUM_LED=BRIGHT_division-1;//the period counter that led truns from faint to shine(1us*CNT_NUM_1PWM**2)
reg     [10:0]  cnt_led;
wire    flag_led;
always @(posedge clk_i or negedge rst_n) begin
    if(~rst_n)
        cnt_led<=0;
    else if(flag_1pwm)
        cnt_led<=(cnt_led<CNT_NUM_LED)?(cnt_led+1):(0);
    else
        cnt_led<=cnt_led;
end
assign flag_led=(cnt_led==CNT_NUM_LED)&(flag_1pwm);//!!!note the flag_1pwm width is 1u rather than 1 clk_i
/////////////////////////////////////////

//******************<breath part:be bright then be faint>********************************//
reg breath;
always@(posedge clk_i or negedge rst_n)begin
    if(~rst_n)
        breath<=0;
    else if(flag_led)
        breath<=~breath;
end
/////////////////////////////////////////

//******************<pwm_output>********************************//
wire pwm_out;
assign pwm_out=breath?(cnt_led<=cnt_1pwm):(cnt_led>cnt_1pwm);
assign led_o={4{pwm_out}};
endmodule