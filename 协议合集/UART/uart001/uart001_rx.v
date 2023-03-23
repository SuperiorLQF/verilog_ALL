//米联自带uart_rx代码，用于学习
module uart001_rx(
input clk_i,
input uart_rx_i,
output [7:0] uart_rx_data_o,
output uart_rx_done
);
parameter [13:0] BAUD_DIV = 14'd10416;//波特率时钟，9600bps，100Mhz/9600 - 1'b1=10416
parameter [12:0] BAUD_DIV_CAP = (BAUD_DIV/8 - 1'b1);//8 次采样滤波去毛刺
reg [13:0] baud_div = 0; //波特率设置计数器
reg bps_start_en = 0; //波特率启动标志
always@(posedge clk_i)begin
    if(bps_start_en && baud_div < BAUD_DIV)
        baud_div <= baud_div + 1'b1;
    else
        baud_div <= 14'd0;
end
reg [12:0] samp_cnt = 0;
always@(posedge clk_i)begin
    if(bps_start_en && samp_cnt < BAUD_DIV_CAP)
        samp_cnt <= samp_cnt + 1'b1;
    else
        samp_cnt <= 13'd0;
end
//数据接收缓存器
reg [4:0] uart_rx_i_r=5'b11111;
always@(posedge clk_i)
    uart_rx_i_r<={uart_rx_i_r[3:0],uart_rx_i};
//数据接收缓存器，当连续接收到五个低电平时，即uart_rx_int=0 时，作为接收到起始信号
wire uart_rx_int=uart_rx_i_r[4] | uart_rx_i_r[3] | uart_rx_i_r[2] | uart_rx_i_r[1] | uart_rx_i_r[0];
parameter START = 4'd0;
parameter BIT0 = 4'd1;
parameter BIT1 = 4'd2;
parameter BIT2 = 4'd3;
parameter BIT3 = 4'd4;
parameter BIT4 = 4'd5;
parameter BIT5 = 4'd6;
parameter BIT6 = 4'd7;
parameter BIT7 = 4'd8;
parameter STOP = 4'd9;
reg [3:0] RX_S = 4'd0;
wire bps_en = (baud_div == BAUD_DIV);
wire rx_start_fail;
always@(posedge clk_i)begin
    if(!uart_rx_int&&bps_start_en==1'b0) begin
        bps_start_en <= 1'b1;
        RX_S <= START;
    end
    else if(rx_start_fail)begin
        bps_start_en <= 1'b0;
    end
    else if(bps_en)begin
    case(RX_S)
    START:RX_S <= BIT0; //RX bit0
    BIT0: RX_S <= BIT1; //RX bit1
    BIT1: RX_S <= BIT2; //RX bit2
    BIT2: RX_S <= BIT3; //RX bit3
    BIT3: RX_S <= BIT4; //RX bit4
    BIT4: RX_S <= BIT5; //RX bit5
    BIT5: RX_S <= BIT6; //RX bit6
    BIT6: RX_S <= BIT7; //RX bit7
    BIT7: RX_S <= STOP; //RX STOP
    STOP: bps_start_en <= 1'b0;
    default: RX_S <= STOP;
    endcase
    end
end
//滤波采样,在每个波特率周期采样，samp_en 一个周期内出现8 次，rx_tmp 初值，15 为中间值，如果采样为1 则增加，否则减少
reg [4:0] rx_tmp = 5'd15;
reg [4:0] cap_cnt = 4'd0;
wire samp_en = (samp_cnt == BAUD_DIV_CAP);//采样使能
always@(posedge clk_i)begin
    if(samp_en)begin
        cap_cnt <= cap_cnt + 1'b1;
        rx_tmp <= uart_rx_i_r[4] ? rx_tmp + 1'b1 : rx_tmp - 1'b1;
    end
    else if(bps_en) begin //每次波特率时钟使能，重新设置rx_tmp 初值为15
        rx_tmp <= 5'd15;
        cap_cnt <= 4'd0;
    end
end
//当采样7 次取值,大于16 为采样1，小于16 为采样0
reg cap_r = 1'b0;
wire cap_tmp = (cap_cnt == 3'd7);
reg ap_tmp_r = 1'b0;
reg ap_tmp_r1 = 1'b0;
wire cap_en = (!ap_tmp_r1&&ap_tmp_r);
reg cap_en_r = 1'b0;
always@(posedge clk_i)begin
    ap_tmp_r <= cap_tmp;
    ap_tmp_r1 <= ap_tmp_r;
    cap_en_r <= cap_en;
end
always@(posedge clk_i)begin
    if(cap_en&&bps_start_en)begin
        cap_r <= (rx_tmp > 5'd15) ? 1 : 0;
    end
    else if(!bps_start_en)begin
        cap_r <= 1'b1;
end
end
//以下状态机里面保存好数据
reg [7:0] rx = 8'd0;
reg start_bit = 1'b1;
always@(posedge clk_i)begin
    if(cap_en_r)begin
        case(RX_S)
            BIT0: rx[0] <= cap_r;
            BIT1: rx[1] <= cap_r;
            BIT2: rx[2] <= cap_r;
            BIT3: rx[3] <= cap_r;
            BIT4: rx[4] <= cap_r;
            BIT5: rx[5] <= cap_r;
            BIT6: rx[6] <= cap_r;
            BIT7: rx[7] <= cap_r;
        default: rx <= rx;
        endcase
    end
end
assign rx_start_fail = (RX_S == START)&&cap_en_r&&(cap_r == 1'b1);
assign uart_rx_done = (RX_S == STOP)&& cap_en;
assign uart_rx_data_o = rx;
endmodule