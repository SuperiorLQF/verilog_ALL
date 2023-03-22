//button shiver avoid module
module key(
    input clk_i,
    input rst_n,
    input key_i,
    output key_cap//capture the button is pressed
);

/**************<frequency division part>*****************/
parameter CLK_freq=100_000_000;//clk_i frequency is 100M
parameter T_clk=1000_000_000/CLK_freq;//clk_i period(in ns)
parameter T_divided=500_000_000;//clk_divided period (in ns)
parameter NUM_count=T_divided/T_clk-1;//frequency division coefficient
reg[29:0] counter;
(*mark_debug="true"*) wire flag_dividedT;
always@(posedge clk_i,negedge rst_n)begin
    if(~rst_n)
        counter<=30'b0;
    else if(counter<NUM_count)
        counter<=counter+1'b1;
    else
        counter<=30'b0;
end
assign flag_dividedT=(counter==NUM_count);
/********************************************************/


/***********************<FSM with counter>***************************/
parameter   S0=2'b00;
parameter   S1=2'b01;
parameter   S2=2'b10;
parameter   S3=2'b11;
(*mark_debug="true"*) reg [1:0]   cstate;
reg [1:0]   nstate;
always @(posedge clk_i,negedge rst_n) begin
    if(~rst_n)
        cstate<=S0;
    else
        cstate<=nstate;
end

always @(*) begin
    if(flag_dividedT)// sample every flag slot
        case(cstate)
            S0:nstate=(key_i==1'b1)?S0:S1;
    
            S1:nstate=(key_i==1'b1)?S0:S2;
    
            S2:nstate=(key_i==1'b0)?S2:S3;
    
            S3:nstate=(key_i==1'b1)?S0:S2;
    
        endcase
     else
        nstate=cstate;
end
/********************************************************/


/***********************<state lock&output logic>***************************/
(*mark_debug="true"*) reg [1:0] cstate_r;
always@(posedge clk_i,negedge rst_n)begin
    if(~rst_n)
        cstate_r<=S0;
    else
        cstate_r<=cstate;
end
assign key_cap=((cstate==S2)&&(cstate_r==S1))?1:0;
/********************************************************/
endmodule