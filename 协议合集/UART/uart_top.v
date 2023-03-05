module uart_top#(
parameter time_frequency = 100_000_000,
parameter baud_rate = 9_600,
parameter data_width = 8,
parameter test = 1,
parameter stop_width = 2
)(
input clk,
input rst_n,
input enable,
input [data_width-1:0] data_in,
output [data_width-1:0] rx_out);

wire rx_clk;
wire tx_clk;
wire tx_out;

baud_generator #(time_frequency,baud_rate)   u1 (.clk(clk),.rst_n(rst_n),.rx_clk(rx_clk),.tx_clk(tx_clk));

tx 			#(data_width,test,stop_width) u2(.tx_clk(tx_clk),.rst_n(rst_n),.data_in(data_in),.enable(enable),.tx_out(tx_out));

rx 			#(data_width,test,stop_width) u3(.rx_clk(rx_clk),.rst_n(rst_n),.data_in(tx_out),.rx_out(rx_out),.fail());

endmodule
