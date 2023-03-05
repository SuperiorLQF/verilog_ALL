//!!!有问题：没有接受校验位，没有判断
module rx #(
parameter data_width = 8,
parameter test = 2,
parameter stop_width = 1)
(input rx_clk,
input rst_n,
input data_in,
output [data_width-1:0]rx_out,
output fail);

//状态机定义
localparam IDLE = 3'b000;
localparam S1 	= 3'b001;
localparam S2	  = 3'b010;
localparam S3 	= 3'b011;
localparam S4   = 3'b100;

reg [2:0] state, nstate;

//
reg [3:0] frq_6;//16倍采样计数器
reg data_in_reg;
reg [15:0] filter_reg;
reg filter_out;

reg [data_width-1:0] rx_out_reg;
reg test_reg;


wire start;


reg [3:0] count_data;
reg [1:0] count_stop;

//三段式状态机的第一段
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nstate;

//三段式状态机的第二段
always@(*)
	begin
	case(state)
		IDLE: nstate = (start ? S1 : IDLE);
		S1:		nstate = (frq_6 == 4'b1111 ? S2 : S1);

		S2:		nstate = (test == 'b0 && frq_6 == 4'b1111 && count_data == data_width - 1) ? 
      S4 : (frq_6 == 4'b1111 && count_data == data_width - 1)? 
      S3 : S2 ;

		S3:		nstate = (frq_6 == 4'b1111 ? S4 : S3);
		S4:		nstate = (frq_6 == 4'b1111 && (count_stop == stop_width - 1)? IDLE : S4);
	default:nstate = IDLE;
	endcase
	end

//下降沿检测电路，输出start信号，激活UART接收，以离开IDLE状态
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n)
		data_in_reg <= 1'b0;
	else
		data_in_reg <= data_in;

assign start = data_in_reg & !data_in;

//数据接收个数的计数器
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n || state !== S2) 
		count_data <= 4'b0000;
	else if (count_data == data_width - 1 && frq_6 ==4'b1111)//这句可不可以不要？
		count_data <= 4'b0000;
	else if (frq_6 == 4'b1111)
		count_data <= count_data + 1'b1;
	else
		count_data <= count_data;


//停止位接受个数的计数器
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n || state !== S4) 
		count_stop <= 2'b00;
	else if (count_stop == stop_width - 1 && frq_6 ==4'b1111)
		count_stop <= 2'b00;
	else if(frq_6 == 4'b1111)
		count_stop <= count_stop + 1'b1;
	else 
		count_stop <= count_stop;	
		

//???16倍的采样计数器
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n)
		frq_6 <= 4'b0000;
	else if(frq_6 == 4'b1111 && state == IDLE)
		frq_6 <= 4'b0000;
	else if(state == S1 || state == S2 || state == S3 || state == S4)
		frq_6 <= frq_6 + 1'b1;
	else 
		frq_6 <= frq_6;

//16倍频的采样结果存储在filter_reg中
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n)
		filter_reg <= 16'h0000;
	else if(state == S1 || state == S2 || state == S3 || state == S4)
		filter_reg[frq_6] <= data_in;
	else
		filter_reg <= 16'h0000;

//存储后的多路选择,结果输出位filter_out,filter——out是啥，跟结果检测有啥关系，而且为什么要这么filter？	
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n || state == IDLE)
		filter_out <= 1'b0;
	else if ( frq_6 == 4'b1100)
		filter_out <= (filter_reg[7] & filter_reg[8]) ^ (filter_reg[7] & filter_reg[9]) ^ (filter_reg[8] & filter_reg[9]);
	else
		filter_out <= filter_out;

//S2状态时将数据依次存入寄存器
always@(posedge rx_clk or negedge rst_n)
			if(!rst_n || state == IDLE)
				rx_out_reg <= 'b0;
			else if (state == S2 && frq_6 == 4'b1111)
				rx_out_reg[count_data] <= filter_out;
			else 
				rx_out_reg <= rx_out_reg;

//S3状态时判断校验位是否正确
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n)
		test_reg <= 1'b0;
	else if(state == S3)
		case(test)
			2'b00 : test_reg <= 1'b0;
			2'b01 : test_reg <= !(^rx_out_reg);
			2'b10 : test_reg <= (^rx_out_reg);
			default : test_reg <= 1'b0;
		endcase
	else
			test_reg <= 1'b0;

assign fail = (state == S3 && frq_6 == 4'b1110 && filter_out !== test_reg) ? 1 : 0;


//数据接受完毕，输出传入RX的值
assign rx_out =(state == S4 && count_stop == stop_width - 1) ? rx_out_reg : 'b0 ;

endmodule
