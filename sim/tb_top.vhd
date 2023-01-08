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
	clk200_p		: in std_logic;
	clk200_n		: in std_logic;
	reset_sw_i		: in std_logic;

	dvi_de			: out std_logic;
	dvi_d			: out std_logic_vector(11 downto 0);
	dvi_v			: out std_logic;
	dvi_h			: out std_logic;
	dvi_xclk_p		: out std_logic;
	dvi_xclk_n		: out std_logic;
	dvi_reset_b		: out std_logic;

	led			: out std_logic_vector(7 downto 0);

	ps2_key_i		: in std_logic_vector(10 downto 0);

	-- config values
	dram_size		: in std_logic_vector(2 downto 0);

	-- ps2 keyboard
	ps2_clk_i		: in std_logic;
	ps2_data_i		: in std_logic;

	sram_flash_a		: out std_logic_vector(21 downto 0);
	sram_flash_d		: inout std_logic_vector(15 downto 0);
	sram_flash_we_b		: out std_logic;
	flash_clk		: out std_logic;
	flash_ce_b		: out std_logic;
	flash_oe_b		: out std_logic;
	sram_mode		: out std_logic;
	sram_oe_b		: out std_logic;

	-- DDR2 RAM
	ddr2_dq			: inout std_logic_vector(63 downto 0);
	ddr2_a			: out std_logic_vector(13 downto 0);
	ddr2_ba			: out std_logic_vector(2 downto 0);
	ddr2_ras_n		: out std_logic;
	ddr2_cas_n		: out std_logic;
	ddr2_we_n		: out std_logic;
	ddr2_cs_n		: out std_logic_vector(1 downto 0);
	ddr2_odt		: out std_logic_vector(1 downto 0);
	ddr2_cke		: out std_logic_vector(1 downto 0);
	ddr2_dm			: out std_logic_vector(7 downto 0);
	ddr2_dqs		: inout std_logic_vector(7 downto 0);
	ddr2_dqs_n		: inout std_logic_vector(7 downto 0);
	ddr2_ck			: out std_logic_vector(1 downto 0);
	ddr2_ck_n		: out std_logic_vector(1 downto 0));
end component;

component ddr2_model is port (
	ck:		in std_logic;
	ck_n:		in std_logic;
	cke:		in std_logic;
	cs_n:		in std_logic;
	ras_n:		in std_logic;
	cas_n:		in std_logic;
	we_n:		in std_logic;
	dm_rdqs:	inout std_logic_vector(1 downto 0);
	ba:		in std_logic_vector(1 downto 0);
	addr:		in std_logic_vector(12 downto 0);
	dq:		inout std_logic_vector(15 downto 0);
	dqs:		inout std_logic_vector(1 downto 0);
	dqs_n:		inout std_logic_vector(1 downto 0);
	rdqs_n:		out std_logic_vector(7 downto 0);
	odt:		in std_logic
);
end component;

component bootrom is port(
	clk_i: in std_logic;
	addr_i:	in std_logic_vector(15 downto 0);
	data_o:	out std_logic_vector(15 downto 0);
	oe_n_i:	std_logic;
	cs_n_i:	std_logic);
end component;

component basicrom is port(
	addr : in std_logic_vector(19 downto 0);
	data : out std_logic_vector(15 downto 0)
);
end component;

signal clk_s			: std_logic := '0';
signal clk200_s			: std_logic := '0';
signal reset_s			: std_logic := '1';
signal clk_pixel_s		: std_logic := '0';
signal hsync_s			: std_logic;
signal vsync_s			: std_logic;
signal dvi_de_s			: std_logic;
signal dvi_d_s			: std_logic_vector(11 downto 0);
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
signal ps2_clk_s		: std_logic := '1';
signal ps2_data_s		: std_logic := '1';
signal dram_size_s		: std_logic_vector(2 downto 0) := "000";

signal bootrom_addr_s		: std_logic_vector(21 downto 0);
signal bootrom_data_s		: std_logic_vector(15 downto 0);
signal bootrom_cs_s		: std_logic;
signal bootrom_oe_s		: std_logic;
signal basicrom_addr_s		: std_logic_vector(19 downto 0);
signal basicrom_data_s		: std_logic_vector(15 downto 0);

signal data_switch_s		: std_logic;

signal ddr2_a_s		: std_logic_vector(13 downto 0);
signal ddr2_ba_s	: std_logic_vector(2 downto 0);
signal ddr2_ras_n_s	: std_logic;
signal ddr2_cas_n_s	: std_logic;
signal ddr2_we_n_s	: std_logic;
signal ddr2_cs_n_s	: std_logic_vector(1 downto 0);
signal ddr2_cke_s	: std_logic_vector(1 downto 0);
signal ddr2_dm_s	: std_logic_vector(7 downto 0);
signal ddr2_dq_s	: std_logic_vector(63 downto 0);
signal ddr2_dqs_s	: std_logic_vector(7 downto 0);
signal ddr2_dqs_n_s	: std_logic_vector(7 downto 0);
signal ddr2_rdqs_s	: std_logic_vector(1 downto 0);
signal ddr2_ck_s	: std_logic_vector(1 downto 0);
signal ddr2_ck_n_s	: std_logic_vector(1 downto 0);
signal ddr2_odt_s	: std_logic_vector(1 downto 0);

begin

dut: hp300 port map(
	clk_i => clk_s,
	clk200_n => not clk200_s,
	clk200_p => clk200_s,
	reset_sw_i => reset_s,
	dvi_v => vsync_s,
	dvi_h => hsync_s,
	dvi_de => dvi_de_s,
	dvi_d => dvi_d_s,
	ps2_key_i => ps2_key_s,
	dram_size => dram_size_s,
	led => led_s,
	ps2_clk_i => ps2_clk_s,
	ps2_data_i => ps2_data_s,
	sram_flash_a => bootrom_addr_s,
	sram_flash_d => bootrom_data_s,
	flash_ce_b => bootrom_cs_s,
	flash_oe_b => bootrom_oe_s,
	ddr2_dq => ddr2_dq_s,
	ddr2_a => ddr2_a_s,
	ddr2_ba => ddr2_ba_s,
	ddr2_ras_n => ddr2_ras_n_s,
	ddr2_cas_n => ddr2_cas_n_s,
	ddr2_we_n => ddr2_we_n_s,
	ddr2_cs_n => ddr2_cs_n_s,
	ddr2_odt => ddr2_odt_s,
	ddr2_cke => ddr2_cke_s,
	ddr2_dm => ddr2_dm_s,
	ddr2_dqs => ddr2_dqs_s,
	ddr2_dqs_n => ddr2_dqs_n_s,
	ddr2_ck => ddr2_ck_s,
	ddr2_ck_n => ddr2_ck_n_s
--	phy_init_done => phy_init_done
	);


gen_dram: for i in 0 to 3 generate
	ddr2_model_i: ddr2_model port map(
		ck => ddr2_ck_s(0),
		ck_n => ddr2_ck_n_s(0),
		cke => ddr2_cke_s(0),
		cs_n => ddr2_cs_n_s(0),
		ras_n => ddr2_ras_n_s,
		cas_n => ddr2_cas_n_s,
		we_n => ddr2_we_n_s,
		dm_rdqs => ddr2_dm_s((2 * (i + 1)) - 1 downto i * 2),
		ba => ddr2_ba_s(1 downto 0),
		addr => ddr2_a_s(12 downto 0),
		dq => ddr2_dq_s((16 * (i + 1)) - 1 downto i * 16),
		dqs => ddr2_dqs_s((2  * (i + 1)) - 1 downto i * 2),
		dqs_n => ddr2_dqs_n_s((2  * (i + 1)) - 1 downto i * 2),
		rdqs_n => open,
		odt => ddr2_odt_s(0)
);
end generate gen_dram;

bootrom_i: bootrom port map(
	clk_i => clk_s,
	addr_i => bootrom_addr_s(15 downto 0),
	data_o => bootrom_data_s,
	oe_n_i => bootrom_oe_s,
	cs_n_i => bootrom_cs_s);

clkgen: process
begin
	clk_s <= '0';
	wait for 16.6666666 ns;
	clk_s <= '1';
	wait for 16.6666666 ns;
end process;

clk200gen: process
begin
	clk200_s <= '0';
	wait for 2.5 ns;
	clk200_s <= '1';
	wait for 2.5 ns;
end process;

resetgen: process
variable delaycnt: integer := 0;
variable bytecnt: integer := 0;
begin
	reset_s <= '1';
	wait for 200 us;
	reset_s <= '0';
	wait;
end process;

end tb;
