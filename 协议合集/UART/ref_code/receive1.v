
module receive1 (
    input               clk,
    input               rst_n,
    input   wire [7 : 0] ab,
    input               rdn,//
    input               wrn,//
    input   wire        rxd,//
    output  reg        txd_clk_r,//
    input   wire [7 : 0] scon,
    input   wire        div_clk,//
    input               REN,
    output  reg         ri,
                        rb8,
    output  wire [7 : 0] db_r,
    output  wire        p_clk,//
    output  reg        flag
);
    parameter   RBUF_ADDR       = 8'h98;
    parameter   idle            = 3'b000;
    parameter   start           = 3'b001;
    parameter   data            = 3'b010;
    parameter   stop            = 3'b011;
    parameter   inter           = 3'b100;
    parameter   receive_rb8     = 3'b101;
	
	reg     [7 : 0]    RSHIFT;
    reg     [7 : 0]     RBUF;
    wire               rbuf_select;
    wire                sm2;
    
    wire    [1 : 0]     SM;
    
    reg     [2 : 0]     current_state,
                        next_state;
    reg txd_clk;
	reg     [2 : 0] data_capture;
    reg            rxd_a;
	reg    rxd_0,negrxd;
	reg                 r8_en;
	reg    [2 : 0]     r_count;
	reg                 to_buf,
                        rb8_buf;
    assign  SM  = scon[7 : 6];
    assign  sm2 = scon[5];

//输出数据
    assign rbuf_select = (ab == RBUF_ADDR);
    assign  db_r = (!rdn && rbuf_select) ? RBUF : 8'b0;

    reg [3 : 0] counter_16;

    reg         txd_clk_0;
//p1 clk �?验起始位
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n)
            counter_16 <= 1'b0;
        else if (div_clk && (current_state != idle)) //
            counter_16 <= counter_16 + 1'b1;
        else if (current_state == idle)
            counter_16 <= 1'b0;
    end
    
    always @(posedge clk  or negedge rst_n) begin // 方式0输出时钟，占空比��?0.5
        if (!rst_n )
            txd_clk <= 1'b1;
        else if (counter_16 == 4'b1111) //16�?1
            txd_clk <= 1'b1;
        else if (counter_16 == 4'b0111) //8�?0
            txd_clk <= 1'b0;
    end

    always @(*) begin
        if (SM == 2'b00)
            txd_clk_r = !txd_clk;
        else 
            txd_clk_r = 1'b1;
    end

    
    always @(posedge clk  or negedge rst_n) begin
        if (!rst_n)
            txd_clk_0 <= 1'b0;
        else if (txd_clk != txd_clk_0)
            txd_clk_0 <= txd_clk;
    end

    assign p_clk = ( txd_clk_0 != txd_clk) && txd_clk;


//----------------------------  时钟模块结束 -----------------------------------

//----------------------------  三段状�?�机模块 --------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_state <= idle;
        else if (p_clk || current_state == idle || (counter_16 == 4'b1001 && current_state == stop) || current_state == inter) 
            current_state <= next_state;
    end

//第二个always块，状�?�转移条�?
    always @(*) begin
        case (current_state)
            idle:begin
                if (!REN)//允许接收位；
                    next_state = idle;
                else if (SM == 2'b00)//方式0直接接收
                    next_state = data;
                else if (negrxd)//判断起始位，
                    next_state = start;
                else 
                    next_state = idle;
            end
            start:begin 
                if (!rxd_a)//起始位为0
                    next_state = data;
                else if (rxd_a && p_clk)
                    next_state = idle;
                else 
                    next_state = data;
            end
            data:begin //此状态为接收状�????
                if (r_count == 3'b111) begin
                    if (SM == 2'b00)
                        next_state = inter;
                    else  if(SM[1] == 1'b1)
                        next_state = receive_rb8;
                    else 
                        next_state = stop;
                 end
                else
                    next_state = data;
            end
            receive_rb8:
                    next_state = stop;
            stop:
                    next_state = inter;
            inter:
                next_state = idle;
            default: next_state = 3'bx;
        endcase
    end


    

   
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            data_capture <= 3'b111;//空闲时为高位
        else if (((counter_16 == 4'b0111) || (counter_16 == 4'b1000) || (counter_16 == 4'b1001))&& div_clk)  begin
            data_capture[0] <= rxd;
            data_capture[2 : 1] <= data_capture[1 :0];  
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
	

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_0 <= 1'b0;
            negrxd <= 1'b0;
        end 
        else if ((rxd_0 != rxd) && (current_state == idle)) begin
            rxd_0 <= rxd;
            if (rxd_0 == 1'b1)
                negrxd <= 1'b1;
            end 
        else if (current_state != idle)
            negrxd <= 1'b0;
    end 
    

//--------------------------------------- state = data ---------------------------------------      

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            RSHIFT <= 8'b0;
            r_count <= 3'b0;
            flag <= 1'b0;
        end else if (((current_state == data) || (next_state == data)) && p_clk ) begin
                 if ((SM == 2'b00) || (current_state == data))begin//在接收数据，按照clk的时钟来
                    RSHIFT <= {rxd_a, RSHIFT[7 : 1]};
                    r_count <= r_count + 1'b1;  
                    flag   <= 1'b1;      
                end 
            end
            else if (current_state== inter)//操作flag
                flag <= 1'b0;
    end

//----------------------------------------  state = stop ------------------------------------

   
    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            r8_en <= 0;
        else if ((current_state == receive_rb8 && SM[1]==1'b1) || (current_state == stop && SM==2'b01))
            r8_en <= (!ri && (!sm2 || rxd_a));

   
   
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            rb8_buf <= 1'b0;
            to_buf <= 1'b0; 
        end else if ((current_state == receive_rb8 && SM[1]==1'b1) || (current_state == stop && SM==2'b01)) begin
            rb8_buf <= rxd_a;
            to_buf <= r8_en; //
        end
    end
//---------------------------------------- state = inter -------------------------------------
//对inter状�?�的操作
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
                ri = (current_state == inter) && to_buf ;
        else 
            ri = (r_count == 3'b111) && p_clk;
//-------------------------------------- 三段状�?�机模块结束 --------------------------------------


endmodule