------------------------------------------------------------------------------------------
--#File: QRNG.vhd
--#Authors: Rodrigo Nogueira Wuerdig
--#         Marcos L. L. Sartori
--#
--#Contact: rodrigo.wuerdig@acad.pucrs.br
------------------------------------------------------------------------------------------
--This Asynchronous Mousetrap Logic QRNG uses Fibonacci LFSRs with a 
--estimated period of 3.40282366920938463463374607431768211455 × 10^38 Async Cycles
--
--#expression: 
--    X^128 + X^126 + X^101 + X^99 + 1
--
--http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity QRNG is
	generic (DEPTH : integer := 6);
	port (	
		hold_in:	in std_logic;
		freq: out std_logic;
		reset_in:	in std_logic;
		random_out:	out std_logic_vector(127 downto 0));
end QRNG;

architecture interface of QRNG is
signal intermediate: std_logic_vector(127 downto 0) := x"30061173151173993930061173151173";
signal AA, BB, CC: std_logic_vector(1 downto 0);
signal req,req_d: std_logic_vector(3 downto 0):= (others => '0');
signal ack: std_logic_vector(3 downto 0) := (others => '0');
signal fictionalclk: std_logic_vector(3 downto 0):= (others => '0');
type data_path is array (3 downto 0) of std_logic_vector(127 downto 0);
type delay is array (3 downto 0) of std_logic_vector(DEPTH-1 downto 0);
signal delay_lines: delay;
signal random: data_path;

attribute keep : string;
attribute keep of delay_lines : signal is "TRUE";

begin
-----------------------------------------------------------
-----------------------------------------------------------
GEN_DELAY0:for I in 0 to 3 generate
delay_lines(I)(0) <= not(req(I)); --1
GEN_DELAY1:for J in 1 to DEPTH-1 generate
delay_lines(I)(J) <= not(delay_lines(I)(J-1)); --0
end generate GEN_DELAY1;
req_d(I) <= delay_lines(I)(DEPTH-1);
end generate GEN_DELAY0;

--delay_lines(0)(0) <= not(req(0)); --1
--delay_lines(0)(1) <= not(delay_lines(0)(0)); --0
--req_d(0)         <= delay_lines(0)(1); --1

--delay_lines(1)(0) <= not(req(1)); --1
--delay_lines(1)(1) <= not(delay_lines(1)(0)); --0
--req_d(1)         <= delay_lines(1)(1); --1

--delay_lines(2)(0) <= not(req(2)); --1
--delay_lines(2)(1) <= not(delay_lines(2)(0)); --0
--req_d(2)         <= delay_lines(2)(1); --1

--delay_lines(3)(0) <= not(req(3)); --1
--delay_lines(3)(1) <= not(delay_lines(3)(0)); --0
--req_d(3)         <= delay_lines(3)(1); --1

--DELAY LINES
--req_d(0) <= req(0) after 5 ns;
--req_d(1) <= req(1) after 1 ns;
--req_d(2) <= req(2) after 1 ns;
--req_d(3) <= req(3) after 1 ns;

-----------------------------------------------------------
-----------------------------------------------------------
--Before LOGIC BARRIER
-----------------------------------------------------------
ack(0) <= req(0);
process(fictionalclk(0),reset_in,req_d(3),random(3))
begin
if(reset_in='1')then
	random(0) <= x"30061173151173993930061173151173";
	req(0) <= '1';
elsif (fictionalclk(0)='1') then
	req(0)    <= req_d(3);
	random(0) <= random(3);
end if;
end process;
fictionalclk(0) <= (ack(1) xnor req(0));
-----------------------------------------------------------
AA(0) <= random(0)(127) xnor random(0)(125);
-----------------------------------------------------------
--Second and After Logic BARRIER
-----------------------------------------------------------
ack(1) <= (req(1) and not(hold_in));
process(fictionalclk(1),reset_in,req_d(0),AA(0),random(0))
begin
if(reset_in='1') then
	req(1)<='0';
	random(1) <= (others => '0');
	AA(1) <= '0';
elsif(fictionalclk(1)='1') then
	req(1)<=req_d(0);
	random(1) <= random(0);
	AA(1) <= AA(0);
end if;
end process;
fictionalclk(1) <= (ack(2) xnor req(1));
-----------------------------------------------------------
BB(0) <= random(1)(100) xnor AA(1);
-----------------------------------------------------------
-- Third Barrier
-----------------------------------------------------------
ack(2) <= req(2);
process(fictionalclk(2),reset_in,req_d(1),BB(0),random(1))
begin
if(reset_in='1') then
	req(2)<='0';
	random(2) <= (others => '0');
	BB(1) <= '0';
elsif(fictionalclk(2)='1') then
	req(2)<=req_d(1);
	random(2) <= random(1);
	BB(1) <= BB (0);
end if;
end process;
fictionalclk(2) <= (ack(3) xnor req(2));
-----------------------------------------------------------
CC(0) <= random(2)(98) xnor BB(1);
-----------------------------------------------------------
-- Fourth and Last Barrier
-----------------------------------------------------------
ack(3) <= req(3);
process(fictionalclk(3),reset_in,req_d(2),CC(0),random(2))
begin
if(reset_in='1') then
	req(3)<='0';
	intermediate <= (others => '0');
	CC(1) <= '0';
elsif(fictionalclk(3)='1') then
	req(3)<=req_d(2);
	intermediate <= random(2);
	CC(1) <= CC(0);
end if;
end process;
fictionalclk(3) <= (ack(0) xnor req(3));
-----------------------------------------------------------
random(3) <= intermediate(126 downto 0) & CC(1);
-----------------------------------------------------------
--OUTPUT PIN
random_out <= random(3);
freq <= ack(0);
-----------------------------------------------------------
end interface;