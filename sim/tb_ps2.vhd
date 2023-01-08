library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
entity tb_ps2 is
end entity;

architecture tb of tb_ps2 is

component ps2_keyb is port (
	clk_i		: in std_logic;
	reset_i		: in std_logic;
	ps2_clk_i	: in std_logic;
	ps2_data_i	: in std_logic;
	rx_ack_i	: in std_logic;
	rx_rdy_o	: out std_logic;
	rx_data_o	: out std_logic_vector(7 downto 0)
);
end component;

signal clk_s		: std_logic;
signal reset_s		: std_logic;
signal ps2_clk_s	: std_logic;
signal ps2_data_s	: std_logic;
signal rx_ack_s		: std_logic;
signal rx_rdy_s		: std_logic;
signal rx_rdy_old_s	: std_logic;
signal rx_data_s	: std_logic_vector(7 downto 0);

procedure ps2_tx(constant data_s: in STD_LOGIC_VECTOR(7 downto 0);
		 signal ps2_clk_s: out STD_LOGIC;
		 signal ps2_data_s: out STD_LOGIC) is
        variable parity_v : std_logic := '1';
begin
	ps2_clk_s <= '1';
	ps2_data_s <= '1';
	wait for 5 us;
	ps2_data_s <= '0';
	wait for 20 us;
	ps2_clk_s <= '0';
	wait for 40 us;
	ps2_clk_s <= '1';
	wait for 20 us;
	for i in 0 to (data_s'length - 1) loop
		ps2_data_s <= data_s(i);
		if(data_s(i) = '1') then
			parity_v := not parity_v;
		end if;
		wait for 20 us;
		ps2_clk_s <= '0';
		wait for 40 us;
		ps2_clk_s <= '1';
		wait for 20 us;
	end loop;
	ps2_data_s <= parity_v;
	wait for 20 us;
	ps2_clk_s <= '0';
	wait for 40 us;
	ps2_clk_s <= '1';
	wait for 20 us;
	ps2_data_s <= '1';
	wait for 20 us;
	ps2_clk_s <= '0';
	wait for 40 us;
	ps2_clk_s <= '1';
	wait for 20 us;
end procedure;

begin

ps2_keyb_i: ps2_keyb port map(
	clk_i => clk_s,
	reset_i => reset_s,
	ps2_clk_i => ps2_clk_s,
	ps2_data_i => ps2_data_s,
	rx_ack_i => rx_ack_s,
	rx_rdy_o => rx_rdy_s,
	rx_data_o => rx_data_s
);

resetgen: process
begin
	reset_s <= '1';
	wait for 100 us;
	reset_s <= '0';
	wait;
end process;

clkgen: process
begin
	clk_s <= '0';
	wait for 10 ns;
	clk_s <= '1';
	wait for 10 ns;
end process;

ack: process(clk_s)
begin
	if (rising_edge(clk_s)) then
		    rx_ack_s <= rx_rdy_s;
		    rx_rdy_old_s <= rx_rdy_s;
		    if (rx_rdy_old_s = '0' and rx_rdy_s = '1') then
			    report "rx: " & to_hstring(rx_data_s);
		    end if;
	end if;
end process;
tx: process
begin
	ps2_tx(x"55", ps2_clk_s, ps2_data_s);
	wait for 10 ms;
	ps2_tx(x"aa", ps2_clk_s, ps2_data_s);
	wait for 100 us;
	ps2_tx(x"01", ps2_clk_s, ps2_data_s);
	wait for 10 ms;
	ps2_tx(x"80", ps2_clk_s, ps2_data_s);
	wait for 10 ms;

end process;
end tb;
