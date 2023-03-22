module key_jitter(
    input diff_clock_clk_p,
    input diff_clock_clk_n,
//    input clk_i,
    input rst_n_i,
    input key_i,
    output [3:0] led_o
);
(*mark_debug="true"*) reg[3:0] led_o;
(*mark_debug="true"*) wire key_cap;

wire clk_i;
IBUFGDS CLK_U(
    .I(diff_clock_clk_p),
    .IB(diff_clock_clk_n),
    .O(clk_i)
);

always@(posedge clk_i,negedge rst_n_i)begin
    if(~rst_n_i)
        led_o<=4'b0;
    else if(key_cap)
        led_o<=~led_o;
end

key key0(
    clk_i,
    rst_n_i,
    key_i,
    key_cap
);
endmodule