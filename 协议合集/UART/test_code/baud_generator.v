//波特率生成器
//`include "uart_head.v"
module baud_generator #(
	parameter clk_rate = 100_000_000, //全局时钟频率100M
	parameter baud_rate = 9_600 //波特率
)(
	input clk_p,
	input clk_n,
	input rst_n,
	output rx_clk,
	output tx_clk);
	//localparam作用域和parameter一样，但是不能重定义
	localparam tx_rate = clk_rate / (baud_rate * 2); //发送模块分频系数
	localparam rx_rate = clk_rate / (baud_rate * 2 * 16); //接收模块分频系数，16倍采样分频
	
	//***设置最节约的计数寄存器的方法----------------------------------------------------
	/*$clog2是向上取整，例如rx_rate只要介于[513,1024]，结果都是10，位宽就是[9:0],表示0-1023的值
	由于1024比1023大，因此还要进行-1调整-------------------------------------------------*/
	wire clk;
	IBUFGDS clk_inst (
    .O(clk),
    .I(clk_p),
    .IB(clk_n)
    );
	reg [$clog2(rx_rate)-1:0] rx_count; 
	reg [$clog2(tx_rate)-1:0] tx_count;
	reg rx_clk_reg;
	reg tx_clk_reg;

// rx_clk分频
always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			rx_count <= 'b0;
			rx_clk_reg <= 1'b0;
		end
		else if(rx_count == rx_rate - 1'b1)
		begin
			rx_clk_reg <= !rx_clk_reg;
			rx_count <= 'b0;
		end
		else
			rx_count = rx_count + 1'b1;
	end
//tx_clk分频
always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			tx_count <= 'b0;
			tx_clk_reg <= 1'b0;
		end
		else if(tx_count == tx_rate - 1'b1)
		begin
			tx_clk_reg = !tx_clk_reg;
			tx_count <= 'b0;
		end
		else
			tx_count= tx_count +1'b1;
	end

assign rx_clk = rx_clk_reg;
assign tx_clk = tx_clk_reg;

endmodule
