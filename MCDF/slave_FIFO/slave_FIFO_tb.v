`timescale 1ns/100ps
`include "slave_FIFO.v"
/*************************<端口声明>*********************/
module  slave_FIFO_tb;
reg             clk_i;       
reg             rstn_i;       
reg             chx_valid_i;  
reg             a2sx_ack_i;  
reg             slvx_en_i;   
reg    [31:0]  chx_data_i;
reg    [2:0]   slvx_pkglen_i;

wire            chx_ready_o;
wire    [5:0]   margin_o;  
wire    [31:0]  slvx_data_o;  
wire            slvx_val_o;  
wire            slvx_req_o;  
/********************<实例化slave_FIFO>*********************/
slave_FIFO  slave1(
                clk_i,       
                rstn_i,       
                chx_valid_i,  
                a2sx_ack_i, 
                slvx_en_i,             
                chx_data_i,
                slvx_pkglen_i,
                
                chx_ready_o,
                margin_o,
                slvx_data_o,  
                slvx_val_o, 
                slvx_req_o  
);
initial begin
    clk_i<=0;//
    rstn_i<=0;//
    chx_valid_i<=1;
    a2sx_ack_i<=0;
    slvx_en_i<=1;//
    chx_data_i<=$random;
    slvx_pkglen_i<=2'b00;//
    $dumpfile("slave_FIFO.vcd");
    $dumpvars;
#25 rstn_i<=1;//
repeat(2)begin
    @(posedge clk_i)begin
        chx_valid_i<=1;
        chx_data_i<=$random;            
    end
end
    @(posedge clk_i)begin
        chx_valid_i<=0;
        chx_data_i<=$random;    
    end
repeat(5)begin
    @(posedge clk_i)begin
        chx_valid_i<=1;
        chx_data_i<=$random;            
    end
end
@(posedge clk_i)
a2sx_ack_i<=1;
@(posedge clk_i)
a2sx_ack_i<=0;chx_valid_i<=0;
#100
@(posedge clk_i)
a2sx_ack_i<=1;
@(posedge clk_i)
a2sx_ack_i<=0;
#200
repeat(40)begin
    @(posedge clk_i)begin
        chx_valid_i<=1;
        chx_data_i<=$random;            
    end
end
    #2000 $finish;
end
always #10 clk_i<=~clk_i;
endmodule