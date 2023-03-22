//Name: proc
//Function: 
//	 	00: mv	    Rx,Ry			: Rx <- [Ry]
//	 	01: mvi		Rx,#D			: Rx <- D
//	 	10: add		Rx, Ry			: Rx <- [Rx] + [Ry]
//	 	11: sub		Rx, Ry			: Rx <- [Rx] - [Ry]
//	 	OPCODE format: II XX YY, where 
//	 	II = instruction, XX = Rx, and YY = Ry. For mvi,
//	 	a second word of data is loaded from DIN
//      run = 1, cpu can run
//Author: caojian

//DIN, Resetn, Clock, Run, Done, BusWires

module proc
#(parameter REG_NUM = 4, DATAWIDTH = 6)
(
	input                      clk_in1_p, clk_in1_n,//用于ILA
	input 	   [DATAWIDTH-1:0] DIN,
	input 			           Resetn, Clock, Run,
	output reg       		   Done,
	output     [DATAWIDTH-1:0] BusWires
);

	// input ins, and decode signals.2 bits for instruction, 4 bits for Rx and Ry respectively.
	wire [5:0] IR;
	wire [1:0] I;
	wire [REG_NUM - 1 : 0]  X, Y;

	// physical register and bus signals:
	wire [DATAWIDTH - 1 : 0] R0, R1, R2, R3, A, G, Sum;

	// control signals for mux select:
	reg IRin, DINout, Ain, Gin, Gout;
	reg [REG_NUM-1:0] Rin, Rout;

	// control signals for add/sub unit:
	reg AddSub;

	// control signals for run/step:
	wire [1:0] Tstep_Q;
	
	// run=1, shield the Tstep, both Tstep_Q[1] and Tstep_Q[0]=0 
	// means current instruction is finished. <run=1 cpu not stop until Tstep=0>
	wire Clear = ~Resetn | Done | (~Run & ~Tstep_Q[1] & ~Tstep_Q[0]); //Tstep清零器
	
	always@(Tstep_Q or X or Y or I)
	begin
		Done = 1'b0; Ain = 1'b0; 
		Gin = 1'b0; Gout = 1'b0; 
		AddSub = 1'b0; IRin = 1'b0; 
		DINout =1'b0; Rin = 'd0; 
		Rout = 'd0;
		
	case(Tstep_Q)
		//***********<ADD content>*********************
		2'b00:begin//IF
			IRin=1;
		end

		2'b01:begin
			case(I)
				2'b00:begin
					{Rout,Rin,Done}={Y,X,1'b1};
				end
					
				2'b01:begin
				  	{DINout,Rin,Done}={1'b1,X,1'b1};
				end

				2'b10:begin
					{Rout,Ain}={X,1'b1};
				end
					
				2'b11:begin
					{Rout,Ain}={X,1'b1};
				end
			endcase
		end

		2'b10:begin
			case(I)
				2'b00:begin
					//
				end
					
				2'b01:begin
				  	//
				end

				2'b10:begin
					{Rout,Gin}={Y,1'b1};
				end
					
				2'b11:begin
					{Rout,Gin,AddSub}={Y,2'b11};
				end
			endcase

		end

		2'b11:begin
			case(I)
				2'b00:begin
					//
				end
					
				2'b01:begin
				  	//
				end

				2'b10:begin
					{Gout,Rin,Done}={1'b1,X,1'b1};
				end
					
				2'b11:begin
					{Gout,Rin,Done}={1'b1,X,1'b1};
				end
			endcase
		end

		//////////////////////////////////
	endcase
	end

	//reg groups
	regn reg_0(BusWires, Rin[3], Clock, R0);
	regn reg_1(BusWires, Rin[2], Clock, R1);
	regn reg_2(BusWires, Rin[1], Clock, R2);
	regn reg_3(BusWires, Rin[0], Clock, R3);

	regn reg_A(BusWires, Ain, Clock, A);

	regn #(.n(6)) reg_IR(DIN[5:0], IRin, Clock, IR);
	regn reg_G(Sum, Gin, Clock, G);

	// ins decode
	assign I = IR[5:4];
	decoder decX (IR[3:2], 1'b1, X);
	decoder decY (IR[1:0], 1'b1, Y);

	//AddSub
	addsub addsub1(AddSub, A, BusWires, Sum);

	//mux
	busmux busmux1(Rout, Gout, DINout, R0, R1, R2, R3, G, DIN, BusWires);

	//counter
	upcount Tstep (Clear, Clock, Tstep_Q);

	
	// for probe
	 wire CLOCK_50;
     clk_wiz_0 u_clk_wiz
      (
       // Clock out ports
       .clk_out1(CLOCK_50),     // output clk_out1
      // Clock in ports
       .clk_in1_p(clk_in1_p),    // input clk_in1_p
       .clk_in1_n(clk_in1_n));    // input clk_in1_n
      
      ila_0 your_instance_name (
           .clk(CLOCK_50),
           .probe0(Clock),
           .probe1(Resetn),
           .probe2(Run),
           .probe3(BusWires),
           .probe4(R0),
           .probe5(R1),
           .probe6(R2),
           .probe7(R3),
           .probe8(Rin),
           .probe9(Rout),
           .probe10(Tstep_Q),
           .probe11(Done)
       );
      

endmodule
