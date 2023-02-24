`timescale 1ns/1ps
`include "button_light.v"
module button_light_tb;
reg         rst_n   ,
            clk     ,
            button  ;
            
wire        light   ;

//模块例化
button_light b1(
            clk     ,
            button  ,
            rst_n   ,
                    
            light 
);
//激励
initial begin
            $dumpfile("button_light.vcd");
            $dumpvars;
            
            clk<=0;
            rst_n<=0;
            button<=0;

    #15     rst_n<=1;
    #20     button<=1;
    #160    button<=0;
    #125    button<=1;
    #130    button<=0;
    #55     button<=1;
    #60     button<=0;
    #1000   $finish;
end
//时钟生成
always #10
    clk=~clk;
endmodule