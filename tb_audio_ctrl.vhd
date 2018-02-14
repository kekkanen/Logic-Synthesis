-------------------------------------------------------------------------------
-- Title     	: TIE-50206, Exercise 09
-- Project		: 
-------------------------------------------------------------------------------
-- File			: tb_audio_ctrl.vhd
-- Authors		: Jukka Ilmanen, Tommi Lehtonen
-- Company		: TUT/DCS
-- Created    	: 2016-1-28
-- Platform   	: 
-- Standard	: VHDL
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_audio_ctrl is

	generic (
		width_g : integer := 16;
		step_g 	: integer := 2
	);

end tb_audio_ctrl;

architecture testbench of tb_audio_ctrl is

	-- constants
	constant period_c 			: TIME := 50 ns;
	constant sync_clear_time 	: TIME := 4 ms;

	----------------------------
	-- component declarations --
	----------------------------
	component wave_gen is
		generic(
			width_g : integer;
			step_g 	: integer
		);
		
		port(
			clk, rst_n 		: in std_logic;
			sync_clear_in  	: in std_logic;		
			value_out 		: out std_logic_vector(width_g-1 downto 0)
		);
	end component;
	
	component audio_ctrl is
		generic (
			ref_clk_freq_g 	: integer := 18432000;
			sample_rate_g 	: integer := 48000;
			data_width_g 	: integer := 16
		);
		
		port (
			clk, rst_n 		: in std_logic;
			left_data_in 	: in std_logic_vector(data_width_g-1 downto 0);
			right_data_in	: in std_logic_vector(data_width_g-1 downto 0);
			aud_bclk_out 	: out std_logic;
			aud_data_out 	: out std_logic;
			aud_lrclk_out 	: out std_logic
		);
	end component;
	
	component audio_codec_model is
	generic (
		data_width_g : integer := 16
	);
	
	port (
		rst_n			: in std_logic;
		aud_data_in 	: in std_logic;
		aud_bclk_in 	: in std_logic;
		aud_lrclk_in 	: in std_logic;
		value_left_out 	: out std_logic_vector(data_width_g-1 downto 0);
		value_right_out : out std_logic_vector(data_width_g-1 downto 0)
	);
	end component;
	
	----------------------
	-- internal signals --
	----------------------

	signal clk 			: std_logic := '0';
	signal rst_n		: std_logic := '0';
	signal sync_clear 	: std_logic := '0';
	signal bclk 		: std_logic := '1';
	signal data, lrclk 	: std_logic := '0';
	signal left_data 	: std_logic_vector(width_g-1 downto 0);
	signal right_data 	: std_logic_vector(width_g-1 downto 0);
	
	signal l_data_codec_tb : std_logic_vector(width_g-1 downto 0);
	signal r_data_codec_tb : std_logic_vector(width_g-1 downto 0);
	
begin -- testbench

	--
	-- map all the necessary components to each other.
	--
	
	ctrl : audio_ctrl
		port map (
			clk 			=> clk,
			rst_n 			=> rst_n,
			left_data_in 	=> left_data,
			right_data_in 	=> right_data,
			aud_bclk_out 	=> bclk,
			aud_data_out 	=> data,
			aud_lrclk_out 	=> lrclk			
		);
		

	wave_gen_left : wave_gen
		generic map (
			width_g 		=> width_g,
			step_g 			=> 2
		)
		port map (
			clk 			=> clk,
			rst_n 			=> rst_n,
			sync_clear_in 	=> sync_clear,
			value_out 		=> left_data
		);
	
	wave_gen_right : wave_gen
		generic map (
			width_g 		=> width_g,
			step_g 			=> 10 
		)
		port map (
			clk 			=> clk,
			rst_n 			=> rst_n,
			sync_clear_in 	=> sync_clear,
			value_out 		=> right_data
		);
		
	model : audio_codec_model
		generic map (
			data_width_g 	=> width_g
		)
		port map (
			rst_n 			=> rst_n,
			aud_data_in 	=> data,
			aud_bclk_in 	=> bclk,
			aud_lrclk_in 	=> lrclk,
			value_left_out	=> l_data_codec_tb,
			value_right_out => r_data_codec_tb
		);
	
	
	-- generate clock and reset signals.
	rst_n 		<= '1' after 4*period_c;
	sync_clear 	<= '1' after sync_clear_time, '0' after sync_clear_time + 100 ns;

	clk_gen : process(clk)
	begin  -- process clk_gen
		clk <= not clk after period_c/2;
	end process clk_gen;
	

end testbench;

















