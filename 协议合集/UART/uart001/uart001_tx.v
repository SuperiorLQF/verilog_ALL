module uart001_tx(
input clk_i,
input [7:0] uart_tx_data_i, //待发送数据
input uart_tx_en_i, //发送发送使能信号
output uart_tx_o,
output uart_busy
);
reg uart_tx_o = 1'b1;
parameter [12:0] BAUD_DIV = 14'd5207;//波特率时钟，9600bps，50Mhz/9600 - 1'b1=5207
//波特率发生器，实际就是分配器
reg bps_start_en = 1'b0;
reg [12:0] baud_div = 13'd0;
assign uart_busy = bps_start_en;
always@(posedge clk_i)begin
if(bps_start_en && baud_div < BAUD_DIV)
baud_div <= baud_div + 1'b1;
else
baud_div <= 13'd0;
end
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
reg [7:0] uart_tx_data_r = 8'd0;
reg [3:0] TX_S = STOP;
wire bps_en = (baud_div == BAUD_DIV);
always@(posedge clk_i)begin
    //首先当发送使能有效，寄存数据
if(uart_tx_en_i) begin
bps_start_en <= 1'b1;
uart_tx_data_r[7:0] <= uart_tx_data_i;
TX_S <= START;
end
else if(!bps_start_en)begin//当bps_start_en 为0 让状态机处于停止状态
TX_S <= STOP;
end
//发送状态机，每个波特率发送一个状态机
if(bps_en)begin
case(TX_S)
START:TX_S <= BIT0;//bit 0
BIT0: TX_S <= BIT1;//bit 1
BIT1: TX_S <= BIT2;//bit 2
BIT2: TX_S <= BIT3;//bit 3
BIT3: TX_S <= BIT4;//bit 4
BIT4: TX_S <= BIT5;//bit 5
BIT5: TX_S <= BIT6;//bit 6
BIT6: TX_S <= BIT7;//bit 7
BIT7: TX_S <= STOP;//bit STOP
STOP: bps_start_en <= 1'b0;//end
default: TX_S <= STOP;
endcase
end
end
always@(*)begin
case(TX_S)
START:uart_tx_o <= 1'b0;
BIT0: uart_tx_o <= uart_tx_data_r[0];
BIT1: uart_tx_o <= uart_tx_data_r[1];
BIT2: uart_tx_o <= uart_tx_data_r[2];
BIT3: uart_tx_o <= uart_tx_data_r[3];
BIT4: uart_tx_o <= uart_tx_data_r[4];
BIT5: uart_tx_o <= uart_tx_data_r[5];
BIT6: uart_tx_o <= uart_tx_data_r[6];
BIT7: uart_tx_o <= uart_tx_data_r[7];
STOP: uart_tx_o <= 1'b1;
default: uart_tx_o <= 1'b1;
endcase
end
endmodule