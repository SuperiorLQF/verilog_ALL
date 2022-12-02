`timescale 1ns/100ps
`include "control_register.v"
/*************************<端口声明>*********************/
module control_register_tb;
reg             clk_i,
                rstn_i;
reg     [1:0]   cmd_i;
reg     [5:0]   cmd_addr_i;
reg     [31:0]  cmd_data_i;    
reg     [5:0]   slv0_margin_i,
                slv1_margin_i,
                slv2_margin_i;


wire            slv0_en_o,
                slv1_en_o,
                slv2_en_o;    
wire    [31:0]  cmd_data_o;
wire    [1:0]   slv0_prio_o,
                slv1_prio_o,
                slv2_prio_o;
wire    [2:0]   slv0_pkglen_o,
                slv1_pkglen_o,
                slv2_pkglen_o;
/*************************<原件例化>*********************/
control_register cr1(
                clk_i,
                rstn_i,
                cmd_i,
                cmd_addr_i,
                cmd_data_i,   
                slv0_margin_i,
                slv1_margin_i,
                slv2_margin_i,
                
                slv0_en_o,
                slv1_en_o,
                slv2_en_o,
                cmd_data_o,
                slv0_prio_o,
                slv1_prio_o,
                slv2_prio_o,
                slv0_pkglen_o,
                slv1_pkglen_o,
                slv2_pkglen_o
);
/*************************<激励信号>*********************/
initial begin
    clk_i=0;
    rstn_i=0;
    cmd_i='b00;
    cmd_addr_i='b00;
    cmd_data_i='hC3;  
    slv0_margin_i='d21;
    slv1_margin_i='d33;
    slv2_margin_i='d45;    
    $dumpfile("control_register.vcd");
    $dumpvars;
    #25 rstn_i=1;
    @(posedge clk_i)begin
        cmd_i='b10;
        cmd_addr_i='d00;
        cmd_data_i='hD1;     
    end
    @(posedge clk_i)begin
        cmd_i='b10;
        cmd_addr_i='d04;
        cmd_data_i='hD2;     
    end
    @(posedge clk_i)begin
        cmd_i='b10;
        cmd_addr_i='d08;
        cmd_data_i='hD3;     
    end
    @(posedge clk_i)begin
        cmd_i='b00;
        cmd_addr_i='d08;
        cmd_data_i='hD3;     
    end
    @(posedge clk_i)begin
        cmd_i='b10;
        cmd_addr_i='d00;
        cmd_data_i='hD4;     
    end
    @(posedge clk_i)begin
        cmd_i='b01;
        cmd_addr_i='d04;
        cmd_data_i='hD4;     
    end
    @(posedge clk_i)begin
        cmd_i='b01;
        cmd_addr_i='d00;
        cmd_data_i='hD4;     
    end
    #500 $finish;
end
always #10
    clk_i=~clk_i;

endmodule