library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ps2_keyb is generic (
	TIMEOUT : INTEGER       := 250
	);
	Port (
		clk_i		: in std_logic;
		reset_i		: in std_logic;
		ps2_clk_i	: in std_logic;
		ps2_data_i	: in std_logic;
		rx_ack_i	: in std_logic;
		rx_rdy_o	: out std_logic;
		rx_data_o	: out std_logic_vector(7 downto 0)
);
end entity ps2_keyb;

architecture rtl of ps2_keyb is

signal ps2_data_old_s	: std_logic;
signal ps2_clk_old_s	: std_logic;
signal ps2_buffer_s	: std_logic_vector(7 downto 0);
signal ps2_parity_s	: std_logic;
signal clk100khz_s	: std_logic;

begin

clkdiv: process(reset_i, clk_i)
	variable cnt: integer;
begin
	if (reset_i = '1') then
		cnt := 0;
		clk100khz_s <= '0';
	elsif (rising_edge(clk_i)) then
		if (cnt < 250) then
			cnt := cnt + 1;
		else
			cnt := 0;
			clk100khz_s <= not clk100khz_s;
		end if;
	end if;
end process;

ps2_shift: process(reset_i, clk100khz_s)
	type ps2_state_t is (START, RECV_BIT, READY);
	variable timeout_v : integer := 0;
	variable state_v: ps2_state_t := START;
	variable bitcnt_v: integer := 0;
begin
	if (reset_i = '1') then
		state_v := START;
	elsif (rising_edge(clk100khz_s)) then
		ps2_clk_old_s <= ps2_clk_i;
		ps2_data_old_s <= ps2_data_i;

		if(ps2_clk_old_s = '1' and ps2_clk_i = '0') then
			timeout_v := 0;
		elsif (timeout_v < TIMEOUT) then
			timeout_v := timeout_v + 1;
		else
			state_v := START;
		end if;

		case state_v is
			when START =>
				rx_rdy_o <= '0';
				if (ps2_clk_i = '0' and ps2_data_i = '0') then
					state_v := RECV_BIT;
					bitcnt_v := 0;
					ps2_parity_s <= '1';
				end if;
			when RECV_BIT =>
				rx_rdy_o <= '0';
				if (ps2_clk_old_s = '1' and ps2_clk_i = '0') then
					if (bitcnt_v < 8) then
						ps2_buffer_s <= ps2_data_i & ps2_buffer_s(7 downto 1);
						if (ps2_data_i = '1') then
							ps2_parity_s <= not ps2_parity_s;
						end if;
						bitcnt_v := bitcnt_v + 1;
					else
						if (ps2_parity_s /= ps2_data_i) then
							state_v := START;
						else
							rx_data_o <= ps2_buffer_s;
							state_v := READY;
						end if;
					end if;
				end if;
			when READY =>
				if(rx_ack_i = '1') then
					state_v := START;
					rx_rdy_o <= '0';
				else
					rx_rdy_o <= '1';
				end if;
		end case;
	end if;
end process;
end rtl;
