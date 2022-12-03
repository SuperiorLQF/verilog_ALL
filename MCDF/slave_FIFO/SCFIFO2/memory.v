`timescale 1ns/1ns
module memory #( 
    parameter  W = 8,
              L = 5
    ) (
   input  wire 	      clk, 
    input  wire [W-1 : 0] data_A, 
    input  wire [L-1 : 0]  addr_A, 
    output wire [W-1 : 0]  data_B, //读
    input  wire [L-1 : 0] addr_B, 
    input  wire 	      rd, 
		              wr 
    ); 
    reg [W-1 : 0] mem [(1<<L)-1 : 0]; 
    reg [L-1 : 0] addr_rd;
    assign data_B = mem[addr_rd]; 
    always @( posedge clk) 
         if(!rd)
addr_rd <= addr_B; 

    always @( posedge clk) 
       if(!wr)
mem[addr_A] <= data_A; 
endmodule 
