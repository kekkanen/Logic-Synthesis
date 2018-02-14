-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 03
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Authors     : Jukka Ilmanen, Tommi Lehtonen
-- Company    : TUT/DCS
-- Created    : 2016-11-15
-- Platform   : 
-- Standard   : VHDL
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
	generic (
		operand_width_g : integer
	);
	port (
		clk, rst_n 		: in std_logic;
		a_in, b_in 		: in std_logic_vector(operand_width_g-1 downto 0);
		sum_out 		: out std_logic_vector(operand_width_g downto 0)
	);
end adder;

architecture rtl of adder is

	-- tyyppiä signed oleva signaali tulokselle
	signal olli : signed(operand_width_g downto 0);

begin
	
	-- yhdistetään rekisterisignaali ulostuloon
	sum_out <= std_logic_vector(olli);
	
	-- kellosignaalista ja resetistä riippuva prosessi
	process(clk, rst_n)
	variable ebin : integer; -- välimuuttuja summalle a_in + b_in
	
	begin
		if (rst_n ='0') then
			-- resetoidaan jokainen rekisterin biteistä asynkronisesti
			olli <= (others => '0');
		
		-- kellon nousevalla reunalla
		elsif (clk'event and clk = '1') then
			
			-- summataan a_in ja b_in, sekä suoritetaan tarvittavat tyyppimuunnokset
			ebin := to_integer(signed(a_in)) + to_integer(signed(b_in));
			olli <= to_signed(ebin, operand_width_g+1);
			
		end if;
	end process;
	
end rtl;
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			