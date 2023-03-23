`timescale 1ns / 1ps
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2021/10/15
*Module Name:uicfg0135
*File Name:uicfg0135.v
*Description: 
*config sensor resgister
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.0
*Signal description
*1) _i input
*2) _o output
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/
module uart_top(
	input clk_i,
	input uart_rx_i,
	output uart_tx_o,
	output pen_o
	
    );


assign pen_o=1'b1;
wire [7:0] uart_rx_data_o;
wire uart_rx_done;
  
uart_rx_path uart_rx_path_u (
    .clk_i(clk_i), 
    .uart_rx_i(uart_rx_i), 
    .uart_rx_data_o(uart_rx_data_o), 
    .uart_rx_done(uart_rx_done)
    );
    
uart_tx_path uart_tx_path_u (
    .clk_i(clk_i), 
    .uart_tx_data_i(uart_rx_data_o), 
    .uart_tx_en_i(uart_rx_done), 
    .uart_tx_o(uart_tx_o)
    );
    
endmodule
