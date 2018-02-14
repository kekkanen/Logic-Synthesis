-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 02
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ripple_carry_adder.vhd
-- Author     : Jukka Ilmanen
-- Company    : TUT/DCS
-- Created    : 2016-11-10
-- Platform   : 
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description: Sums two 3-bit values
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;


entity ripple_carry_adder is
	port (
		a_in, b_in 	: in std_logic_vector(2 downto 0);
		s_out 		: out std_logic_vector(3 downto 0)
	);
end ripple_carry_adder;

architecture gate of ripple_carry_adder is

	signal Carry_ha, Carry_fa 	: std_logic;
	signal C, D, E, F, G, H 	: std_logic;
  
begin  

	-- Signals named according to the circuit diagram in the exercise info

	-- Half adder
	s_out(0) <= a_in(0) xor b_in(0);
	Carry_ha <= a_in(0) and b_in(0);
	
	-- Full adder
	C 			<= a_in(1) xor b_in(1);
	s_out(1) 	<= C xor Carry_ha;
    D 			<= Carry_ha and C;
	E 			<= a_in(1) and b_in(1);
	Carry_fa 	<= D or E;
	
	-- Full adder 2
	F 			<= a_in(2) xor b_in(2);
	s_out(2) 	<= F xor Carry_fa;
	G 			<= Carry_fa and F;
	H 			<= a_in(2) and b_in(2);
	s_out(3) 	<= G or H;
	
end gate;
