library ieee;

use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
entity tb_top is
end entity;

architecture tb of tb_top is
component hp300 is port(
	clk_i			: in std_logic;
	clk2_i			: in std_logic;
	reset_sw_i		: in std_logic;
	clk_pixel_i		: in std_logic;
	ce_pixel_o		: out std_logic;
	hsync_o			: out std_logic;
	vsync_o			: out std_logic;
	vblank_o		: out std_logic;
	hblank_o		: out std_logic;
	r_o			: out std_logic_vector(7 downto 0);
	g_o			: out std_logic_vector(7 downto 0);
	b_o			: out std_logic_vector(7 downto 0);
	led			: out std_logic_vector(7 downto 0);
	ps2_key_i		: in std_logic_vector(10 downto 0);
	dram_size		: in std_logic_vector(2 downto 0));
end component;

component bootrom is port(
	clk_i  : in std_logic;
	addr_i : in std_logic_vector(14 downto 0);
	data_o : out std_logic_vector(31 downto 0)
);
end component;

component basicrom is port(
	addr : in std_logic_vector(19 downto 0);
	data : out std_logic_vector(15 downto 0)
);
end component;

signal clk_s			: std_logic := '0';
signal clk2_s			: std_logic := '0';
signal reset_s			: std_logic := '1';
signal clk_pixel_s		: std_logic := '0';
signal hsync_s			: std_logic;
signal vsync_s			: std_logic;
signal hblank_s			: std_logic;
signal vblank_s			: std_logic;
signal vsync_old_s		: std_logic;
signal hsync_old_s		: std_logic;
signal vblank_old_s		: std_logic;
signal hblank_old_s		: std_logic;
signal ce_pixel_old_s		: std_logic;
signal g_s			: std_logic_vector(7 downto 0);

signal led_s			: std_logic_vector(7 downto 0);
signal ps2_key_s		: std_logic_vector(10 downto 0) := (others => '0');

signal dram_size_s		: std_logic_vector(2 downto 0) := "000";

signal bootrom_addr_s		: std_logic_vector(16 downto 0);
signal bootrom_data_s		: std_logic_vector(31 downto 0);

signal basicrom_addr_s		: std_logic_vector(19 downto 0);
signal basicrom_data_s		: std_logic_vector(15 downto 0);


signal data_switch_s		: std_logic;

begin

dut: hp300 port map(
	clk_i => clk_s,
	clk2_i => clk2_s,
	reset_sw_i => reset_s,
	clk_pixel_i => clk_pixel_s,
	vsync_o => vsync_s,
	hsync_o => hsync_s,
	vblank_o => vblank_s,
	hblank_o => hblank_s,
	g_o => g_s,
	ps2_key_i => ps2_key_s,
	dram_size => dram_size_s,
	led => led_s);

clkgen: process
begin
	clk2_s <= '0';
	clk_s <= '0';
	wait for 5 ns;
	clk2_s <= '1';
	wait for 5 ns;
	clk2_s <= '0';
	clk_s <= '1';
	wait for 5 ns;
	clk2_s <= '1';
	wait for 5 ns;
end process;

pixclkgen: process
begin
	clk_pixel_s <= '0';
	wait for 7.8125 ns;
	clk_pixel_s <= '1';
	wait for 7.8125 ns;
end process;

resetgen: process
variable delaycnt: integer := 0;
variable bytecnt: integer := 0;
begin
	reset_s <= '1';
	wait for 500 ns;
	reset_s <= '0';
	wait;
end process;

screenw: process(clk_pixel_s)
	file file_video: text;
	variable row: line;
	variable hdr: line;
	variable fileopen: std_logic := '0';
begin
	vsync_old_s <= vsync_s;
	hblank_old_s <= hblank_s;

	if hblank_s = '0' and vblank_s = '0' and clk_pixel_s = '1' then
		if (g_s = x"ff") then
			write(row, string'("0"));
		else
			write(row, string'("1"));
		end if;
		if hblank_s = '0' and hblank_old_s = '1' then
			write(row, string'("\n"));
		end if;
	end if;

	if vsync_s = '1' and vsync_old_s = '0' then
		file_open(file_video, "video.txt", write_mode);
		write(hdr, string'("P1 1024 768"));
		writeline(file_video, hdr);
		writeline(file_video, row);
		file_close(file_video);
	end if;
end process;

end tb;
