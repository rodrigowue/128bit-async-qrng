------------------------------------------------------------------------------------------
--#File TRNG_tb.vhd
--#Authors: Rodrigo Nogueira Wuerdig
--#         Marcos L. L. Sartori
--#
--#Contact: rodrigo.wuerdig@acad.pucrs.br
------------------------------------------------------------------------------------------
--This Asynchronous Mousetrap Logic TRNG uses Fibonacci LFSRs with a 
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

entity TRNG_tb is
end TRNG_tb;

architecture interface of TRNG_tb is
signal hold,reset,clk: std_logic := '0';
begin

clk <= not(clk) after 5 ns;
hold <= '0', '1' after 500 ns, '0' after 550 ns;
reset <= '1', '0' after 50 ns, '1' after 100 ns, '0' after 150 ns;

TRNG_top: entity work.TRNG_top
port map (
			hold_in => hold,
		   rst => reset,
		   clk => clk,
         an => open,
         freq => open,
         led => open
);

end interface;
