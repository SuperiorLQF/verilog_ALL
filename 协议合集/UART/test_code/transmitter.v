//uart发射模块
/****
简化为8位传输，1位结束符，无校验位
*****/
//重点学习，带计数器的状态机写法
module transmitter
#(parameter data_width = 8//数据宽度8位
    )
(
input tx_clk,
input rst_n,
input [data_width-1:0] data_in,
input enable,//输入使能位
output reg tx_out);

localparam IDLE 	= 3'b000;
localparam START 	= 3'b001;//发送低电平
localparam DATA	 	= 3'b010;
localparam CRC 	 	= 3'b011;//校验,但暂时不用
localparam FINISH   = 3'b100;

reg [3:0] state, nstate;
reg [3:0] count_data;//输出数据位计数器

//状态机第一段
always@(posedge tx_clk or negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nstate;

//状态机第二段
always@(*)
	begin
	case(state)
		IDLE: 		nstate = (enable ? START : IDLE);//注意enable的时序
		START:		nstate =  DATA ;
		DATA:		nstate = (count_data == (data_width - 1)? FINISH : DATA); 
		CRC:		nstate =  FINISH ;//正常情况进不来CRC的
		FINISH:		nstate =  IDLE;//注意count_data和count_stop的时序
	default: nstate = IDLE;
	endcase
	end
	
//状态机的输出
always@(*)
	case(state)
		IDLE : tx_out = 1'b1;
		START : tx_out = 1'b0;
		DATA : tx_out = data_in[count_data]; //由低位到高位依次输出
		CRC : tx_out = 1'b0;
		FINISH : tx_out = 1'b1;
	default : tx_out = 1'b1;
	endcase

//DATA状态，输出数据位的计数器
always@(posedge tx_clk or negedge rst_n)
	if(!rst_n)
		count_data <= 4'b0000;
	else if (count_data < data_width && state == DATA)
		count_data <= count_data + 1'b1;
	else 
		count_data <= 4'b0000;


endmodule
