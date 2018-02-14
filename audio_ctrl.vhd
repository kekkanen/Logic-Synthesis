-------------------------------------------------------------------------------
-- Title     	: TIE-50206, Exercise 08
-- Project		: 
-------------------------------------------------------------------------------
-- File			: audio_ctrl.vhd
-- Authors		: Jukka Ilmanen, Tommi Lehtonen
-- Company		: TUT/DCS
-- Created    	: 2017-1-28
-- Platform   	: 
-- Standard	: VHDL
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_ctrl is
    generic (
		ref_clk_freq_g 	: integer := 18432000;
		sample_rate_g 	: integer := 48000;
		data_width_g 	: integer := 16
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
end audio_ctrl;

architecture rtl of audio_ctrl is

	constant sample_counter_max : integer := ref_clk_freq_g / sample_rate_g;
	constant bclk_counter_max 	: integer := ref_clk_freq_g / sample_rate_g / (data_width_g * 2) / 2; -- 6
	constant lrclk_counter_max 	: integer := bclk_counter_max * 2 * data_width_g; -- 192
	constant snapshot_width 	: integer := 2 * data_width_g;
	
	signal snapshot_r 	: std_logic_vector(snapshot_width - 1 downto 0);
	signal snapshot_bit : std_logic := '0';
	
	signal dbg_snapshot_left_r : std_logic_vector(snapshot_width/2 - 1 downto 0);
	signal dbg_snapshot_right_r : std_logic_vector(snapshot_width/2 - 1 downto 0);
	
	-- registers for outputs
	signal aud_bclk_r 	: std_logic;
	signal aud_data_r 	: std_logic;
	signal aud_lrclk_r	: std_logic;
	
	signal bclk_old_r	: std_logic;
	signal lrclk_old_r	: std_logic;
	
	signal bclk_counter 	: integer;
	signal lrclk_counter 	: integer;
	signal sample_counter 	: integer;
	signal snapshot_pos 	: integer := snapshot_width - 1; -- Bit iterator
	
	
	
begin -- rtl
	
	aud_bclk_out 	<= aud_bclk_r;	
	aud_data_out 	<= aud_data_r;
	aud_lrclk_out 	<= aud_lrclk_r;
	
	dbg_snapshot_left_r <= snapshot_r(snapshot_width - 1 downto snapshot_width / 2);
	dbg_snapshot_right_r <= snapshot_r(snapshot_width/2 - 1 downto 0);
	
	--
	-- This process concatenates two 16-bit input vectors into one
	-- 32-bit vector. This is done at the rate of aud_lrclk_out (48 kHz)
	-- The vectors' values are written into snapshot_r on lrclk's rising edge
	--
	
	take_snapshot : process(clk, rst_n)
	
	begin
	
		-- At reset.
		if rst_n = '0' then
			snapshot_r <= (others => '0');
			sample_counter <= 0;
		
		-- On the falling edge of clock signal.
		elsif clk'event and clk = '0' then 
				
			if lrclk_old_r = '0' and aud_lrclk_r = '1' then
				snapshot_r <= left_data_in & right_data_in;
			end if;
			
			
			
		end if;
		
	end process;
	
	--
	-- This process generates the lrclk and bclk signal. It is implemented
	-- with counters. When the counter reaches its maximum value, the clock bit is
	-- inverted. Hereby the counters define half of their clock's period length.
	--
	gen_clocks : process(clk, rst_n)
	
	begin -- gen_clocks
		
	
		if rst_n = '0' then
		
			-- lrclk_counter	<= lrclk_counter_max - 2*bclk_counter_max + 1;
			lrclk_counter	<= 1;
			bclk_counter 	<= 1;
			aud_bclk_r 		<= '0';
			aud_lrclk_r		<= '1';
			
		elsif clk'event and clk = '1' then
		
			bclk_old_r 	<= aud_bclk_r;
			lrclk_old_r <= aud_lrclk_r;
			
			-- Counter reaches max value -> signal is inverted
			-- and the counter continues from 1. Otherwise
			-- it is incremented by one.
			if lrclk_counter /= lrclk_counter_max then
				lrclk_counter <= lrclk_counter + 1;
			else
				aud_lrclk_r 	<= not aud_lrclk_r;
				lrclk_counter 	<= 1;
			end if;
			
			-- As above
			if bclk_counter /= bclk_counter_max then
				bclk_counter <= bclk_counter + 1;
			else
				-- bclk bit is inverted and the counter resets to 1.
				aud_bclk_r 		<= not aud_bclk_r;
				bclk_counter 	<= 1;
			end if;
		end if;
	end process;
	
	
	--
	-- This process reads data from the snapshot_r vector and feeds it bit by bit into aud_data_r.
	-- The signal snapshot_pos indicates a bit in the snapshot vector. aud_data_r is updated at
	-- aud_bclk_r falling edge. snapshot_pos is updated at aud_bclk_r rising edge.
	--
	read_data : process(clk, rst_n)
	
	
	begin -- read_data
		
		if rst_n = '0' then
		
			aud_data_r <= '0';
			snapshot_pos <= snapshot_width - 1;
			
		elsif clk'event and clk = '1' then
						
			if bclk_old_r = '0' and aud_bclk_r = '1' then
				
				if snapshot_pos /= 0 then
					snapshot_pos <= snapshot_pos - 1;
				else
					snapshot_pos <= snapshot_width - 1;
				end if;
				
			elsif bclk_old_r = '1' and aud_bclk_r = '0' then
			
				snapshot_bit <= snapshot_r(snapshot_pos);
				aud_data_r <= snapshot_r(snapshot_pos);
				
			end if;
			
			-- special case to synchronize snapshot_pos with lrclk.
			if aud_lrclk_r = '1' and lrclk_old_r = '0' then
				snapshot_pos <= snapshot_width - 1;
			end if;
		end if;
	end process;
		
end rtl;









