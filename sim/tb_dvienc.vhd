library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity tb_dvienc is
end entity tb_dvienc;

architecture rtl of tb_dvienc is

component dvienc is port (
	clk_i: in std_logic;
	reset_i: in std_logic;

	sda:	out std_logic;
	scl:	out std_logic);
end component;


signal clk_s		: std_logic := '0';
signal reset_s		: std_logic := '1';
begin

dut: dvienc port map(
	clk_i		=> clk_s,
	reset_i		=> reset_s);

clkgen: process
begin
	wait for 16.666 ns;
	clk_s <= '1';
	wait for 16.666 ns;
	clk_s <= '0';
end process;

main: process
begin
	reset_s <= '1';
	wait for 10 ns;
	reset_s <= '0';
	wait;
end process;


end rtl;
