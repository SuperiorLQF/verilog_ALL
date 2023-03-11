//uart接收器
//16倍频采样，采取中间3个多数结果
//???接受数据时是否需要打2拍避免亚稳态
module receiver #(
parameter data_width = 8)
(
    input rx_clk,
    input rst_n,
    input data_in,
    output [data_width-1:0]rx_out
);

//状态机定义
localparam IDLE 	= 3'b000;
localparam START 	= 3'b001;//发送低电平
localparam DATA	 	= 3'b010;
localparam CRC 	 	= 3'b011;//校验,但暂时不用
localparam FINISH   = 3'b100;

reg [2:0] state, nstate;

//
reg [3:0] frq_16;       //16倍采样计数器
reg data_in_reg;
reg [15:0] filter_reg;  //16倍频采样数据寄存器
reg filter_out;         //16倍采样结果

reg [data_width-1:0] rx_out_reg;
reg test_reg;



wire start_flag;


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
		IDLE:       nstate = (start_flag ? START : IDLE);//根据接收到下降沿进入工作状态
		START:		nstate = (frq_16 == 4'b1111 ? DATA : START);
		DATA:		nstate = (frq_16 == 4'b1111 && count_data == data_width - 1) ? FINISH : DATA ;
		//本例不用的状态
        CRC:		nstate = (frq_16 == 4'b1111 ? FINISH : CRC);
		
        FINISH:		nstate = (frq_16 == 4'b1111 ? IDLE : FINISH);
	default:nstate = IDLE;
	endcase
	end

//下降沿检测电路，输出start信号，激活UART接收，以离开IDLE状态
//************************************************************
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n)
		data_in_reg <= 1'b0;
	else
		data_in_reg <= data_in;

assign start_flag = data_in_reg & !data_in;//下降沿检测器
//**************************************************************



//数据位数8计数器
//**************************************************************
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n || state != DATA)//清零或离开数据状态归零 
		count_data <= 4'b0000;
	else if (frq_16 == 4'b1111)//在数据状态内根据16倍采样器进1
		count_data <= count_data + 1'b1;
	else                        //16倍采样器未满时保持不变
		count_data <= count_data;
//**************************************************************		



//16倍的采样计数器，离开了IDLE才开始计数
//********************************************************************
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n)
		frq_16 <= 4'b0000;
	else if(frq_16 == 4'b1111 || state == IDLE)//IDLE态为0，满15归0
		frq_16 <= 4'b0000;
	else 
		frq_16 <= frq_16 + 1'b1;
//********************************************************************


//16倍频的采样结果存储在filter_reg中
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n)
		filter_reg <= 16'h0000;
	else if(state == START || state == DATA || state == CRC || state == FINISH)//工作状态都16倍频采样
		filter_reg[frq_16] <= data_in;//目前仅使用DATA16倍采样数据
	else
		filter_reg <= 16'h0000;

//存储后的多路选择,结果输出位filter_out
//12拍时取中间时刻的多数表决结果作为当拍最终结果
//********************************************************************
always@(posedge rx_clk or negedge rst_n)
	if(!rst_n || state == IDLE)
		filter_out <= 1'b0;
	else if ( frq_16 == 4'b1100)
		filter_out <= (filter_reg[7] & filter_reg[8]) ^ (filter_reg[7] & filter_reg[9]) ^ (filter_reg[8] & filter_reg[9]);
	else
		filter_out <= filter_out;
//********************************************************************



//DATA状态时将数据依次存入寄存器rx_out_reg
//********************************************************************
always@(posedge rx_clk or negedge rst_n)
			if(!rst_n || state == IDLE)
				rx_out_reg <= 'b0;
			else if (state == DATA && frq_16 == 4'b1111)
				rx_out_reg[count_data] <= filter_out;
			else 
				rx_out_reg <= rx_out_reg;
//********************************************************************


//在finish状态，将rx_out_reg作为rx_out的有效数据
//********************************************************************
assign rx_out =(state == FINISH) ? rx_out_reg : 'b0 ;
//********************************************************************

endmodule
