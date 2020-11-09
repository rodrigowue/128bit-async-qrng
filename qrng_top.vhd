------------------------------------------------------------------------------------------
--#File TRNG_top.vhd
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

entity TRNG_top is
	port (hold_in: in std_logic;
		   rst: in std_logic;
		   clk : in STD_LOGIC;-- 100Mhz clock on Basys 3 FPGA board
         an : out STD_LOGIC_VECTOR (3 downto 0);-- 4 Anode signals
         freq : out STD_LOGIC;-- 4 Anode signals
         led : out STD_LOGIC_VECTOR (6 downto 0));-- Cathode patterns of 7-ledment display);
end TRNG_top;

architecture interface of TRNG_top is
signal hold,reset,middle_freq: std_logic := '0';
signal random: std_logic_vector(127 downto 0);
signal displayed_number: STD_LOGIC_VECTOR (15 downto 0);
signal LED_BCD: STD_LOGIC_VECTOR (3 downto 0);
signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0);
signal LED_activating_counter: std_logic_vector(1 downto 0);
begin

reset <= rst;
freq <= middle_freq;

hold <= hold_in;
process(hold)
begin
if(hold='1')then
displayed_number <= random (15 downto 0);
end if;
end process;


process(LED_BCD)
begin
    case LED_BCD is
    when "0000" => led <= "0000001"; -- "0"     
    when "0001" => led <= "1001111"; -- "1" 
    when "0010" => led <= "0010010"; -- "2" 
    when "0011" => led <= "0000110"; -- "3" 
    when "0100" => led <= "1001100"; -- "4" 
    when "0101" => led <= "0100100"; -- "5" 
    when "0110" => led <= "0100000"; -- "6" 
    when "0111" => led <= "0001111"; -- "7" 
    when "1000" => led <= "0000000"; -- "8"     
    when "1001" => led <= "0000100"; -- "9" 
    when "1010" => led <= "0000010"; -- a
    when "1011" => led <= "1100000"; -- b
    when "1100" => led <= "0110001"; -- C
    when "1101" => led <= "1000010"; -- d
    when "1110" => led <= "0110000"; -- E
    when "1111" => led <= "0111000"; -- F
	 when others => led <= "0000001";
    end case;
end process;


process(clk,rst)
begin 
    if(rst='1') then
        refresh_counter <= (others => '0');
    elsif(rising_edge(clk)) then
        refresh_counter <= refresh_counter + 1;
    end if;
end process;

LED_activating_counter <= refresh_counter(19 downto 18);
 
process(LED_activating_counter)
begin
    case LED_activating_counter is
    when "00" =>
        an <= "0111"; 
        LED_BCD <= displayed_number(15 downto 12);
    when "01" =>
        an <= "1011"; 
        LED_BCD <= displayed_number(11 downto 8);
    when "10" =>
        an <= "1101"; 
        LED_BCD <= displayed_number(7 downto 4);
    when "11" =>
        an <= "1110"; 
        LED_BCD <= displayed_number(3 downto 0);
	 when others =>
	     an <= "0111"; 
        LED_BCD <= displayed_number(15 downto 12);
    end case;
end process;


TRNG: entity work.TRNG
port map (
	hold_in  =>  hold,
	freq => middle_freq,
	reset_in => reset,
	random_out    =>  random
);

end interface;
