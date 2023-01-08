library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
library unisim;
use unisim.vcomponents.all;
entity fb is port (
	clk_i		: in std_logic;
	clk_pixel_p_o	: out std_logic;
	clk_pixel_n_o	: out std_logic;
	reset_i		: in std_logic;
	de		: out std_logic;
	hsync_o		: out std_logic;
	vsync_o		: out std_logic;
	data_o		: out std_logic_vector(11 downto 0);

	db_i		: in std_logic_vector(15 downto 0);
	db_o		: out std_logic_vector(15 downto 0);
	addr_i		: in std_logic_vector(19 downto 0);
	vram_cs_i	: in std_logic;
	rwn_i		: in std_logic;
	rdy_o		: out std_logic;
	udsn_i		: in std_logic;
	ldsn_i		: in std_logic;
	ctl_cs_i	: in std_logic);
end entity fb;

architecture rtl of fb is

component topcat is port (
	clk_i		: in std_logic;
	clk_pixel_i	: in std_logic;
	reset_i		: in std_logic;
	hblank_o	: out std_logic;
	vblank_o	: out std_logic;
	hsync_o		: out std_logic;
	vsync_o		: out std_logic;
	video_o		: out std_logic;
	db_i		: in std_logic_vector(15 downto 0);
	db_o		: out std_logic_vector(15 downto 0);
	addr_i		: in std_logic_vector(19 downto 0);
	vram_cs_i	: in std_logic;
	ctl_cs_i	: in std_logic;
	rwn_i		: in std_logic;
	rdy_o		: out std_logic;
	udsn_i		: in std_logic;
	ldsn_i		: in std_logic);
end component;

component PLL_BASE is
generic (
	BANDWIDTH : string := "OPTIMIZED";
	CLKFBOUT_MULT : integer := 1;
	CLKFBOUT_PHASE : real := 0.0;
	CLKIN_PERIOD : real := 0.000;
	CLKOUT0_DIVIDE : integer := 1;
	CLKOUT0_DUTY_CYCLE : real := 0.5;
	CLKOUT0_PHASE : real := 0.0;
	CLKOUT1_DIVIDE : integer := 1;
	CLKOUT1_DUTY_CYCLE : real := 0.5;
	CLKOUT1_PHASE : real := 0.0;
	CLKOUT2_DIVIDE : integer := 1;
	CLKOUT2_DUTY_CYCLE : real := 0.5;
	CLKOUT2_PHASE : real := 0.0;
	CLKOUT3_DIVIDE : integer := 1;
	CLKOUT3_DUTY_CYCLE : real := 0.5;
	CLKOUT3_PHASE : real := 0.0;
	CLKOUT4_DIVIDE : integer := 1;
	CLKOUT4_DUTY_CYCLE : real := 0.5;
	CLKOUT4_PHASE : real := 0.0;
	CLKOUT5_DIVIDE : integer := 1;
	CLKOUT5_DUTY_CYCLE : real := 0.5;
	CLKOUT5_PHASE : real := 0.0;
	CLK_FEEDBACK : string := "CLKFBOUT";
	COMPENSATION : string := "SYSTEM_SYNCHRONOUS";
	DIVCLK_DIVIDE : integer := 1;
	REF_JITTER : real := 0.100;
	RESET_ON_LOSS_OF_LOCK : boolean := FALSE);
port (
	CLKFBOUT : out std_ulogic;
	CLKOUT0 : out std_ulogic;
	CLKOUT1 : out std_ulogic;
	CLKOUT2 : out std_ulogic;
	CLKOUT3 : out std_ulogic;
	CLKOUT4 : out std_ulogic;
	CLKOUT5 : out std_ulogic;
	LOCKED : out std_ulogic;
	CLKFBIN : in std_ulogic;
	CLKIN : in std_ulogic;
	RST : in std_ulogic
);
end component;

signal video_s		: std_logic;
signal hblank_s		: std_logic;
signal vblank_s		: std_logic;
signal dvi_d24		: std_logic_vector(23 downto 0);
signal clk_pixel_s	: std_logic;
signal pll_fb_s		: std_logic;
signal pll_clk0_s	: std_logic;
begin

de <= not hblank_s and not vblank_s;

dvi_d24 <= x"ffffff" when video_s = '1' else (others => '0');

videopll: PLL_BASE generic map(
		CLKFBOUT_MULT => 10,
		CLKOUT0_DIVIDE => 8,
		CLKIN_PERIOD => 20.0
	)
	port map(
		RST => reset_i,
		CLKIN => clk_i,
		CLKFBIN => pll_fb_s,
		CLKFBOUT => pll_fb_s,
		CLKOUT0 => pll_clk0_s
	);

clk0_bufg: BUFG port map(
	I => pll_clk0_s,
	O => clk_pixel_s
);

clkds: OBUFDS port map(
	I => clk_pixel_s,
	O => clk_pixel_p_o,
	OB => clk_pixel_n_o
);

gen_oddr: for i in 0 to 11 generate
	oddr_i : ODDR generic map(
		DDR_CLK_EDGE => "OPPOSITE_EDGE",	-- "OPPOSITE_EDGE" or "SAME_EDGE"
		INIT => '0',				-- Initial value for Q port ('1' or '0')
		SRTYPE => "SYNC"			-- Reset Type ("ASYNC" or "SYNC")
		)
		port map (Q => data_o(i),	-- 1-bit DDR output
			  C => not clk_pixel_s,	-- 1-bit clock input
			  CE => '1',		-- 1-bit clock enable input
			  D1 => dvi_d24(i+12),	-- 1-bit data input (positive edge)
			  D2 => dvi_d24(i),	-- 1-bit data input (negative edge)
			  R => '0',		-- 1-bit reset input
			  S => '0'		-- 1-bit set input
			  );
end generate;

topcat_i: topcat port map(
	clk_i		=> clk_i,
	clk_pixel_i	=> clk_pixel_s,
	reset_i		=> reset_i,
	hblank_o	=> hblank_s,
	vblank_o	=> vblank_s,
	hsync_o		=> hsync_o,
	vsync_o		=> vsync_o,
	video_o		=> video_s,
	db_i		=> db_i,
	db_o		=> db_o,
	addr_i		=> addr_i,
	vram_cs_i	=> vram_cs_i,
	ctl_cs_i	=> ctl_cs_i,
	rwn_i		=> rwn_i,
	rdy_o		=> rdy_o,
	udsn_i		=> udsn_i,
	ldsn_i		=> ldsn_i);
end rtl;
