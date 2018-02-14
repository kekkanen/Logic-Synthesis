-------------------------------------------------------------------------------
-- Title     	: TIE-50206, Exercise 06
-- Project		: 
-------------------------------------------------------------------------------
-- File			: wave_gen.vhd
-- Authors		: Jukka Ilmanen, Tommi Lehtonen
-- Company		: TUT/DCS
-- Created    	: 2016-12-8
-- Platform   	: 
-- Standard	: VHDL
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wave_gen is
	generic(
		width_g 	: integer;
		step_g 		: integer
	);
	
	port(
		clk, rst_n 		: in std_logic;
		sync_clear_in  	: in std_logic;		
		value_out 		: out std_logic_vector(width_g-1 downto 0)
	);
end wave_gen;

architecture structural of wave_gen is

	-- vakiot arvon ylä- ja alarajalle
	-- min = -1 * max
	constant max : signed := to_signed(((2**(width_g-1)-1) / step_g) * step_g, width_g);
	constant min : signed := to_signed(-1, width_g) * max;
	
	-- signaali arvolle, joka yhdistetään output-porttiin value_out
	signal value_out_r : signed(width_g-1 downto 0);
	
	begin
	
		-- yhdistetään value_out signaaliin value_out_r sopivalla yksikkömuunnoksella
		value_out <= std_logic_vector(value_out_r);
	
		---------------------------------------------------------------------------------------------------
		--! PROSESSI
		---------------------------------------------------------------------------------------------------
		wave_gen : process(clk, rst_n)
		
		-- kerroin arvon lisäämiselle/vähentämiselle
		-- arvo noudattaa kaavaa sign * step + value_out_r
		-- jossa sign on -1 tai 1
		variable sign : integer := 1;
			begin
			
				if rst_n = '0' then
				
					-- resetissä
					sign := 1;
					value_out_r  <= (others => '0');
				
				elsif clk'event and clk = '1' then
				
				
					if sync_clear_in = '1' then
					
						-- sync_clear_in ylhäällä
					
						sign := 1;
						value_out_r  <= (others => '0');
					
					else 
					
						-- saa laskea
						if value_out_r = max then
							
							sign := -1;
							
						
						elsif value_out_r = min then
							
							sign := 1;
							
						end if;
						
						-- vähennetään/lisätään step ja
						-- muutetaan oikeaan leveyteen
						value_out_r <= resize(value_out_r + (to_signed(sign, width_g) * to_signed(step_g, width_g)), width_g);
					end if;
					
				end if;
			end process;
	

end structural;	






