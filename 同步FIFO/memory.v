`timescale 1ns/100ps
module memory #( 
    parameter   W = 8,//位宽
                L = 5//地址线
    ) (
    input  wire 	        clk, 
    input  wire [W-1 : 0]   data_A, //写数据
    input  wire [L-1 : 0]   addr_A, 
    output wire [W-1 : 0]   data_B, //读数据
    input  wire [L-1 : 0]   addr_B, 
    input  wire 	        rd,     //读信号，低有效
		                    wr      //写信号，低有效
    ); 
    reg [W-1 : 0] mem [(1<<L)-1 : 0]; //存储单元
    reg [L-1 : 0] addr_rd;
    assign data_B = mem[addr_rd];   //注意，因为data_B是wire类型，所以用addr_rd作为中间变量
    
    always @( posedge clk) 
        if(!rd)
            addr_rd <= addr_B;      //同步读

    always @( posedge clk)          //同步写
        if(!wr)
            mem[addr_A] <= data_A; 
endmodule
