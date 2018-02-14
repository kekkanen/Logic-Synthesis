-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 03
-- Project    : 
-------------------------------------------------------------------------------
-- File       : multi_port_adder.vhd
-- Authors     : Jukka Ilmanen, Tommi Lehtonen
-- Company    : TUT/DCS
-- Created    : 2016-11-15
-- Platform   : 
-- Standard   : VHDL
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multi_port_adder is
	generic (
		operand_width_g 	: integer := 16;
		num_of_operands_g 	: integer := 4
	);
	port (
		clk, rst_n 	: in std_logic;
		operands_in : in std_logic_vector(operand_width_g*num_of_operands_g-1 downto 0);
		sum_out 	: out std_logic_vector(operand_width_g-1 downto 0)
	);
end multi_port_adder;

architecture structural of multi_port_adder is
	
	component adder
		generic (
			operand_width_g : integer
		);
		PORT (
			clk, rst_n 	: in std_logic;
			a_in, b_in 	: in std_logic_vector(operand_width_g-1 downto 0);
			sum_out 	: out std_logic_vector(operand_width_g downto 0)
		);
	end component;
	
	type OLLI is array (num_of_operands_g/2-1 downto 0) of std_logic_vector(operand_width_g downto 0);
	signal subtotal : OLLI;
	signal total : std_logic_vector(operand_width_g+1 downto 0);
	
begin  
		A0 : adder
			generic map (
				operand_width_g => operand_width_g	
			)
			port map (
				clk => clk,
				rst_n => rst_n,
				a_in => operands_in(operand_width_g - 1 downto 0),
				b_in => operands_in(2 * operand_width_g - 1 downto operand_width_g),
				sum_out => subtotal(0)
			);
		A1 : adder
			generic map (
				operand_width_g => operand_width_g
			)
			port map (
				clk => clk,
				rst_n => rst_n,
				a_in => operands_in(3 * operand_width_g - 1 downto 2 * operand_width_g),
				b_in => operands_in(4 * operand_width_g - 1 downto 3 * operand_width_g),
				sum_out => subtotal(1)
			);
		A2 : adder
			generic map (
				operand_width_g => operand_width_g + 1
			)
			port map (
				clk => clk,
				rst_n => rst_n,
				a_in => subtotal(0),
				b_in => subtotal(1),
				sum_out => total
			);
		sum_out <= total(operand_width_g - 1 downto 0);

		assert num_of_operands_g = 4 report "ebin" severity failure;
	
end structural;
							   
