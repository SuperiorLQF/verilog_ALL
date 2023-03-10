//用来接收信号读取
// 在方式0下工作
// rxd表示输入输出（方式1方式2只表示接收）
// txd输出同步时钟
// 由于txd在发送模块使用，故应该以其他方式代指
// 在transmit中
module receive (
    input               clk,
    input               rst_n,
    input   wire [7 : 0] ab,
    input               rdn,//低电平有��?
    input               wrn,//低电平有��?
    input   wire        rxd,//输入信号,PC输入过来的数据
    output  reg        txd_clk_r,//方式0同步信号
    input   wire [7 : 0] scon,
    input   wire        div_clk,//数据发态的时钟信号
    input               REN,
    output  reg         ri,
                        rb8,//在receive中改变的状态
    output  wire [7 : 0] db_r,//读数总线(接收时，数据总线只需要读数据)，把PC发来的串行数据变为8位，放在总线上
    output  wire        p_clk,//因为��?要采样所以再16分频，也方便脉冲变时��?
    output  reg        flag
);
    reg     [7 : 0]    RSHIFT;//移位寄存器
    reg     [7 : 0]     RBUF;//接收寄存器
    wire               rbuf_select;
    wire                sm2;//读取的状态
    
    wire    [1 : 0]     SM;
    
    reg     [2 : 0]     current_state,
                        next_state;
    parameter   RBUF_ADDR       = 8'h98;
// 状态机编码
    parameter   idle            = 3'b000;
    parameter   start           = 3'b001;
    parameter   data            = 3'b010;
    parameter   stop            = 3'b011;//读取停止位并判断
    parameter   inter           = 3'b100;//写入sbuf并置中断

//接收控制寄存器

    assign  SM  = scon[7 : 6];
    assign  sm2 = scon[5];
//改变控制寄存器状态

//输出数据
    assign rbuf_select = (ab == RBUF_ADDR);
    assign  db_r = (!rdn && rbuf_select) ? RBUF : 8'b0;

//-------------------------- 时钟模块�态�? ----------------------------------
//16分频子时钟?
    reg [3 : 0] counter_16;

    reg         txd_clk_0;
//p1 clk 检验起始位
    always @(posedge clk or negedge rst_n) begin //分频的意义是每个bit传输间隔
        if (!rst_n)
            counter_16 <= 1'b0;
        else if (div_clk && (current_state != idle)) //
            counter_16 <= counter_16 + 1'b1;
        else if (current_state == idle)
            counter_16 <= 1'b0;
    end

    reg txd_clk;

    always @(posedge clk  or negedge rst_n) begin // 方式0输出时钟，占空比��?0.5
        if (!rst_n )
            txd_clk <= 1'b1;
        else if (counter_16 == 4'b1111) //16置1
            txd_clk <= 1'b1;
        else if (counter_16 == 4'b0111) //8置0
            txd_clk <= 1'b0;
    end
// 产生方式0的接收时钟
    always @(*) begin
        if (SM == 2'b00)
            txd_clk_r <= !txd_clk;
        else 
            txd_clk_r <= 1'b1;
    end
//注意只有这样才是准确的时钟，��?要最后一个div_clk读完
//此处提取接收的时钟上升沿
    
    always @(posedge clk  or negedge rst_n) begin
        if (!rst_n)
            txd_clk_0 <= 1'b0;
        else if (txd_clk != txd_clk_0)
            txd_clk_0 <= txd_clk;
    end

    assign p_clk = ( txd_clk_0 != txd_clk) && txd_clk;//提取16分频时钟的上升沿，长度为1个时钟沿

//----------------------------  时钟模块结束 -----------------------------------

//----------------------------  三段状态机模块 --------------------------------
//三段式状态机,状态idle，start，data，crc，stop
//第一个always描述对应当前状态的状态寄存器
//接收数据的时钟频率率应该为波特率
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_state <= idle;
        else if (p_clk || current_state == idle) // 按设定波特率，子时钟上升沿
            current_state <= next_state;
    end

//第二个always块，状态转移条件
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            next_state <= idle;
        else case (current_state)
            idle:begin
                if (!REN)//允许接收位；
                    next_state <= idle;
                else if (SM == 2'b00)//方式0直接接收
                    next_state <= data;
                else if (negrxd)//判断起始位，
                    next_state <= start;
            end
            start:begin 
                if (!rxd_a )//起始位为0
                    next_state <= data;
                else if (rxd_a && p_clk)
                    next_state <= idle;
            end
            data:begin //此状态为接收状态??
                if (r_count == 3'b111) 
                    if (SM == 2'b00)
                        next_state <= inter;
                    else  
                        next_state <= stop;
                else
                    next_state <= data;
            end
            stop:
                next_state <= inter;
            inter:
                next_state <= idle;
            default: next_state <= 3'bx;
        endcase
    end
//状态机第三端，多个always，对状态进行输出
// 对状态转换条件的描述
//状态有：接收到8位数据，到停止位，接收正常接收，起始位开始，

//
    

    reg     [2 : 0] data_capture;//��?测位
    reg            rxd_a ;//rxd段采样输��?
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            data_capture <= 3'b111;//空闲时为高位
        else if (((counter_16 == 4'b0111) || (counter_16 == 4'b1000) || (counter_16 == 4'b1001))&& div_clk)  begin
            data_capture[0] <= rxd;
            data_capture[2 : 1] <= data_capture[1 :0];  //在第7 8 9个计数值开始采样，取出现最多的次数为接受的串行数据
        end
    end
    //这个always对确认rdx的输��?
    always @(data_capture) begin
        case(data_capture)
            3'b111,3'b011,3'b110,3'b101:
                rxd_a = 1'b1;
		    default: 
                rxd_a = 1'b0;
        endcase
    end
    //��?测负跳变
    reg    rxd_0,negrxd;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_0 <= 1'b0;
            negrxd <= 1'b0;
        end else if ((rxd_0 != rxd) && (current_state == idle)) begin
            rxd_0 <= rxd;
            if (rxd_0 == 1'b1)
                negrxd <= 1'b1;
        end else if (current_state != idle)
            negrxd <= 1'b0;
    end 
    

//--------------------------------------- state = data ---------------------------------------      
//对data状态的操作，这个always对移位寄存器操作，计数器操作,包括接收
    reg    [2 : 0]     r_count;//接收计数��?
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            RSHIFT <= 8'b0;
            r_count <= 3'b0;
            flag <= 1'b0;
        end else if (((current_state == data) || (next_state == data)) && p_clk ) 
            if ((SM == 2'b00) || (current_state == data))begin//在接收数据，按照clk的时钟来
                RSHIFT <= {rxd_a, RSHIFT[7 : 1]};
                r_count <= r_count + 1'b1;  
                flag   <= 1'b1;      
            end 
        else if (current_state== inter)//操作flag
                flag <= 1'b0;
    end
//有脉冲就读数��?
//----------------------------------------  state = stop ------------------------------------

    reg                 r8_en;//��?8位数据有��?
//这个always判断��?8位放入sbuf的条��?
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            r8_en <= 0;
        else if (p_clk)
            r8_en <= (!ri && (!sm2 || rxd));

    //数据装入sbuf的条件：未置中断的情况下：方��?0已经读取8位数据，方式1��?2 在子时钟下第9位或sm2满足条件 
//对stop状态的操作，接收数据并判断
    reg                 to_buf,//读入buf标志
                        rb8_buf;//rb8暂存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            rb8_buf <= 1'b0;
            to_buf <= 1'b0; 
        end else if (current_state == stop) begin
            rb8_buf <= rxd_a;
            to_buf <= r8_en; //
        end
    end
//---------------------------------------- state = inter -------------------------------------
//对inter状态的操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)   
            RBUF <= 8'b0;
        else if ((current_state == inter) && (to_buf || (SM == 2'b00))) begin 
            RBUF <= RSHIFT;
            if (SM != 2'b00)
                rb8 <= rb8_buf;
         end
    end
    always @(*)
        if (SM != 2'b00)
                ri = (current_state == inter) && to_buf && p_clk;
        else 
            ri = (r_count == 3'b111) && p_clk;
//-------------------------------------- 三段状态机模块结束 --------------------------------------


endmodule
