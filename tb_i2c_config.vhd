-------------------------------------------------------------------------------
-- Title     	: TIE-50206, Exercise 13
-- Project		: 
-------------------------------------------------------------------------------
-- File			: tb_i2c_config.vhd
-- Authors		: Jukka Ilmanen, Tommi Lehtonen
-- Company		: TUT/DCS
-- Created    	: 2017-2-25
-- Platform   	: 
-- Standard		: VHDL
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Empty entity
-------------------------------------------------------------------------------

entity tb_i2c_config is
end tb_i2c_config;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture testbench of tb_i2c_config is

  -- Number of parameters to expect
  constant n_params_c     : integer := 10;
  constant i2c_freq_c     : integer := 20000;
  constant ref_freq_c     : integer := 50000000;
  constant clock_period_c : time    := 20 ns;
  
	-- config values
	constant left_line_in 		: std_logic_vector(7 downto 0) := "00011010";
	constant right_line_in 		: std_logic_vector(7 downto 0) := "00011010";
	constant left_headphone_out : std_logic_vector(7 downto 0) := "01111011";
	constant right_headphone_out: std_logic_vector(7 downto 0) := "01111011";
	constant aap_ctlr 			: std_logic_vector(7 downto 0) := "11111000";
	constant dap_ctrl 			: std_logic_vector(7 downto 0) := "00000110";
	constant power_down_ctrl 	: std_logic_vector(7 downto 0) := "00000000";
	constant dai_format 		: std_logic_vector(7 downto 0) := "00000001";
	constant sampling_ctrl 		: std_logic_vector(7 downto 0) := "00000010";
	constant active_ctrl 		: std_logic_vector(7 downto 0) := "00000001";
	
	type value_array is array(9 downto 0) of std_logic_vector(7 downto 0);
	signal value_array_s : value_array;

  -- Every transmission consists several bytes and every byte contains given
  -- amount of bits. 
  constant n_bytes_c       : integer := 3;
  constant bit_count_max_c : integer := 8;

  -- Signals fed to the DUV
  signal clk   : std_logic := '0';  -- Remember that default values supported
  signal rst_n : std_logic := '0';      -- only in synthesis

  -- The DUV prototype
  component i2c_config
    generic (
      ref_clk_freq_g : integer;
      i2c_freq_g     : integer;
      n_params_g     : integer);
    port (
      clk              : in    std_logic;
      rst_n            : in    std_logic;
      sdat_inout       : inout std_logic;
      sclk_out         : out   std_logic;
      param_status_out : out   std_logic_vector(n_params_g-1 downto 0);
      finished_out     : out   std_logic
      );
  end component;

  -- Signals coming from the DUV
  signal sdat         : std_logic := 'Z';
  signal sclk         : std_logic;
  signal param_status : std_logic_vector(n_params_c-1 downto 0);
  signal finished     : std_logic;

  -- To hold the value that will be driven to sdat when sclk is high.
  signal sdat_r : std_logic;

  -- Counters for receiving bits and bytes
	signal bit_counter_r  		: integer range 0 to bit_count_max_c-1;
	signal byte_counter_r		: integer range 0 to n_bytes_c-1;
	signal transfer_counter_r 	: integer range 0 to n_params_c-1;

  -- States for the FSM
  type   states is (wait_start, read_byte, send_ack, wait_stop);
  signal curr_state_r : states;

  -- Previous values of the I2C signals for edge detection
  signal sdat_old_r : std_logic;
  signal sclk_old_r : std_logic;
  
	-- is nack sent
	signal nack_sent 		: boolean := false;
	signal transfer_byte 	: std_logic_vector(bit_count_max_c-1 downto 0);
	
	constant address : std_logic_vector(6 downto 0) := "0011010";
  
begin  -- testbench

	value_array_s(0) <= left_line_in;
	value_array_s(1) <= right_line_in;
	value_array_s(2) <= left_headphone_out;
	value_array_s(3) <= right_headphone_out;
	value_array_s(4) <= aap_ctlr;
	value_array_s(5) <= dap_ctrl;
	value_array_s(6) <= power_down_ctrl;
	value_array_s(7) <= dai_format;
	value_array_s(8) <= sampling_ctrl;
	value_array_s(9) <= active_ctrl;

	clk   <= not clk after clock_period_c/2;
	rst_n <= '1'     after clock_period_c*4;

  -- Assign sdat_r when sclk is active, otherwise 'Z'.
  -- Note that sdat_r is usually 'Z'
  with sclk select
    sdat <=
		sdat_r when '1',
		'Z'    when others;


  -- Component instantiation
  i2c_config_1 : i2c_config
    generic map (
      ref_clk_freq_g => ref_freq_c,
      i2c_freq_g     => i2c_freq_c,
      n_params_g     => n_params_c)
    port map (
      clk              => clk,
      rst_n            => rst_n,
      sdat_inout       => sdat,
      sclk_out         => sclk,
      param_status_out => param_status,
      finished_out     => finished);

  -----------------------------------------------------------------------------
  -- The main process that controls the behavior of the test bench
  fsm_proc : process (clk, rst_n)
  
	variable nack_counter : integer := 0;
	
  begin  -- process fsm_proc
    if rst_n = '0' then                 -- asynchronous reset (active low)

      curr_state_r <= wait_start;

      sdat_old_r <= '0';
      sclk_old_r <= '0';

      byte_counter_r <= 0;
      bit_counter_r  <= 0;
	  transfer_counter_r <= 0;
	  
	  transfer_byte <= "00000000";

      sdat_r <= 'Z';
      
    elsif clk'event and clk = '1' then  -- rising clock edge

      -- The previous values are required for the edge detection
      sclk_old_r <= sclk;
      sdat_old_r <= sdat;


      -- Falling edge detection for acknowledge control
      -- Must be done on the falling edge in order to be stable during
      -- the high period of sclk
      if sclk = '0' and sclk_old_r = '1' then

        -- If we are supposed to send ack
        if curr_state_r = send_ack then

			if not nack_sent then
			
				if nack_counter = 11 then
				
					sdat_r 			<= '1';
					nack_sent 		<= true;
					nack_counter 	:= 0;
					
				else 
				
					-- Send ack (low = ACK, high = NACK)
					sdat_r <= '0';
					nack_counter := nack_counter + 1;

				end if;
			end if;
        else

			-- Otherwise, sdat is in high impedance state.
			sdat_r <= 'Z';
          
        end if;
        
      end if;


      -------------------------------------------------------------------------
      -- FSM
      case curr_state_r is

        -----------------------------------------------------------------------
        -- Wait for the start condition
        when wait_start =>

			--While clk stays high, the sdat falls
			--if sclk = '1' and sclk_old_r = '1' and
			--sdat_old_r = '1' and sdat = '0' then

			if sclk = '0' and sclk_old_r = '1' and
			sdat_old_r = '0' and sdat = '0' then
			
			
			
            curr_state_r <= read_byte;

			end if;

          --------------------------------------------------------------------
          -- Wait for a byte to be read
        when read_byte =>

          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then
		  

            if bit_counter_r /= bit_count_max_c-1 then

				
			transfer_byte((bit_count_max_c-1)-bit_counter_r) <= sdat;
				-- Normally just receive a bit
				bit_counter_r <= bit_counter_r + 1;

            else
			
				transfer_byte((bit_count_max_c-1)-bit_counter_r) <= sdat;
				-- When terminal count is reached, let's send the ack
				curr_state_r  <= send_ack;
				bit_counter_r <= 0;
			  
			  
            end if;  -- Bit counter terminal count
            
          end if;  -- sclk rising clock edge

          --------------------------------------------------------------------
          -- Send acknowledge
        when send_ack =>
		

			-- Detect a rising edge
			if sclk = '1' and sclk_old_r = '0' then
            
				-- verify transferred byte
				if byte_counter_r = 0 then
				  
					assert transfer_byte = address & '0'
					report "Transferred address does not match." severity failure;
				
				elsif byte_counter_r = 1 then
				
					assert transfer_byte = std_logic_vector(to_unsigned(transfer_counter_r, 7)) & '0'
					report "Wrong register address." severity failure;
					
				elsif byte_counter_r = 2 then
					
					assert transfer_byte = value_array_s(transfer_counter_r)
					report "Value does not match." severity failure;
					
			end if;
			
			if nack_sent then
			
				byte_counter_r <= 0;
				curr_state_r   <= wait_stop;
				nack_sent <= false;
				
            elsif byte_counter_r /= n_bytes_c-1 then

              -- Transmission continues
				byte_counter_r <= byte_counter_r + 1;
				curr_state_r   <= read_byte;
              
            else

				-- Transmission is about to stop
				byte_counter_r <= 0;
				
				if transfer_counter_r /= 9 then 
					transfer_counter_r <= transfer_counter_r + 1;
				end if;
				
				curr_state_r   <= wait_stop;
				nack_sent <= false;
              
            end if;

          end if;

          ---------------------------------------------------------------------
          -- Wait for the stop condition
        when wait_stop =>

			-- Stop condition detection: sdat rises while sclk stays high
			if sclk = '1' and sclk_old_r = '0' then -- and
				
				-- sdat_old_r = '0' and sdat = '1' then
				curr_state_r <= wait_start;
            
          end if;

      end case;

    end if;
end process fsm_proc;

  -----------------------------------------------------------------------------
  -- Asserts for verification
  -----------------------------------------------------------------------------

  -- SDAT should never contain X:s.
  assert sdat /= 'X' report "Three state bus in state X" severity error;

  -- End of simulation, but not during the reset
   assert finished = '0' report
     "Simulation done" severity failure;
  
end testbench;
