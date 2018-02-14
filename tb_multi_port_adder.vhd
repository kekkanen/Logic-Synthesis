

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

entity tb_multi_port_adder is
	generic (
		operand_width_g : integer := 3
	);
 end tb_multi_port_adder;
 
architecture testbench of tb_multi_port_adder is

	-- testipenkin vakiot
	constant period_c 			: TIME := 10 ns;
	constant num_of_operands_g 	: integer := 4;
	constant duv_delay_c 		: integer := 2;
	
	-- tiedostot io:ta varten
	file input_f 		: text open read_mode is "input.txt";
	file ref_results_f 	: text open read_mode is "ref_results.txt";
	file output_f 		: text open write_mode is "output.txt";
	
	component multi_port_adder
		generic (
			operand_width_g 	: integer;
			num_of_operands_g 	: integer
		);
		port (
			clk, rst_n 	: in std_logic;
			operands_in : in std_logic_vector(operand_width_g*num_of_operands_g-1 downto 0);
			sum_out 	: out std_logic_vector(operand_width_g-1 downto 0)
		);
	end component;
	
	signal clk 			: std_logic := '0';
	signal rst_n 		: std_logic := '0';
	signal operands_r 	: std_logic_vector(operand_width_g*num_of_operands_g-1 downto 0);
	signal sum 			: std_logic_vector(operand_width_g-1 downto 0);
	signal output_valid_r : std_logic_vector(duv_delay_c downto 0);

begin -- testbench

	
	mpa : multi_port_adder
		generic map (
			operand_width_g 	=> operand_width_g,
			num_of_operands_g 	=> num_of_operands_g
		)
		port map (
			clk 		=> clk,
			rst_n 		=> rst_n,
			operands_in => operands_r,
			sum_out 	=> sum
		);
		
	rst_n <= '1' after 4*period_c;
		
	-- prosessi kellosignaalin luomiseen
	clk_gen : process (clk)
	begin  -- process clk_gen
		clk <= not clk after period_c/2;
	end process clk_gen;
	
	-- prosessi inputtien lukemiseen
	input_reader : process(clk, rst_n)
		
		variable line_in : line;
		variable input_tmp : integer;
		variable upper_limit, lower_limit : integer;
		
		-- taulukko syötteiden talteenottamista varten. ei tosin käytössä nyt
		type signed_array is array (num_of_operands_g-1 downto 0) of signed(operand_width_g-1 downto 0);
		variable us_array : signed_array;
		
		
		
	begin -- input_reader
	
	
		if rst_n = '0' then
			
			operands_r 		<= (others => '0');
			output_valid_r 	<= (others => '0');
			-- sum <= (others => '0');
		
		elsif clk'event and clk = '1' then
			
			-- shiftataan rekisteriä 
			output_valid_r(0) <= '1';
			output_valid_r(1) <= output_valid_r(0);
			output_valid_r(2) <= output_valid_r(1);
			
			-- jos ei olla tiedoston lopussa, luetaan siitä rivi
			if not endfile(input_f) then
			
				readline(input_f, line_in);
				for i in 1 to num_of_operands_g loop
				
					-- sijoitetaan tiedostosta luettuja numeroita operands_r-vektoriin 
					-- komponenttiin sijoittamiseksi
					upper_limit := i*operand_width_g-1;
					lower_limit := (i-1)*operand_width_g;
					read(line_in, input_tmp);
					operands_r(upper_limit downto lower_limit) <= std_logic_vector(to_signed(input_tmp,3));
				
				end loop;
				
			end if;
		end if;
	end process input_reader;
	
	checker : process(clk, rst_n)
		variable ref 		: integer;
		variable refl, outl : line;
	begin -- checker
	
		if rst_n = '0' then
			
			
		elsif clk'event and clk = '1' then
			
			if output_valid_r(duv_delay_c) = '1' then
				
				if not endfile(ref_results_f) then
					readline(ref_results_f, refl);
					-- for i in 1 to num_of_operands_g loop
						read(refl, ref);
						-- jos tulokset eivät täsmää, simulaatio lopetetaan
						assert to_signed(ref, 3) = signed(sum) report "Checking failed: values don't match!" severity failure;
						
						
					-- end loop;
					
					-- kirjoitetaan komponentin summa output.txt:hen
					write(outl, to_integer(signed(sum)));
					writeline(output_f, outl);
				else 
				assert false report "Simulation ended successfully." severity failure;
				end if;
				
			end if;
			
		
		end if;
		
	
	end process checker;
		
end testbench;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
