library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.ALL;

entity dvienc is port (
	clk_i: in std_logic;
	reset_i: in std_logic;

	sda:	out std_logic;
	scl:	out std_logic);
end entity dvienc;

architecture rtl of dvienc is

type bitstate is (IDLE, START, CLOCK_LOW, DATA, CLOCK_HIGH, ACK_LOW, ACK_BIT, ACK_HIGH, STOP_LOW, STOP_MID, STOP_HIGH, DONE);

type initentry is array (0 to 7) of std_logic_vector(0 to 23);
signal state: bitstate;
constant initentries: initentry := (
	x"ec" & x"1c" & x"00", -- 1x clk mode
	x"ec" & x"1f" & x"80", -- input data format
	x"ec" & x"21" & x"09", -- horizontal sync out
	x"ec" & x"48" & x"18", -- disable reset, no test pattern
	x"ec" & x"49" & x"c0", -- disable power down
	x"ec" & x"33" & x"06", -- > 75MHz clock
	x"ec" & x"34" & x"26", -- > 75MHz clock
	x"ec" & x"36" & x"a0"  -- > 75MHz clock
	);
signal i2c_clk: std_logic;
signal bitcnt: integer;
signal initcnt: integer;
begin

clkdiv: process(reset_i, clk_i)
	variable count: integer;
begin
	if (reset_i = '1') then
		count := 0;
		i2c_clk <= '0';
	elsif rising_edge(clk_i) then
		if (count < 333) then
			count := count + 1;
		else
			i2c_clk <= not i2c_clk;
			count := 0;
		end if;
	end if;
end process;

shift: process(reset_i, i2c_clk)
	variable delay: integer;
begin
	if (reset_i = '1') then
		scl <= '1';
		sda <= '1';
		initcnt <= 0;
		bitcnt <= 0;
		delay := 0;
		state <= IDLE;
	elsif (rising_edge(i2c_clk)) then
	case state is
		when IDLE =>
			scl <= '1';
			sda <= '1';
			if (delay < 2048) then
				delay := delay + 1;
			else
				delay := 0;
				state <= START;
			end if;
		when START =>
			scl <= '1';
			sda <= '0';
			state <= CLOCK_LOW;
			bitcnt <= 0;
		when CLOCK_LOW =>
			scl <= '0';
			state <= DATA;
		when DATA =>
			sda <= initentries(initcnt)(bitcnt);
			bitcnt <= bitcnt + 1;
			state <= CLOCK_HIGH;
		when CLOCK_HIGH =>
			scl <= '1';
			if (bitcnt mod 8 = 0) then
				state <= ACK_LOW;
			else
				state <= CLOCK_LOW;
			end if;
		when ACK_LOW =>
			scl <= '0';
			state <= ACK_BIT;
		when ACK_BIT =>
			sda <= '1';
			state <= ACK_HIGH;
		when ACK_HIGH =>
			scl <= '1';
			if (bitcnt = initentries(initcnt)'length) then
				state <= STOP_LOW;
			else
				state <= CLOCK_LOW;
			end if;
		when STOP_LOW =>
			scl <= '0';
			state <= STOP_MID;
		when STOP_MID =>
			sda <= '0';
			state <= STOP_HIGH;
		when STOP_HIGH =>
			scl <= '1';
			if (initcnt = 8) then
				state <= DONE;
			else
				initcnt <= initcnt + 1;
				state <= IDLE;
			end if;
		when DONE =>
			sda <= '1';
			scl <= '1';
	end case;
	end if;
end process;
end rtl;
