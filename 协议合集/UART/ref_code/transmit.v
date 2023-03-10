module transmit(
    input               clk,
    input               rst_n,
    input   wire [7 : 0] ab,//address bus
    input               wrn,//低电平有效
    input   wire [7 : 0] scon,
    input   wire        div_clk,//
    output   reg         txd,//方式1，2,3 串行输出
    output   reg         ti,
    input  wire [7 : 0] db_w,//数据总线，如果地址符合，则写入transmit
    output  reg           TEN,//??
    output  reg           rxd_out,//方式0，串行输出
    output  reg            flag
);
    //状态机编码
	parameter   idle    = 3'b000;
    parameter   start   = 3'b001;
    parameter   data    = 3'b010;
    parameter   crc     = 3'b011;
    parameter   stop    = 3'b100;
	parameter   TSHIFT_ADDR     = 8'h98;
    
	reg     [7 : 0]    TSHIFT;
    
    wire               tshift_select;
    wire                TI,TB8;

    wire    [1 : 0]     SM;//?
    
    
    reg     [2 : 0]     current_state,
                        next_state;
						
	reg      [2 : 0]   t_count;//记录已经发送数位的寄存器					
	reg txd_clk;					
	reg txd_t;

     

    reg [3 : 0] counter_16;

    reg         txd_clk_0;
    wire        p_clk;

	assign      SM   = scon[7 : 6]; //SM0/SM1 串行口工作方式选择位置
    assign      TB8  = scon[3];//发送数据第九位（若有）
    assign      TI   = scon [1];//发送中断标志
   
    assign tshift_select = (ab == TSHIFT_ADDR);//确定address bus上的地址是否为发送地址，如果是发送地址，tshift_select=1
	
    always @(posedge clk or negedge rst_n) begin //分频的意义是每个bit传输间隔
        if (!rst_n)
            counter_16 <= 1'b0;
        else if (!((next_state == idle) && (current_state == idle)) && div_clk) //在传输过程中，每次都需要counter计数
            counter_16 <= counter_16 + 1'b1;
        else if ((next_state == idle) && (current_state == idle))
            counter_16 <= 1'b0;
    end

    

    always @(posedge clk  or negedge rst_n) begin //每8个分频时钟，设置对应的发送时钟
        if (!rst_n )
            txd_clk <= 1'b1;
        else if (counter_16 == 4'b1111) //
            txd_clk <= 1'b1;
        else if (counter_16 == 4'b0111) //
            txd_clk <= 1'b0;
    end

    //txd_clk_0干啥的
    always @(posedge clk  or negedge rst_n) begin
        if (!rst_n)
            txd_clk_0 <= 1'b0;
        else if (txd_clk != txd_clk_0)
            txd_clk_0 <= txd_clk;
    end

    assign p_clk = ( txd_clk_0 != txd_clk) && txd_clk;


//状态跳变
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= idle;
        end
        else if (p_clk) //存完数据�?
            current_state <= next_state;
    end

//状态转换
    always @(*) begin
        case (current_state)
            idle:begin
                if (TEN)
                    if (SM == 2'b00)
                        next_state = data;//同步移位寄存器方式00
                    else
                        next_state = start;
                else
                    next_state = idle;
            end
            start:
                    next_state = data;
            data:begin
                if (t_count == 3'b111)
                    if (SM == 2'b00)
                        next_state = idle;
                    else if (SM == 2'b01)
                        next_state = stop;//说明工作在方式1，有停止位
                    else 
                        next_state = crc;//工作在方式2，有校验位
                else
                    next_state = data; //由于进入data的方式不�??? 
                
            end
            crc:
                next_state = stop;
            stop:
                next_state = idle;  
            default:
                next_state = 3'bx;  
        endcase  
end

    
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            txd_t <= 1'b1; 
            flag <= 1'b0;
        end else if ((next_state == start) && p_clk) 
            txd_t <= 1'b0;
        else if (((current_state == data) || (next_state == data)) && p_clk) begin
            if (t_count != 3'b111)
                txd_t <= TSHIFT[0];
            if (SM == 2'b00) begin
                flag <= 1'b1;
                if (t_count == 3'b111)
                    flag <= 1'b0;
            end
        end else if (current_state == crc)
            txd_t <= TB8;
        else if (current_state == stop) begin
            txd_t <= 1'b1;
            
        end
    end
    always @(*)
        if (SM != 2'b00)
            ti = (current_state == stop) && p_clk;
        else 
            ti = (t_count == 3'b111) && p_clk;

    
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            t_count <= 3'b000;
            TEN <= 1'b0;
        end else if (((current_state == data) || (next_state == data)) && p_clk) begin
            TSHIFT <= TSHIFT >> 1;
            if (current_state == data) //传输状态下，进行串行8bit数据的计数
                t_count <= t_count +1'b1;
        end else if (!wrn && tshift_select) begin //写使能且地址匹配
            TSHIFT <= db_w;
            TEN <= 1'b1;
        end else if (TI) 
            TEN <= 1'b0;
    end
    
    always @(*)
    if (SM == 2'b00)begin
        rxd_out = txd_t;
        txd = 1'b0;
    end
    else begin
        txd = txd_t;
        rxd_out = 1'b0;
    end
endmodule
