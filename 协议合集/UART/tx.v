//uart发射模块
//重点学习，带计数器的状态机写法
//这里模块内部没有对data_in进行缓存或者fifo处理，或许在enable后应当对数据进行锁存
//防止寄存器变化导致传输数据变化
module tx 
#(parameter data_width = 8,//数据宽度
parameter test = 2,//偶校验
parameter stop_width = 1)//结束符宽度1个高电平
(
input tx_clk,
input rst_n,
input [data_width-1:0] data_in,
input enable,
output reg tx_out);

localparam IDLE = 3'b000;
localparam S1 	 = 3'b001;
localparam S2	 = 3'b010;
localparam S3 	 = 3'b011;
localparam S4   = 3'b100;

reg [3:0] state, nstate;
reg [3:0] count_data;//输出数据位计数器
reg [1:0] count_stop;//结束符长度计数器
reg check_bit;

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
	IDLE: nstate = (enable ? S1 : IDLE);//注意enable的时序
	S1:		nstate =  S2 ;
	S2:		nstate = (test == 'b0 && count_data == (data_width - 1)? S4 : count_data == (data_width - 1)? S3 : S2); 
	S3:		nstate =  S4 ;
	S4:		nstate = count_stop == (stop_width - 1) ? IDLE : S4 ;//注意count_data和count_stop的时序
	default: nstate = IDLE;
	endcase
	end
	
//状态机的输出
always@(*)
	case(state)
		IDLE : tx_out = 1'b1;
		S1 : tx_out = 1'b0;
		S2 : tx_out = data_in[count_data]; //由低位到高位依次输出
		S3 : tx_out = check_bit;
		S4 : tx_out = 1'b1;
	default : tx_out = 1'b1;
	endcase

//S2状态，输出数据位的计数器
always@(posedge tx_clk or negedge rst_n)
	if(!rst_n)
		count_data <= 4'b0000;
	else if (count_data < data_width && state == S2)
		count_data <= count_data + 1'b1;
	else 
		count_data <= 4'b0000;

//UART的奇偶校验位的生成
always@(posedge tx_clk or negedge rst_n)
	begin
	if(!rst_n)	
		check_bit <= 1'b0;
	else if (state == S2)
		case(test)
		2'b00 : check_bit <= 1'b0;
		2'b01 : check_bit <= !(^data_in);
		2'b10 : check_bit <= (^data_in);
		default:check_bit <= 1'b0;
		endcase
	else check_bit <= check_bit;
	end

//UART停止位计数器
always@(posedge tx_clk or negedge rst_n)
	begin
		if(!rst_n)
			count_stop <= 2'b00;
		else if( state == S4 && count_stop <stop_width)
			count_stop <= count_stop + 1'b1;
		else 
			count_stop <= 2'b00;
	end

endmodule
