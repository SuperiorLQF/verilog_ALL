----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2020/11/15 14:54:16
-- Design Name: 
-- Module Name: TREQRESP - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TREQRESP is
    Port ( 
	clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    --Status input interface-----------------
    linkup			: in  std_logic;
    --Config interface-----------------------
    self_id			: in  std_logic_vector(15 downto 0);
    --Target request input interface---------
    treq_tvalid		: in  std_logic;
    treq_tready		: out std_logic;
    treq_tlast		: in  std_logic;
    treq_tdata		: in  std_logic_vector(63 downto 0);
    treq_tkeep		: in  std_logic_vector( 7 downto 0);
    treq_tuser		: in  std_logic_vector(31 downto 0);
    --Target response output interface--------
    tresp_tvalid	: out std_logic;
    tresp_tready	: in  std_logic;
    tresp_tlast		: out std_logic;
    tresp_tdata		: out std_logic_vector(63 downto 0);
    tresp_tkeep		: out std_logic_vector( 7 downto 0);
    tresp_tuser		: out std_logic_vector(31 downto 0);
    --Addr Remap-------------------------------
    maping1_base     : in  std_logic_vector(15 downto 0);
    maping1_high     : in  std_logic_vector(15 downto 0);
    maping1_target   : in  std_logic_vector(31 downto 0);
    maping2_base     : in  std_logic_vector(15 downto 0);
    maping2_high     : in  std_logic_vector(15 downto 0);
    maping2_target   : in  std_logic_vector(31 downto 0);   
	--DoorBell buffer fifo interface-----------
    db_fifo_wren	: out std_logic;
    db_fifo_data	: out std_logic_vector(63 downto 0);
    --NWriteR/NWrite/SWrite-buf interface------
	WA_addr		: out std_logic_vector( 7 downto 0);--地址
	WA_wren		: out std_logic_vector( 0 downto 0);--写使能
	WA_data_wr	: out std_logic_vector(63 downto 0);--数据总线
	--AxiRam Control interface--------------------
	WAstart		: out std_logic;					--AXi写
	WAidle		: in  std_logic;
	WAcount		: out std_logic_vector(31 downto 0);
	WAaddr		: out std_logic_vector(31 downto 0);
    --NRead-buf interface---------------------------
	RA_addr		: out std_logic_vector( 7 downto 0);--读地址
	RA_data_rd	: in  std_logic_vector(63 downto 0);--读数据
    --AxiRam Control interface--------------------
    RAstart		: out std_logic;					--Axi读
    RAidle		: in  std_logic;
    RAcount		: out std_logic_vector(31 downto 0);
    RAaddr		: out std_logic_vector(31 downto 0)
    );
end TREQRESP;

architecture Behavioral of TREQRESP is

	
	signal treq_tready_w	: std_logic:='0';
	signal regReqHead		: std_logic_vector(63 downto 0):=x"0000000000000000";
	signal TID				: std_logic_vector( 7 downto 0):=x"00";
	signal FTYPE			: std_logic_vector( 3 downto 0):=x"0";
	signal TTYPE			: std_logic_vector( 3 downto 0):=x"0";
	signal SIZE				: std_logic_vector( 7 downto 0):=x"00";
	signal ADDR				: std_logic_vector(33 downto 0):="00"&x"00000000";
	signal DBINFO           : std_logic_vector(15 downto 0):=x"0000";
	signal TUSER			: std_logic_vector(31 downto 0):=x"00000000";
	signal regLast			: std_logic:='0';
	signal cntsNswrWA2axi	: std_logic_vector( 3 downto 0):=x"0";
	signal cntsNrdRAaxi		: std_logic_vector( 3 downto 0):=x"0";
	signal cntTrans			: std_logic_vector( 7 downto 0):=x"00";
	signal cntsNrdRespData	: std_logic_vector( 7 downto 0):=x"00";	--回复数据包计数器，回复到了第几个数据包
	signal tresp_tvalid_w	: std_logic:='0';
	
	type state_type is ( sReset, sIdle,
					 sWaitHead, sGotHead,
					 sNswrGetData, sNswrResp, sNswrWA2axi, sNswrWAwaitdone, sNswrFinish,
					 sNrdRAaxi, sNrdRAwaitdone, sNrdRespHead, sNrdRespHead2, sNrdRespData, sNrdFinish,
					 sDbWrInfo, sDbResp, sDbFinish,
					 sError );
	---状态解释
	--
	signal state,next_state : state_type:=sReset;	
begin
	--output logic-------------------------------------------------------
	tresp_logic: process( state, FTYPE, TTYPE, TID, self_id, TUSER, RA_data_rd, cntsNrdRespData, SIZE ) begin
		case state is
		when sNswrResp =>--???这是什么状态捏NWRITE_R或者SWRITE?
			if (FTYPE=x"5" and TTYPE=x"5") then--NWRITE_R
				tresp_tvalid_w 	<= '1';	--应该是对方（即IP，I端）要写，并且是需要回应的写，因此我们需要发一个包回应，包长为1所以直接tlat置高
				tresp_tlast		<= '1';
			else--在此状态但不是NWRITE_R的处理，不回复数据
				tresp_tvalid_w 	<= '0';
				tresp_tlast		<= '0';
			end if;
			tresp_tdata		<= TID & x"d04000"&x"00000000";--NWRITE_R的回复指定格式
			tresp_tkeep		<= x"ff";
			tresp_tuser		<= self_id & TUSER(15 downto 0);--将自己的id和接受到TUSER低16位拼接
		when sDbResp =>--收到DB需要回复
			tresp_tvalid_w 	<= '1';	
			tresp_tlast		<= '1';
			tresp_tdata		<= TID & x"d04000"&x"00000000";
			tresp_tkeep		<= x"ff";
			tresp_tuser		<= self_id & TUSER(15 downto 0);--逻辑与上述一致（所以上述的回复也是一个DB	）
		when sNrdRespHead =>--NREAD RESPOND的包头响应
			tresp_tvalid_w 	<= '1';	
			tresp_tlast		<= '0';--因为还要发送数据包，所以不last
			tresp_tdata		<= TID & x"d84000"&x"00000000";
			tresp_tkeep		<= x"ff";
			tresp_tuser		<= self_id & TUSER(15 downto 0);	
		when sNrdRespData =>--NREAD RESPOND的数据响应
			tresp_tvalid_w 	<= '1';	
			tresp_tdata		<= RA_data_rd;
			tresp_tkeep		<= x"ff";
			tresp_tuser		<= self_id & TUSER(15 downto 0);
			if ( cntsNrdRespData>=(SIZE(7 downto 3)) ) then--数到最后一个就拉高
				tresp_tlast	<= '1';
			else
				tresp_tlast	<= '0';
			end if;	
		when others =>
			tresp_tvalid_w 	<= '0';
			tresp_tlast		<= '0';
			tresp_tdata		<= x"0000000000000000";
			tresp_tkeep		<= x"ff";
			tresp_tuser		<= self_id & TUSER(15 downto 0);
		end case;
	end process;
	tresp_tvalid <= tresp_tvalid_w;
	--应该相当于assign,应该是这个值还要在其他地方使用，因为VHDL定义的out类型不能在构造体内部使用，除非定义为buffer
	--这一点和verilog不同，详见【参考书p30】
	

	
	--AXI控制逻辑这块不太看得懂???
	RAstart_logic: process(clk) begin if rising_edge(clk) then
		if ( state=sNrdRAaxi and cntsNrdRAaxi<x"3" ) then 
			RAstart<='1';
		else 
			RAstart<='0'; 
		end if;
	end if; end process;
	RAcount <= x"00000020";--输出恒定值
	RAaddr_logic: process(clk) begin if rising_edge(clk) then
		RAaddr <= ADDR(31 downto 0);
	end if; end process;

	RA_addr_logic: process( state, tresp_tvalid_w, tresp_tready, cntsNrdRespData ) begin
		if ( state=sNrdRespHead or state=sNrdRespHead2 ) then
			RA_addr <= x"00";--以上两个state置0
		elsif ( tresp_tvalid_w='1' and tresp_tready='1' ) then
			RA_addr <= cntsNrdRespData+1;--回送数据计数器和地址之间的映射关系
		else
			RA_addr <= cntsNrdRespData+1;
		end if;
	end process;
	
	WA_ram_logic: process(clk) begin
	if rising_edge(clk) then
		case state is
		when sNswrGetData =>
			if ( treq_tvalid='1' and treq_tready_w='1' ) then
				WA_wren 	<= "1";
			else
				WA_wren 	<= "0";
			end if;
			WA_addr		<= cntTrans;
			WA_data_wr	<= treq_tdata;
		when others =>
			WA_addr		<= x"00";
			WA_wren 		<= "0";
			WA_data_wr	<= x"0000000000000000";
		end case;
	end if;
	end process;
	WA_ctrl_logic: process(clk) begin
	if rising_edge(clk) then
		case state is
		when sNswrWA2axi =>
			if ( cntsNswrWA2axi<=x"3") then
				WAstart <= '0';
			else
				WAstart <= '1';			
			end if;
			WAcount <= x"000000"&cntTrans;
			WAaddr	<= ADDR(31 downto 0);
		when sNswrWAwaitdone =>
			WAstart <= '0';
			WAcount <= x"000000"&cntTrans;
			WAaddr	<= ADDR(31 downto 0);
		when others =>
			WAstart <= '0';
			WAcount <= x"00000000";
			WAaddr 	<= x"00000000";
		end case;
	end if;
	end process;	
	--!!!DB的FIFO控制逻辑
	db_fifo_logic: process(clk) begin if rising_edge(clk) then
		if ( state=sDbWrInfo ) then
			db_fifo_wren <= '1';--使能FIFO写
			--db_fifo_data <= x"00" & TID & ADDR(31 downto 16) & TUSER;
			db_fifo_data <= x"00" & TID & DBINFO & TUSER;--FIFO写数据包装{补充的位宽8，TID位宽8，DBINFO位宽16，TUSER位宽32}=1个包
		else
			db_fifo_wren <= '0';
			db_fifo_data <= x"0000000000000000";
		end if;
	end if; end process;




	
	--状态转换逻辑
	----------------------------------------------------------------------------	
	FSM_StateChange_logic: process(clk) begin if rising_edge(clk) then
	if ( rst='1' or linkup='0' ) then
		state <= sReset;
	else
		case state is
		when sReset =>
			state <= sIdle;
		when sIdle =>
			state <= sWaitHead;
		when sWaitHead =>
			if (treq_tvalid='1' and treq_tready_w='1') then
				state <= sGotHead;
			else
				state <= state;
			end if;
		when sGotHead =>
			if ( regLast='1' ) then
				if ( FTYPE=x"2" ) then
					state <= sNrdRAaxi;
				elsif ( FTYPE=x"a" ) then
					state <= sDbWrInfo;
				else
					state <= sIdle;
				end if;
			else
				if ( FTYPE=x"5" or FTYPE=x"6" ) then
					state <= sNswrGetData;
				else
					state <= sIdle;
				end if;		
			end if;
		when sNswrGetData =>
			if (treq_tvalid='1' and treq_tready_w='1' and treq_tlast='1') then
				state <= sNswrResp;
			else
				state <= state;
			end if;
		when sNswrResp =>
			if ( tresp_tready='1' ) then
				state <= sNswrWA2axi;
			else
				state <= state;
			end if;
		when sNswrWA2axi =>
			if ( cntsNswrWA2axi>=x"6" ) then
				state <= sNswrWAwaitdone;
			else
				state <= state;
			end if;
		when sNswrWAwaitdone =>
			if ( WAidle='1' ) then
				state <= sNswrFinish;
			else
				state <= state;
			end if;
		when sNswrFinish =>
			state <= sIdle;
		when sNrdRAaxi =>
			if ( cntsNrdRAaxi>=x"6") then
				state <= sNrdRAwaitdone;
			else
				state <= state;
			end if;
		when sNrdRAwaitdone =>
			if ( RAidle='1' ) then
				state <= sNrdRespHead;
			else
				state <= state;
			end if;
		when sNrdRespHead =>
			if ( tresp_tready='1' ) then
				state <= sNrdRespHead2;
			else
				state <= state;
			end if;
		when sNrdRespHead2 =>
			state <= sNrdRespData;
		when sNrdRespData =>
			if ( cntsNrdRespData>=(SIZE(7 downto 3)) and tresp_tready='1' and tresp_tvalid_w='1') then
				state <= sNrdFinish;
			else
				state <= state;
			end if;
		when sNrdFinish =>
			state <= sIdle;
		when sDbWrInfo =>
			state <= sDbResp;
		when sDbResp =>
			if ( tresp_tready='1' ) then
				state <= sDbFinish;
			else
				state <= state;
			end if;
		when sDbFinish =>
			state <= sIdle;
		when others =>
			state <= sReset;
		end case;
	end if;
	end if; end process;

	--assist logic------------------------------------------------------
	treq_tready_w_logic: process(state) begin
		case state is
		when sWaitHead | sNswrGetData =>
			treq_tready_w <= '1';
		when others =>
			treq_tready_w <= '0';
		end case;
	end process;
	treq_tready <= treq_tready_w;	
	regReqHead_logic: process(clk) begin
	if rising_edge(clk) then
		if ( state=sReset or state=sIdle ) then
			regReqHead <= x"0000000000000000";
		elsif ( state=sWaitHead and treq_tvalid='1' ) then
			regReqHead <= treq_tdata;
		else
			regReqHead <= regReqHead;
		end if;
	end if; end process;
	TID_FTYPE_TTYPE_SIZE_ADDR_TUSER_logic: process(clk) begin
	if rising_edge(clk) then
		if ( state=sReset or state=sIdle ) then
			TID		<= x"00";
			FTYPE	<= x"0";
			TTYPE	<= x"0";
			SIZE	<= x"00";
			ADDR	<= "00"&x"00000000";
			DBINFO  <= x"0000";
			TUSER	<= x"00000000";
			regLast <= '0';
		elsif ( state=sWaitHead and treq_tvalid='1' ) then
			TID		<= treq_tdata(63 downto 56);
			FTYPE	<= treq_tdata(55 downto 52);--FTYPE译码
			TTYPE	<= treq_tdata(51 downto 48);
			SIZE	<= treq_tdata(43 downto 36);
			--ADDR	<= treq_tdata(33 downto 0);
			ADDR(33 downto 32) <= treq_tdata(33 downto 32);--ADDR重定向
			if    (treq_tdata(31 downto 16)>=maping1_base and treq_tdata(31 downto 16)<=maping1_high) then
                ADDR(31 downto 0) <= treq_tdata(31 downto 0)-(maping1_base&x"0000")+maping1_target;
            elsif (treq_tdata(31 downto 16)>=maping2_base and treq_tdata(31 downto 16)<=maping2_high) then
                ADDR(31 downto 0) <= treq_tdata(31 downto 0)-(maping2_base&x"0000")+maping2_target;
            else
                ADDR(31 downto 0) <= treq_tdata(31 downto 0);
            end if;
            DBINFO  <= treq_tdata(31 downto 16);
			TUSER	<= treq_tuser;
			regLast <= treq_tlast;	
		else
			TID		<= TID;
			FTYPE	<= FTYPE;
			TTYPE	<= TTYPE;
			SIZE	<= SIZE;
			ADDR	<= ADDR;
			DBINFO  <= DBINFO;
			TUSER	<= TUSER;
			regLast <= regLast;
		end if;
	end if; end process;
	cntsNswrWA2axi_logic: process(clk) begin
	if rising_edge(clk) then
		if ( state=sNswrWA2axi ) then
			cntsNswrWA2axi <= cntsNswrWA2axi + 1;
		else
			cntsNswrWA2axi <= x"0";
		end if;
	end if; end process;
	cntsNrdRAaxi_logic: process(clk) begin
	if rising_edge(clk) then
		if ( state=sNrdRAaxi ) then
			cntsNrdRAaxi <= cntsNrdRAaxi + 1;
		else
			cntsNrdRAaxi <= x"0";
		end if;
	end if; end process;	
	cntTrans_logic: process(clk) begin
	if rising_edge(clk) then	
		if ( state=sNswrGetData ) then
			if (treq_tvalid='1' and treq_tready_w='1') then
				cntTrans <= cntTrans + 1;
			else
				cntTrans <= cntTrans;
			end if;
		elsif ( state=sNswrResp or state=sNswrWA2axi or state=sNswrWAwaitdone or state=sNswrFinish ) then
			cntTrans <= cntTrans;
		else
			cntTrans <= x"00";
		end if;
	end if;
	end process;
	cntsNrdRespData_logic: process(clk) begin if rising_edge(clk) then
		if ( state=sNrdRespData and tresp_tvalid_w='1' and tresp_tready='1') then
			cntsNrdRespData <= cntsNrdRespData+1;
		elsif ( state=sNrdRAaxi or state=sNrdRAwaitdone or state=sNrdRespHead  ) then
			cntsNrdRespData <= x"00";
		else
			cntsNrdRespData <= cntsNrdRespData;
		end if;
	end if; end process;

end Behavioral;
