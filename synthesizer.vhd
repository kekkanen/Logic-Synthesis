-------------------------------------------------------------------------------
-- Title     	: TIE-50206, Exercise 10
-- Project		: 
-------------------------------------------------------------------------------
-- File			: synthesizer.vhd
-- Authors		: Jukka Ilmanen, Tommi Lehtonen
-- Company		: TUT/DCS
-- Created    	: 2017-1-28
-- Platform   	: 
-- Standard	: VHDL
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity synthesizer is
	
	generic (
		clk_freq_g 		: integer := 18432000;
		sample_rate_g 	: integer := 48000;
		data_width_g 	: integer := 16;
		n_keys_g 		: integer := 4
	);
	
	port (
		clk 			: in std_logic;
		rst_n 			: in std_logic;
		keys_in 		: in std_logic_vector(n_keys_g-1 downto 0);
		aud_bclk_out 	: out std_logic;
		aud_lrclk_out 	: out std_logic;
		aud_data_out 	: out std_logic
	);
end synthesizer;

architecture structural of synthesizer is

	component wave_gen
		generic (
			width_g 	: integer;
			step_g 		: integer
		);
		port (
			clk, rst_n 		: in std_logic;
			sync_clear_in  	: in std_logic;		
			value_out 		: out std_logic_vector(width_g-1 downto 0)
		);
	end component;
	
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
	
	component audio_ctrl
		generic (
			ref_clk_freq_g 	: integer;
			sample_rate_g 	: integer;
			data_width_g 	: integer
		);
	
		port (
			clk 			: in std_logic;
			rst_n			: in std_logic;
			left_data_in 	: in std_logic_vector(data_width_g-1 downto 0);
			right_data_in 	: in std_logic_vector(data_width_g-1 downto 0);
			aud_bclk_out 	: out std_logic;
			aud_data_out 	: out std_logic;
			aud_lrclk_out 	: out std_logic
		);
	end component;
	
	constant operands_width_c : integer := data_width_g * n_keys_g;
	
	signal wave0_s		: std_logic_vector(data_width_g-1 downto 0);
	signal wave1_s		: std_logic_vector(data_width_g-1 downto 0);
	signal wave2_s		: std_logic_vector(data_width_g-1 downto 0);
	signal wave3_s		: std_logic_vector(data_width_g-1 downto 0);
	signal sum_out_s	: std_logic_vector(data_width_g-1 downto 0);
	signal operands_s 	: std_logic_vector(operands_width_c-1 downto 0);

begin

	wave0 : wave_gen
		generic map (
			width_g => data_width_g,
			step_g 	=> 1
		)
		port map (
			clk 			=> clk,
			rst_n 			=> rst_n,
			sync_clear_in 	=> keys_in(0),
			value_out		=> wave0_s
		);
	
	wave1 : wave_gen
		generic map (
			width_g => data_width_g,
			step_g 	=> 1
		)
		port map (
			clk 			=> clk,
			rst_n 			=> rst_n,
			sync_clear_in 	=> keys_in(1),
			value_out		=> wave1_s
		);
		
	wave2 : wave_gen
		generic map (
			width_g => data_width_g,
			step_g 	=> 1
		)
		port map (
			clk 			=> clk,
			rst_n 			=> rst_n,
			sync_clear_in 	=> keys_in(2),
			value_out		=> wave2_s
		);
	
	wave3 : wave_gen
		generic map (
			width_g => data_width_g,
			step_g 	=> 1
		)
		port map (
			clk 			=> clk,
			rst_n 			=> rst_n,
			sync_clear_in 	=> keys_in(3),
			value_out		=> wave3_s
		);
	
	-- all the wave signals combined into a 64-bit vector
	-- operands_s <= wave3_s & wave2_s & wave1_s & wave0_s;
	operands_s <= wave0_s & wave1_s & wave2_s & wave3_s;

	
	mpa : multi_port_adder
		generic map (
			operand_width_g 	=> data_width_g,
			num_of_operands_g	=> n_keys_g
		)
		port map (
			clk 		=> clk,
			rst_n 		=> rst_n,
			operands_in => operands_s,
			sum_out 	=> sum_out_s
		);
	
	audio : audio_ctrl
		generic map (
			ref_clk_freq_g 	=> clk_freq_g,
			sample_rate_g  	=> sample_rate_g,
			data_width_g	=> data_width_g
		)
		port map (
			clk				=> clk,
			rst_n			=> rst_n,
			left_data_in	=> sum_out_s,
			right_data_in	=> sum_out_s,
			aud_bclk_out	=> aud_bclk_out,
			aud_data_out	=> aud_data_out,
			aud_lrclk_out	=> aud_lrclk_out
		);
		
end structural;





























