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

    output reg				wfull	,
    output reg				rempty	,
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
    else if(~wfull&&winc)
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
  always @(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      rempty<=1'b0;
      wfull<=1'b0;
    end
    else
    begin
      rempty<=(rd_addr==wr_addr)?1'b1:1'b0;
      wfull<=((rd_addr_msb!=wr_addr_msb)&&
              (rd_addr_true==wr_addr_true))?1'b1:1'b0;
    end

  end
endmodule
