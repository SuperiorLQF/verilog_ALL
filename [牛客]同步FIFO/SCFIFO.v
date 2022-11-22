`timescale 1ns/1ns
//已通过
/**********************************RAM************************************/
`include "RAM.v"
/**********************************SFIFO************************************/
module sfifo#(
    parameter	WIDTH = 8,
    parameter 	DEPTH = 16
  )(
    input 					clk		,
    input 					rst_n	,
    input 					winc	,
    input 			 		rinc	,
    input 		[WIDTH-1:0]	wdata	,

    output wire				wfull	,
    output wire				rempty	,
    output wire [WIDTH-1:0]	rdata
  );
  reg     [$clog2(DEPTH):0]   wr_addr,
          rd_addr;
  wire    [$clog2(DEPTH)-1:0] wr_addr_true,
          rd_addr_true;
  wire                        wr_addr_msb,
                              rd_addr_msb;
  assign  {wr_addr_msb,wr_addr_true}=wr_addr;
  assign  {rd_addr_msb,rd_addr_true}=rd_addr;
  always @(posedge clk,negedge rst_n)
  begin//写
    if(~rst_n)
      wr_addr<='b0;
    else if(~wfull&&winc)//给外部控制器的要求
    //如果写满后输入FIFO的winc不能为高，不然虽然FIFO层地址不增加，但是RAM层的最高位地址会被覆盖
      wr_addr<=wr_addr+1'b1;
  end
  always @(posedge clk,negedge rst_n)
  begin//读
    if(~rst_n)
      rd_addr<='b0;
    else if(~rempty&&rinc)
      rd_addr<=rd_addr+1'b1;
  end
  dual_port_RAM#(
                 .WIDTH(WIDTH),
                 .DEPTH(DEPTH)
               )
               RAM1(
                 .wclk(clk),
                 .wenc(winc),
                 .waddr(wr_addr_true),
                 .wdata(wdata),
                 .rclk(clk),
                 .renc(rinc),
                 .raddr(rd_addr_true),
                 .rdata(rdata)
               );

assign  rempty=(rd_addr==wr_addr)?1'b1:1'b0;
assign  wfull=((rd_addr_msb!=wr_addr_msb)&&
              (rd_addr_true==wr_addr_true))?1'b1:1'b0;
endmodule
