library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_config is 
	
	generic (
		ref_clk_freq_g 	: integer := 50000000;
		i2c_freq_g 		: integer := 20000;
		n_params_g 		: integer := 10
		);
	
	port (
		clk 				: in std_logic;
		rst_n 				: in std_logic;
		sdat_inout 			: inout std_logic;
		sclk_out 			: out std_logic;
		param_status_out 	: out std_logic_vector(n_params_g-1 downto 0);
		finished_out 		: out std_logic := '0'
		);

end i2c_config;

architecture rtl of i2c_config is 

	type state_type is (prep_start, start, send_byte, prep_ack, read_ack, prep_stop, stop);
	
	signal curr_state_r : state_type;
	
	-- counter and its max value for generating the sclk
	signal sclk_counter_r		: integer;
	constant sclk_control_max_c : integer := ref_clk_freq_g / (2*i2c_freq_g);
	
	-- constants for slave address and values
	constant write_bit 			: std_logic := '0';
	constant address 			: std_logic_vector(6 downto 0) := "0011010";
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
	
	-- signals for clock and data
	signal sclk			: std_logic;
	signal sdat_r		: std_logic;
	signal sclk_control : std_logic; -- control signal
	
	-- Previous values of the I2C signals for edge detection
	signal sdat_old_r 	: std_logic;
	signal sclk_old_r 	: std_logic;

	-- counters for transferring
	signal bit_counter		: integer;
	signal byte_counter 	: integer;
	signal transfer_counter : integer;
	
	constant bits_max_c 	: integer := 7;
	constant bytes_max_c	: integer := 3;
	
	-- vector to store the next byte to be sent
	signal transfer_byte_r 	: std_logic_vector(7 downto 0);
	
	-- type and signal for an array of values
	type value_array is array(9 downto 0) of std_logic_vector(7 downto 0);
	signal value_array_s : value_array;
	
begin

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

	sclk_out <= sclk;

	sclk_gen : process(clk, rst_n)
	
	begin
	
		if rst_n = '0' then
		
			sclk <= '1';
			sclk_control <= '1';
			sclk_counter_r <= 0;
		
		elsif rising_edge(clk) then
			
			
			
			sclk_counter_r <= sclk_counter_r + 1;
			if sclk_counter_r = sclk_control_max_c/2 then
			
				sclk <= sclk_control;
				
			elsif sclk_counter_r = sclk_control_max_c then
				sclk_control <= not sclk_control;
				sclk_counter_r <= 0;
			end if;
			
			if curr_state_r = stop or curr_state_r = prep_start or
				curr_state_r = start then
				sclk <= '1';
			end if;
			
		end if;
		
	end process;
	
	fsm : process(clk, rst_n)
	
	begin
		
		if rst_n = '0' then
		
			
			sdat_old_r <= '0';
			sclk_old_r <= '1';
			
			sdat_inout <= '1';
	
			curr_state_r <= prep_start;
			param_status_out <= (others => '0');
			
			bit_counter  		<= bits_max_c;
			byte_counter 		<= 0;
			transfer_counter 	<= 0;
		
		elsif rising_edge(clk) then
		
			-- The previous values are required for the edge detection
			sclk_old_r <= sclk_control;
			sdat_old_r <= sdat_inout;
		
			--
			if byte_counter = 0 then
							
				-- have to send slave address and write bit,
				-- assign them to transfer_byte_r
				transfer_byte_r <= address & write_bit;
				
			elsif byte_counter = 1 then
				
				-- send slave register address, 
				transfer_byte_r <= std_logic_vector(to_unsigned(transfer_counter, 7)) & '0';
				
			else
				-- get byte from array
				transfer_byte_r <= value_array_s(transfer_counter);
				
			end if;
			
			case curr_state_r is
			
				
				when prep_start =>
				
					if sclk_control = '0' and sclk_old_r = '1' then
						curr_state_r <= start;
					end if;
					
				when start 		=>
					if sclk_control = '0' and sclk_old_r = '1' then
						curr_state_r <= send_byte;
						sdat_inout 		<= '0';
					end if;
				when send_byte 	=>
					
					if sclk_control = '1' and sclk_old_r = '0' then
					
						sdat_inout <= transfer_byte_r(bit_counter);
						if bit_counter = 0 then 
							curr_state_r <= prep_ack;
							-- sdat_inout <= 'Z';
							bit_counter <= bits_max_c;
						else
							bit_counter <= bit_counter - 1;
						end if;
					end if;
					
					
				when prep_ack	=>
					
					if sclk_control = '1' and sclk_old_r = '0' then
						curr_state_r <= read_ack;
						sdat_inout <= 'Z';
					end if;
				
				when read_ack 	=>
				
					if sclk_control = '0' and sclk_old_r = '1' then
						if sdat_inout = '1' then
							-- nack received
							byte_counter <= 0;
							curr_state_r <= prep_stop;
					
						elsif sdat_inout = '0' then
							-- ack received
							if byte_counter = 2 then -- if 3 bytes written
								curr_state_r <= prep_stop;
								byte_counter <= 0;
								param_status_out(transfer_counter) <= '1';
								transfer_counter <= transfer_counter + 1;
							else
								-- increment byte counter and send new byte
								byte_counter <= byte_counter + 1;
								curr_state_r <= send_byte;
							end if;
						end if;
					end if;
				
				when prep_stop 	=>
				
					if sclk_control = '0' and sclk_old_r = '1' then
						curr_state_r <= stop;
						sdat_inout <= '0';
					end if;
					
				when stop 		=>
				
					if sclk_control = '0' and sclk_old_r = '1' then
					
						if transfer_counter /= 10 then
							curr_state_r <= prep_start;
							sdat_inout <= '1';
						else
							finished_out <= '1';
						end if;
					end if;
				
			end case;
			
		end if;
	end process;
	


end rtl;