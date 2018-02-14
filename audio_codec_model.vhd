-------------------------------------------------------------------------------
-- Title     	: TIE-50206, Exercise 09
-- Project		: 
-------------------------------------------------------------------------------
-- File			: audio_codec_model.vhd
-- Authors		: Jukka Ilmanen, Tommi Lehtonen
-- Company		: TUT/DCS
-- Created    	: 2016-1-28
-- Platform   	: 
-- Standard	: VHDL
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_codec_model is
	generic (
		data_width_g : integer := 16
	);
	
	port (
		rst_n 			: in std_logic;
		aud_data_in   	: in std_logic;
		aud_bclk_in   	: in std_logic;
		aud_lrclk_in 	: in std_logic;
		value_left_out 	: out std_logic_vector(data_width_g-1 downto 0);
		value_right_out : out std_logic_vector(data_width_g-1 downto 0)
	);
end audio_codec_model;

architecture rtl of audio_codec_model is

	-- max value for a position in a data_width_g-bit vector
	constant pos_max_c : integer := data_width_g-1;
	
	-- type for states
	type state_type is (read_left, read_right, wait_for_input);
	
	signal curr_state_r : state_type; -- current state
	
	-- registers to store the left/right outputs
	signal value_left_r, value_right_r : std_logic_vector(data_width_g-1 downto 0);
	
	-- vector to store the input data
	signal input_r 		: std_logic_vector(data_width_g-1 downto 0);
	signal position_r	: integer; -- indicates the current position in the input_r vector
	
	signal lrclk_old_r 	: std_logic;

begin

	
	value_left_out 	<= value_left_r;
	value_right_out <= value_right_r;

	--
	-- process for handling the state switch between read_left and read_right
	--
	lr_state_switch : process(aud_lrclk_in, rst_n)
	
	begin
	
		if rst_n = '0' then
			curr_state_r <= wait_for_input;	-- init state
		elsif aud_lrclk_in = '1' then
			curr_state_r <= read_left;
		else
			curr_state_r <= read_right;
		end if;
		
	end process;
	
	--
	-- handles the position of input vector to which aud_data_in is written
	--
	position_reg	: process(aud_bclk_in, aud_lrclk_in, rst_n)
	
	begin
		
		if rst_n = '0' then
			position_r <= pos_max_c;
		elsif falling_edge(aud_bclk_in) then
		
			-- position maxed when lrclk changes, keeps it in sync
			if aud_lrclk_in = '1' and lrclk_old_r = '0' then
			
				position_r <= pos_max_c;
				
			elsif aud_lrclk_in = '0' and lrclk_old_r = '1' then
			
				position_r <= pos_max_c;
				
			else
				if position_r = 0 then
				
					position_r <= pos_max_c;
					
				else position_r <= position_r - 1;
				end if;
			end if;
		end if;
	end process;
	
	--
	-- the state machine process that handles outputs and other logic
	--
	codec_fsm : process(aud_bclk_in, aud_lrclk_in, rst_n)
		
	begin
		
		if rst_n = '0' then
		
			value_left_r 	<= (others => '0');
			value_right_r 	<= (others => '0');
			lrclk_old_r		<= '0';
			input_r 		<= (others => '0');
		
		elsif rising_edge(aud_bclk_in) then
		
			-- store the current value of aud_lrclk_in for
			-- edge detection
			lrclk_old_r <= aud_lrclk_in;
			
			
			
			-- read a bit from aud_data_in to a vector
			input_r(position_r) <= aud_data_in;
			
			case curr_state_r is
			
				-- if current state is wait_for_input, nothing will be done
				when wait_for_input =>
				
					-- position_r <= pos_max_c;
					
				when read_left =>					
					
					-- the state is changed to read_left, so we store the input_r
					-- vector into value_right_r
					if lrclk_old_r = '0' and aud_lrclk_in = '1' then
						value_right_r <= input_r;
					end if;
					
				when read_right =>
					
					-- as above, but vice versa
					if lrclk_old_r = '1' and aud_lrclk_in = '0' then
						value_left_r <= input_r;
					end if;
					
			end case;
		end if;
	end process;
end rtl;