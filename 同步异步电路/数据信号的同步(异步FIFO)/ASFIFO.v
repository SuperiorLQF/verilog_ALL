//牛客网VL45 异步FIFO
//2023年2月27日15:45:43
`timescale 1ns/1ns
/***************************************RAM*****************************************/
module dual_port_RAM 
#(  parameter DEPTH = 16,
    parameter WIDTH = 8)
(
	 input wclk                         //写时钟
	,input wenc                         //写使能
	,input [$clog2(DEPTH)-1:0] waddr  //深度对2取对数，得到地址的位宽。
	,input [WIDTH-1:0] wdata      	    //数据写入
	,input rclk                         //读时钟
	,input renc                         //读使能
	,input [$clog2(DEPTH)-1:0] raddr  //深度对2取对数，得到地址的位宽。
	,output reg [WIDTH-1:0] rdata 		//数据输出
);

reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];    //寄存器数组
//读写分离
always @(posedge wclk) begin
	if(wenc)
		RAM_MEM[waddr] <= wdata;
end 

always @(posedge rclk) begin
	if(renc)
		rdata <= RAM_MEM[raddr];
end 

endmodule  

/***************************************AFIFO*****************************************/
module asyn_fifo#(
	parameter	WIDTH = 8,
	parameter 	DEPTH = 16
)(
	input 					wclk	, 
	input 					rclk	,   
	input 					wrstn	,
	input					rrstn	,
	input 					winc	,//写使能
	input 			 		rinc	,//读使能
	input 		[WIDTH-1:0]	wdata	,

	output wire				wfull	,
	output wire				rempty	,
	output wire [WIDTH-1:0]	rdata
);
//扩展地址
reg  [$clog2(DEPTH):0]      rptr_expand ,
                            rptr_expand_g,
                            rptr_expand_g_d1,
                            rptr_expand_g_d2,//写时钟域的读地址

                            wptr_expand ,
                            wptr_expand_g,
                            wptr_expand_g_d1,
                            wptr_expand_g_d2;//读时钟域的写地址

wire                        wenc,
                            renc;
assign wenc=winc&(~wfull);  //写使能且未写满
assign renc=rinc&(~rempty); //读使能且未读空
/**************原始指针读写变化逻辑***********************/
always@(posedge wclk,negedge wrstn)begin
    if(~wrstn)
        wptr_expand<=0;
    else if(wenc)
        wptr_expand<=wptr_expand+1;
    else
        wptr_expand<=wptr_expand;
end
always@(posedge rclk,negedge rrstn)begin
    if(~rrstn)
        rptr_expand<=0;
    else if(renc)
        rptr_expand<=rptr_expand+1;
    else
        rptr_expand<=rptr_expand;
end
/*********指针地址转换为格雷码*******************/
//由于定义时格雷码是reg类型，因此打一拍更加规范,当然也为了过本题的原因
always@(posedge wclk,negedge wrstn)begin
    if(~wrstn)
        wptr_expand_g<=0;
    else
        wptr_expand_g<=(wptr_expand>>1)^(wptr_expand);
end
always@(posedge rclk,negedge rrstn)begin
    if(~rrstn)
        rptr_expand_g<=0;
    else
        rptr_expand_g<=(rptr_expand>>1)^(rptr_expand);
end
/******************同步器************************/
always @(posedge wclk,negedge wrstn) begin
    if(~wrstn)
        {rptr_expand_g_d2,rptr_expand_g_d1}<=2'b0;
    else
        {rptr_expand_g_d2,rptr_expand_g_d1}<={rptr_expand_g_d1,rptr_expand_g};
end
always @(posedge rclk,negedge rrstn) begin
    if(~rrstn)
        {wptr_expand_g_d2,wptr_expand_g_d1}<=2'b0;
    else
        {wptr_expand_g_d2,wptr_expand_g_d1}<={wptr_expand_g_d1,wptr_expand_g};
end
/***************EMPTY&FULL************************/
assign rempty=(rptr_expand_g==wptr_expand_g_d2)?1:0;
assign wfull=(wptr_expand_g=={~(rptr_expand_g_d2[$clog2(DEPTH)-:2]),rptr_expand_g_d2[$clog2(DEPTH)-2:0]})?1:0;

/********************双口RAM例化****************/
dual_port_RAM 
#(
    DEPTH,
    WIDTH
)
d1
(    
     wclk   //                     
    ,wenc   //                        
    ,wptr_expand[$clog2(DEPTH)-1:0]   //
    ,wdata  //    	
    ,rclk   //                     
    ,renc   //                   
    ,rptr_expand[$clog2(DEPTH)-1:0]   //!!!
    ,rdata 	//
);
endmodule