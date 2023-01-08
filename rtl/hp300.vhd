library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- synthesis translate_off
use ieee.numeric_std.ALL;
-- synthesis translate_on
library unisim;
use unisim.vcomponents.all;

entity hp300 is
	port(
	-- clk/reset
	clk_i			: in std_logic;
	clk200_p		: in std_logic;
	clk200_n		: in std_logic;
	reset_sw_i		: in std_logic;

	-- DVI interface
	dvi_de			: out std_logic;
	dvi_d			: out std_logic_vector(11 downto 0);
	dvi_v			: out std_logic;
	dvi_h			: out std_logic;
	dvi_xclk_p		: out std_logic;
	dvi_xclk_n		: out std_logic;
	dvi_reset_b		: out std_logic;
	iic_scl_video		: out std_logic;
	iic_sda_video		: out std_logic;

	led			: out std_logic_vector(7 downto 0);
	gpio_dip_sw		: in std_logic_vector(7 downto 0);

	ddr2_init_done_led_o	: out std_logic;
	ps2_key_i		: in std_logic_vector(10 downto 0);

	-- config values
	dram_size		: in std_logic_vector(2 downto 0);

	-- ps2 keyboard
	ps2_clk_i		: in std_logic;
	ps2_data_i		: in std_logic;
	-- FLASH
	sram_flash_a		: out std_logic_vector(21 downto 0);
	sram_flash_d		: inout std_logic_vector(15 downto 0);
	sram_flash_we_b		: out std_logic;
	flash_clk		: out std_logic;
	flash_adv_b		: out std_logic;
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
	ddr2_ck_n		: out std_logic_vector(1 downto 0)
	);
end entity hp300;

architecture rtl of hp300 is

component WF68K30L_TOP is
	generic(VERSION     : std_logic_vector(31 downto 0) := x"20191224"; -- CPU version number.
	-- The following two switches are for debugging purposes. Default for both is false.
	NO_PIPELINE     : boolean := false;  -- If true the main controller work in scalar mode.
	NO_LOOP         : boolean := false); -- If true the DBcc loop mechanism is disabled.

	port (
	CLK             : in std_logic;

	-- Address and data:
	ADR_OUT         : out std_logic_vector(31 downto 0);
	DATA_IN         : in std_logic_vector(31 downto 0);
	DATA_OUT        : out std_logic_vector(31 downto 0);
	DATA_EN         : out std_logic; -- Enables the data port.

	-- System control:
	BERRn           : in std_logic;
	RESET_INn       : in std_logic;
	RESET_OUT       : out std_logic; -- Open drain.
	HALT_INn        : in std_logic;
	HALT_OUTn       : out std_logic; -- Open drain.

	-- Processor status:
	FC_OUT          : out std_logic_vector(2 downto 0);

	-- Interrupt control:
	AVECn           : in std_logic;
	IPLn            : in std_logic_vector(2 downto 0);
	IPENDn          : out std_logic;

	-- Aynchronous bus control:
	DSACKn          : in std_logic_vector(1 downto 0);
	SIZE            : out std_logic_vector(1 downto 0);
	ASn             : out std_logic;
	RWn             : out std_logic;
	RMCn            : out std_logic;
	DSn             : out std_logic;
	ECSn            : out std_logic;
	OCSn            : out std_logic;
	DBENn           : out std_logic; -- Data buffer enable.
	BUS_EN          : out std_logic; -- Enables ADR, ASn, DSn, RWn, RMCn, FC and SIZE.

	-- Synchronous bus control:
	STERMn          : in std_logic;

	-- Status controls:
	STATUSn         : out std_logic;
	REFILLn         : out std_logic;

	-- Bus arbitration control:
	BRn             : in std_logic;
	BGn             : out std_logic;
	BGACKn          : in std_logic
	);
end component;

component ddr2_controller is generic(
	BANK_WIDTH		: integer := 2;      -- # of memory bank addr bits.
	CKE_WIDTH		: integer := 1;  -- # of memory clock enable outputs.
	CLK_WIDTH		: integer := 2;  -- # of clock outputs.
	COL_WIDTH		: integer := 10; -- # of memory column bits.
	CS_NUM			: integer := 1;  -- # of separate memory chip selects.
	CS_WIDTH		: integer := 1;  -- # of total memory chip selects.
	CS_BITS			: integer := 0;  -- set to log2(CS_NUM) (rounded up).
	DM_WIDTH		: integer := 8;  -- # of data mask bits.
	DQ_WIDTH		: integer := 64; -- # of data width.
	DQ_PER_DQS		: integer := 8;  -- # of DQ data bits per strobe.
	DQS_WIDTH		: integer := 8;  -- # of DQS strobes.
	DQ_BITS			: integer := 6;  -- set to log2(DQS_WIDTH*DQ_PER_DQS).
	DQS_BITS		: integer := 3;  -- set to log2(DQS_WIDTH).
	ODT_WIDTH		: integer := 1;  -- # of memory on-die term enables.
	ROW_WIDTH		: integer := 13; -- # of memory row and # of addr bits.
	ADDITIVE_LAT		: integer := 0;  -- additive write latency.
	BURST_LEN		: integer := 4;  -- burst length (in double words).
	BURST_TYPE		: integer := 0; -- burst type (=0 seq; =1 interleaved).
	CAS_LAT			: integer := 3; -- CAS latency.
	ECC_ENABLE		: integer := 0; -- enable ECC (=1 enable).
	APPDATA_WIDTH		: integer := 128; -- # of usr read/write data bus bits.
	MULTI_BANK_EN		: integer := 1;	-- Keeps multiple banks open. (= 1 enable).
	TWO_T_TIME_EN		: integer := 1;	-- 2t timing for unbuffered dimms.
	ODT_TYPE		: integer := 1;	-- ODT (=0(none),=1(75),=2(150),=3(50)).
	REDUCE_DRV		: integer := 0;	-- reduced strength mem I/O (=1 yes).
	REG_ENABLE		: integer := 0;	-- registered addr/ctrl (=1 yes).
	TREFI_NS		: integer := 7800;	-- auto refresh interval (ns).
	TRAS			: integer := 40000;	-- active->precharge delay.
	TRCD			: integer := 15000;	-- active->read/write delay.
	TRFC			: integer := 105000;	-- refresh->refresh, refresh->active delay.
	TRP			: integer := 15000;	-- precharge->command delay.
	TRTP			: integer := 7500; -- read->precharge delay.
	TWR			: integer := 15000; -- used to determine write->precharge.
	TWTR			: integer := 7500; -- write->read delay.
	HIGH_PERFORMANCE_MODE	: boolean := TRUE;
	SIM_ONLY		: integer := 0; -- = 1 to skip SDRAM power up delay.
	DEBUG_EN		: integer := 0; -- Enable debug signals/controls.
	CLK_PERIOD		: integer := 5000;	-- Core/Memory clock period (in ps).
	DLL_FREQ_MODE		: string := "HIGH"; -- DCM Frequency range.
	CLK_TYPE		: string := "DIFFERENTIAL";
	NOCLK200		: boolean := FALSE; -- clk200 enable and disable
	RST_ACT_LOW		: integer := 1 -- =1 for active low reset, =0 for active high.
	);
port(
	ddr2_dq			: inout std_logic_vector((DQ_WIDTH-1) downto 0);
	ddr2_a			: out std_logic_vector((ROW_WIDTH-1) downto 0);
	ddr2_ba			: out std_logic_vector((BANK_WIDTH-1) downto 0);
	ddr2_ras_n		: out std_logic;
	ddr2_cas_n		: out std_logic;
	ddr2_we_n		: out std_logic;
	ddr2_cs_n		: out std_logic_vector((CS_WIDTH-1) downto 0);
	ddr2_odt		: out std_logic_vector((ODT_WIDTH-1) downto 0);
	ddr2_cke		: out std_logic_vector((CKE_WIDTH-1) downto 0);
	ddr2_dm			: out std_logic_vector((DM_WIDTH-1) downto 0);
	clk200_p		: in std_logic;
	clk200_n		: in std_logic;
	sys_rst_n		: in std_logic;
	rst0_tb			: out std_logic;
	clk0_tb			: out std_logic;
	phy_init_done		: out std_logic;
	app_wdf_afull		: out std_logic;
	app_af_afull		: out std_logic;
	rd_data_valid		: out std_logic;
	app_wdf_wren		: in std_logic;
	app_af_wren		: in std_logic;
	app_af_addr		: in std_logic_vector(30 downto 0);
	app_af_cmd		: in std_logic_vector(2 downto 0);
	rd_data_fifo_out	: out std_logic_vector((APPDATA_WIDTH-1) downto 0);
	app_wdf_data		: in std_logic_vector((APPDATA_WIDTH-1) downto 0);
	app_wdf_mask_data	: in std_logic_vector((APPDATA_WIDTH/8-1) downto 0);
	ddr2_dqs		: inout std_logic_vector((DQS_WIDTH-1) downto 0);
	ddr2_dqs_n		: inout std_logic_vector((DQS_WIDTH-1) downto 0);
	ddr2_ck			: out std_logic_vector((CLK_WIDTH-1) downto 0);
	ddr2_ck_n		: out std_logic_vector((CLK_WIDTH-1) downto 0)
);
end component;

component videorom is port (
	clk_i		: in std_logic;
	addr_i		: in std_logic_vector(12 downto 0);
	data_o		: out std_logic_vector(7 downto 0));
end component;

component fb is port (
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
end component;

component dvienc is port (
	clk_i: in std_logic;
	reset_i: in std_logic;
	sda:	out std_logic;
	scl:	out std_logic);
end component;

component hif is port(
	clk_i		: in std_logic;
	reset_i		: in std_logic;
	nmi_o		: out std_logic;
	irq_o		: out std_logic;

	db_i		: in std_logic_vector(7 downto 0);
	db_o		: out std_logic_vector(7 downto 0);
	addr_i		: in std_logic_vector(31 downto 0);
	cs_i		: in std_logic;
	rwn_i		: in std_logic;

	ps2_clk_i	: in std_logic;
	ps2_data_i	: in std_logic);
end component;

component ptm6840 is port (
	db_i		: in std_logic_vector(7 downto 0);
	db_o		: out std_logic_vector(7 downto 0);
	rs_i		: in std_logic_vector(2 downto 0);
	e_i		: in std_logic;
	clk_i		: in std_logic;
	cs_i		: in std_logic;
	rwn_i		: in std_logic;
	irq_o		: out std_logic;
	reset_i		: in std_logic;

	g1_i		: in std_logic;
	g2_i		: in std_logic;
	g3_i		: in std_logic;

	c1_i		: in std_logic;
	c2_i		: in std_logic;
	c3_i		: in std_logic;

	o1_o		: out std_logic;
	o2_o		: out std_logic;
	o3_o		: out std_logic);
end component;

component chipscope_ila IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    CLK: in std_logic;
    DATA: in std_logic_vector(320 downto 0);
    TRIG0: in std_logic_vector(31 downto 0);
    TRIG1: in std_logic_vector(0 to 0);
    TRIG2: in std_logic_vector(0 to 0));
END component;

component chipscope_icon IS
  port (
    CONTROL0: inout std_logic_vector(35 downto 0));
END component;

signal videorom_data_s		: std_logic_vector(7 downto 0);
signal hif_data_s		: std_logic_vector(7 downto 0);

signal cpu_data_in_s		: std_logic_vector(31 downto 0);
signal cpu_addr_s		: std_logic_vector(31 downto 0);
signal cpu_data_out_s		: std_logic_vector(31 downto 0);
signal cpu_fc_s			: std_logic_vector(2 downto 0);
signal cpu_size_s		: std_logic_vector(1 downto 0);
signal cpu_dsack_n_s		: std_logic_vector(1 downto 0);
signal cpu_ipl_n_s		: std_logic_vector(2 downto 0);
signal cpu_reset_n_s		: std_logic;
signal cpu_reset_out_s		: std_logic;
signal cpu_sterm_n_s		: std_logic;
signal cpu_br_n_s		: std_logic;
signal cpu_lds_n_s		: std_logic;
signal cpu_uds_n_s		: std_logic;
signal cpu_bg_n_s		: std_logic;
signal cpu_bgack_n_s		: std_logic;
signal cpu_berr_n_s		: std_logic;
signal cpu_as_n_s		: std_logic;
signal cpu_ecs_n_s		: std_logic;
signal cpu_rw_n_s		: std_logic;
signal cpu_avec_n_s		: std_logic;
signal cpu_ds_s			: std_logic_vector(3 downto 0);

signal sdram_read_req_s		: std_logic;
signal sdram_read_req200_s	: std_logic;
signal sdram_read_ack_s		: std_logic;
signal sdram_read_ack200_s	: std_logic;
signal sdram_write_req_s	: std_logic;
signal sdram_write_req200_s	: std_logic;
signal sdram_write_ack_s	: std_logic;
signal sdram_write_ack200_s	: std_logic;
signal sdram_cs_s		: std_logic;
signal sdram_addr200_s		: std_logic_vector(31 downto 0);
signal sdram_read_data200_s	: std_logic_vector(31 downto 0);
signal sdram_write_data200_s	: std_logic_vector(31 downto 0);
signal sdram_read_data_s	: std_logic_vector(31 downto 0);

signal ptm_data_s		: std_logic_vector(7 downto 0);
signal ptm_clk_counter_s	: std_logic_vector(7 downto 0);
signal ptm_o3_s			: std_logic;
signal ptm_cs_s			: std_logic;
signal ptm_irq_s		: std_logic;
signal ptm_clk_s		: std_logic;

signal fb_data_s		: std_logic_vector(15 downto 0);

signal bootrom_cs_s		: std_logic;
signal pmmu_cs_s		: std_logic;
signal videorom_cs_s		: std_logic;
signal videoctl_cs_s		: std_logic;
signal fb_cs_s			: std_logic;
signal fb_rdy_s			: std_logic;
signal gpib_cs_s		: std_logic;

signal hif_cs_s			: std_logic;
signal hif_reset_s		: std_logic;
signal hif_irq_s		: std_logic;
signal hif_nmi_s		: std_logic;

signal clk_s			: std_logic;
signal clk_pixel_s		: std_logic;
signal reset_s			: std_logic;
signal rst0_tb_s		: std_logic;
signal high_s			: std_logic := '1';
signal low_s			: std_logic := '0';

signal app_wdf_afull_s		: std_logic;
signal app_af_afull_s		: std_logic;
signal rd_data_valid_s		: std_logic;
signal rd_data_fifo_out_s	: std_logic_vector(127 downto 0);
signal app_wdf_wren_s		: std_logic := '0';
signal app_af_wren_s		: std_logic := '0';
signal app_af_addr_s		: std_logic_vector(30 downto 0) := (others => '0');
signal app_af_cmd_s		: std_logic_vector(2 downto 0) := (others => '0');
signal app_wdf_data_s		: std_logic_vector(127 downto 0) := (others => '0');
signal app_wdf_mask_data_s	: std_logic_vector(15 downto 0) := (others => '0');
signal ddr2_init_done_s		: std_logic;
signal wait_states_s		: integer;
signal clk_tb_s			: std_logic;

constant DS_WAIT		: std_logic_vector(1 downto 0) := "11";
constant DS_8BIT		: std_logic_vector(1 downto 0) := "10";
constant DS_16BIT		: std_logic_vector(1 downto 0) := "01";
constant DS_32BIT		: std_logic_vector(1 downto 0) := "00";

constant SIZ_LONG		: std_logic_vector(1 downto 0) := "00";
constant SIZ_BYTE		: std_logic_vector(1 downto 0) := "01";
constant SIZ_WORD		: std_logic_vector(1 downto 0) := "10";
constant SIZ_3BYTES		: std_logic_vector(1 downto 0) := "11";

signal sda_s			: std_logic;
signal scl_s			: std_logic;

signal chipscope_control_s	: std_logic_vector(35 downto 0);
signal chipscope_data_s		: std_logic_vector(320 downto 0);
signal chipscope_trig_read_s	: std_logic_vector(0 downto 0);
signal chipscope_trig_write_s	: std_logic_vector(0 downto 0);
signal chipscope_trig_addr_s	: std_logic_vector(31 downto 0);

function is_sdram(signal addr: in std_logic_vector(31 downto 0);
		  signal sel: in std_logic_vector(2 downto 0)) return boolean is
begin
	case sel is
		when "000" => return addr(31 downto 19) = "1111111111111";
		when "001" => return addr(31 downto 20) = "111111111111";
		when "010" => return addr(31 downto 21) = "11111111111";
		when "011" => return addr(31 downto 22) = "1111111111";
		when "100" => return addr(31 downto 23) = "111111111";
		when "101" => return addr(31 downto 24) = "11111111";
		when "110" => return addr(31 downto 25) = "1111111";
		when "111" => return addr(31 downto 26) = "111111";
		when others => return false;
	end case;
end function is_sdram;
begin

cpu_i: WF68K30L_TOP port map(
	CLK => clk_s,
	DATA_IN => cpu_data_in_s,
	DATA_OUT => cpu_data_out_s,
	ADR_OUT => cpu_addr_s,
	BERRn => cpu_berr_n_s,
	RESET_INn => cpu_reset_n_s,
	HALT_INn => cpu_reset_n_s,
	RESET_OUT => cpu_reset_out_s,
	FC_OUT => cpu_fc_s,
	AVECn => cpu_avec_n_s,
	IPLn => cpu_ipl_n_s,
	DSACKn => cpu_dsack_n_s,
	SIZE => cpu_size_s,
	ASn => cpu_as_n_s,
	ECSn => cpu_ecs_n_s,
	RWn => cpu_rw_n_s,
	STERMn => cpu_sterm_n_s,
	BRn => cpu_br_n_s,
	BGACkn => cpu_bgack_n_s);

ddr2_i: ddr2_controller port map(
	ddr2_dq => ddr2_dq,
	ddr2_a => ddr2_a(12 downto 0),
	ddr2_ba => ddr2_ba(1 downto 0),
	ddr2_ras_n => ddr2_ras_n,
	ddr2_cas_n => ddr2_cas_n,
	ddr2_we_n => ddr2_we_n,
	ddr2_cs_n => ddr2_cs_n(0 downto 0),
	ddr2_odt => ddr2_odt(0 downto 0),
	ddr2_cke => ddr2_cke(0 downto 0),
	ddr2_dm => ddr2_dm,
	ddr2_dqs => ddr2_dqs,
	ddr2_dqs_n =>  ddr2_dqs_n,
	ddr2_ck => ddr2_ck,
	ddr2_ck_n => ddr2_ck_n,
	sys_rst_n => not reset_sw_i,
	clk200_n => clk200_n,
	clk200_p => clk200_p,
	clk0_tb => clk_tb_s,
	rst0_tb => rst0_tb_s,
	phy_init_done => ddr2_init_done_s,
	app_wdf_wren => app_wdf_wren_s,
	app_wdf_afull => app_wdf_afull_s,
	app_af_wren => app_af_wren_s,
	app_af_addr => app_af_addr_s,
	app_af_cmd => app_af_cmd_s,
	app_wdf_data => app_wdf_data_s,
	app_wdf_mask_data => app_wdf_mask_data_s,
	rd_data_valid => rd_data_valid_s,
	rd_data_fifo_out => rd_data_fifo_out_s
);

videorom_i: videorom port map(
	clk_i => clk_s,
	data_o => videorom_data_s,
	addr_i => cpu_addr_s(13 downto 1));

fb_i: fb port map(
	clk_i => clk_s,
	clk_pixel_p_o => dvi_xclk_p,
	clk_pixel_n_o => dvi_xclk_n,
	reset_i => reset_s,
	hsync_o => dvi_h,
	vsync_o => dvi_v,
	data_o => dvi_d,
	de => dvi_de,
	db_i => cpu_data_out_s(31 downto 16),
	db_o => fb_data_s,
	addr_i => cpu_addr_s(19 downto 0),
	vram_cs_i => fb_cs_s,
	rwn_i => cpu_rw_n_s,
	udsn_i => cpu_uds_n_s,
	ldsn_i => cpu_lds_n_s,
	ctl_cs_i => videoctl_cs_s,
	rdy_o => fb_rdy_s);

dvienc_i: dvienc port map(
	clk_i => clk_s,
	reset_i => reset_s,
	scl => scl_s,
	sda => sda_s
);

ptm_i: ptm6840 port map(
	db_i => cpu_data_out_s(7 downto 0),
	db_o => ptm_data_s,
	rs_i => cpu_addr_s(3 downto 1),
	clk_i => clk_s,
	cs_i => ptm_cs_s,
	rwn_i => cpu_rw_n_s,
	irq_o => ptm_irq_s,
	reset_i => reset_s,
	g1_i => high_s,
	g2_i => high_s,
	g3_i => high_s,
	e_i => high_s,
	c1_i => ptm_clk_s,
	c2_i => ptm_o3_s,
	c3_i => ptm_clk_s,
	o3_o => ptm_o3_s);

hif_i: hif port map(
	clk_i => clk_s,
	reset_i => hif_reset_s,
	nmi_o => hif_nmi_s,
	irq_o => hif_irq_s,
	db_i => cpu_data_out_s(7 downto 0),
	db_o => hif_data_s,
	addr_i => cpu_addr_s,
	cs_i => hif_cs_s,
	rwn_i => cpu_rw_n_s,
	ps2_clk_i => ps2_clk_i,
	ps2_data_i => ps2_data_i);

icon: chipscope_icon port map(
	CONTROL0 => chipscope_control_s
);

ila: chipscope_ila port map(
	CONTROL => chipscope_control_s,
	clk => clk_tb_s,
	data => chipscope_data_s,
	trig0 => chipscope_trig_addr_s,
	trig1 => chipscope_trig_write_s,
	trig2 => chipscope_trig_read_s
);

cpu_bgack_n_s <= '1';
cpu_br_n_s <= '1';
cpu_sterm_n_s <= '1';
cpu_uds_n_s <= cpu_ds_s(3) and cpu_ds_s(1);
cpu_lds_n_s <= cpu_ds_s(2) and cpu_ds_s(0);
cpu_reset_n_s <= not reset_s;
hif_reset_s <= reset_s or cpu_reset_out_s;
flash_clk <= clk_s;
flash_adv_b <= '0';
sram_flash_we_b <= '1';
sram_oe_b <= '1';
sram_mode <= '0';
sram_flash_d <= (others => 'Z');
dvi_reset_b <= not reset_s;
iic_scl_video <= 'Z' when scl_s = '1' else '0';
iic_sda_video <= 'Z' when sda_s = '1' else '0';

ddr2_cs_n(1) <= '1';
ddr2_odt(1) <= '0';
ddr2_a(13) <= '0';
ddr2_cke(1) <= '0';
ddr2_ba(2) <= '0';
ddr2_init_done_led_o <= ddr2_init_done_s;

clkdiv: process(reset_s, clk_tb_s)
	variable divcnt: integer;
begin
	if (reset_sw_i = '1') then
		divcnt := 0;
		clk_s <= '0';
	elsif (rising_edge(clk_tb_s)) then
		if (divcnt < 1) then
			divcnt := divcnt + 1;
		else
			divcnt := 0;
			clk_s <= not clk_s;
		end if;
	end if;
end process;

resetgen: process(reset_sw_i, clk_i)
begin
	if (reset_sw_i = '1') then
		reset_s <= '1';
	elsif (rising_edge(clk_i)) then
		if (ddr2_init_done_s = '1' and rst0_tb_s = '0') then
			reset_s <= '0';
		else
			reset_s <= '1';
		end if;
	end if;
end process;

ptmclk: process(reset_s, clk_s)
begin
	if (reset_s = '1') then
		ptm_clk_counter_s <= (others => '0');
	elsif rising_edge(clk_s) then
		ptm_clk_counter_s <= ptm_clk_counter_s + 1;
		ptm_clk_s <= ptm_clk_counter_s(7);
	end if;
end process;

ipl: process(reset_s, clk_s)
begin
	if (reset_s = '1') then
		cpu_ipl_n_s <= (others => '1');
	elsif rising_edge(clk_s) then
		if (hif_irq_s = '1') then
			cpu_ipl_n_s <= "110";
		elsif (ptm_irq_s = '1') then
			cpu_ipl_n_s <= "001";
		else
			cpu_ipl_n_s <= "111";
		end if;
	end if;
end process;

cpu_ds_s(3) <= not(cpu_rw_n_s or (not cpu_addr_s(0) and not cpu_addr_s(1)));

cpu_ds_s(2) <= not(cpu_rw_n_s or (not cpu_size_s(0) and not cpu_addr_s(1)) or
		   (not cpu_addr_s(1) and cpu_addr_s(0)) or
		   (cpu_size_s(1) and not cpu_addr_s(1)));

cpu_ds_s(1) <= not(cpu_rw_n_s or (not cpu_addr_s(0) and cpu_addr_s(1)) or
		   (not cpu_addr_s(1) and not cpu_size_s(0) and not cpu_size_s(1)) or
		   (cpu_size_s(1) and cpu_size_s(0) and not cpu_addr_s(1)) or
		   (not cpu_size_s(0) and not cpu_addr_s(1) and cpu_addr_s(0)));

cpu_ds_s(0) <= not(cpu_rw_n_s or
		   (cpu_addr_s(0) and cpu_size_s(0) and cpu_size_s(1)) or
		   (not cpu_size_s(0) and not cpu_size_s(1)) or
		   (cpu_addr_s(0) and cpu_addr_s(1)) or
		   (cpu_addr_s(1) and cpu_size_s(1)));

-- watchdog: process(clk_s)
-- 	variable watchdogcnt : integer;
-- begin
-- 	if bus_state_s = IDLE then
-- 		watchdogcnt := watchdogcnt + 1;
-- 		assert (watchdogcnt < 1024) report "Watchdog timeout" severity failure;
-- 	else
-- 		watchdogcnt := 0;
-- 	end if;
-- end process;

chipscope_data_s(127 downto 0) <= app_wdf_data_s;
chipscope_data_s(158 downto 128) <= app_af_addr_s;
chipscope_data_s(159) <= app_af_wren_s;
chipscope_data_s(160) <= app_wdf_wren_s;
chipscope_data_s(161) <= clk_i;
chipscope_data_s(162) <= reset_s;
chipscope_data_s(163) <= ddr2_init_done_s;
chipscope_data_s(164) <= sdram_read_req_s;
chipscope_data_s(165) <= sdram_read_ack_s;
chipscope_data_s(166) <= sdram_write_req_s;
chipscope_data_s(167) <= sdram_write_ack_s;
chipscope_data_s(168) <= rd_data_valid_s;
chipscope_data_s(319 downto 192) <= rd_data_fifo_out_s;
chipscope_trig_addr_s <= '0' & app_af_addr_s;
chipscope_trig_write_s(0) <= sdram_write_req_s;
chipscope_trig_read_s(0) <= sdram_read_req_s;
chipscope_data_s(191 downto 169) <= (others => '1');

reqsync: process(reset_s, clk_tb_s)
begin
	if (rising_edge(clk_tb_s)) then
		sdram_read_req200_s <= sdram_read_req_s;
		sdram_write_req200_s <= sdram_write_req_s;
		sdram_write_data200_s <= cpu_data_out_s;
		sdram_addr200_s <= cpu_addr_s;
	end if;
end process;

acksync: process(reset_s, clk_s)
begin
	if (rising_edge(clk_s)) then
		sdram_read_ack_s <= sdram_read_ack200_s;
		sdram_write_ack_s <= sdram_write_ack200_s;
		sdram_read_data_s <= sdram_read_data200_s;
	end if;
end process;


dramgw: process(reset_s, clk_tb_s)
	type sdram_state_t is (IDLE, READ0, READ1, WRITE0, WRITE1);
	variable state: sdram_state_t;
	constant APP_CMD_WRITE: std_logic_vector(2 downto 0) := "000";
	constant APP_CMD_READ: std_logic_vector(2 downto 0)  := "001";
begin
	if (reset_s = '1') then
		app_af_addr_s <= (others => '0');
		app_wdf_data_s <= (others => '0');
		app_af_cmd_s <= (others => '0');
		app_af_wren_s <= '0';
		sdram_read_ack200_s <= '0';
		sdram_write_ack200_s <= '0';
		state := IDLE;
	elsif (rising_edge(clk_tb_s)) then
		case state is
			when IDLE =>
				if (sdram_read_req200_s = '1') then
					app_af_addr_s <= "0000000" & sdram_addr200_s(25 downto 2);
					app_af_cmd_s <= APP_CMD_READ;
					app_af_wren_s <= '1';
					state := READ0;
				else
					sdram_read_ack200_s <= '0';
				end if;

				if (sdram_write_req200_s = '1') then
					app_af_addr_s <= "0000000" & sdram_addr200_s(25 downto 2);
					app_af_wren_s <= '1';
					app_af_cmd_s <= APP_CMD_WRITE;
					app_wdf_data_s(31 downto 0) <= cpu_data_out_s;
					app_wdf_data_s(127 downto 32) <= (others => '0');
					app_wdf_wren_s <= '1';
					app_wdf_mask_data_s <= x"ff0" & cpu_ds_s(3) & cpu_ds_s(2) & cpu_ds_s(1) & cpu_ds_s(0);
					sdram_write_ack200_s <= '1';
					state := WRITE0;
				else
					sdram_write_ack200_s <= '0';
				end if;
			when READ0 =>
				app_wdf_mask_data_s <= (others => '1');
				app_af_wren_s <= '0';
				if (rd_data_valid_s = '1') then
					sdram_read_data200_s <= rd_data_fifo_out_s(31 downto 0);
					sdram_read_ack200_s <= '1';
					state := READ1;
				end if;
			when READ1 =>
				if (sdram_read_req200_s = '0') then
					state := IDLE;
					sdram_read_ack200_s <= '0';
				end if;
			when WRITE0 =>
				app_wdf_mask_data_s(15 downto 0) <= (others => '1');
				app_wdf_data_s <= (others => '0');
				app_wdf_wren_s <= '1';
				app_af_wren_s <= '0';
				state := WRITE1;
			when WRITE1 =>
				app_wdf_wren_s <= '0';
				if (sdram_write_req200_s = '0') then
					sdram_write_ack200_s <= '0';
					state := IDLE;
				end if;
		end case;
	end if;
end process;

addr_decode: process(reset_s, clk_s)
	type state_type is ( IDLE, WS, ACK, ERROR );
	variable bus_state_s: state_type;
begin
	if (reset_s = '1') then
		bus_state_s := IDLE;
	elsif (rising_edge(clk_s)) then
		case bus_state_s is
			when IDLE =>
				cpu_dsack_n_s <= DS_WAIT;
				cpu_berr_n_s <= '1';
				bootrom_cs_s <= '0';
				fb_cs_s <= '0';
				videorom_cs_s <= '0';
				pmmu_cs_s <= '0';
				ptm_cs_s <= '0';
				hif_cs_s <= '0';
				gpib_cs_s <= '0';
				flash_ce_b <= '1';
				flash_oe_b <= '1';
				videoctl_cs_s <= '0';
				sdram_read_req_s <= '0';
				sdram_write_req_s <= '0';
				sdram_cs_s <= '0';
				if (cpu_as_n_s = '0' and cpu_fc_s /= 7) then
					cpu_avec_n_s <= '1';
					if (cpu_addr_s(31 downto 20) = x"002") then
						fb_cs_s <= '1';
						bus_state_s := ACK;
					elsif (cpu_addr_s(31 downto 16) = x"0042") then
						hif_cs_s <= '1';
						bus_state_s := ACK;
					elsif (cpu_addr_s(31 downto 16) = x"0047") then
						gpib_cs_s <= '1';
						bus_state_s := ACK;
					elsif (cpu_addr_s(31 downto 14) = x"0056" & "00") then
						videorom_cs_s <= '1';
						bus_state_s := ACK;
					elsif (cpu_addr_s(31 downto 14) = x"0056" & "01") then
						videoctl_cs_s <= '1';
						bus_state_s := ACK;
					elsif (cpu_addr_s(31 downto 17) = "000000000000000" ) then -- boot rom
						sram_flash_a <= "000" & cpu_addr_s(19 downto 1);
						flash_ce_b <= '0';
						flash_oe_b <= '0';
						bootrom_cs_s <= '1';
						wait_states_s <= 5;
						bus_state_s := WS;
					elsif (cpu_addr_s(31 downto 20) = x"001") then -- basic rom
						sram_flash_a <= "001" & cpu_addr_s(19 downto 1);
						flash_ce_b <= '0';
						flash_oe_b <= '0';
						bootrom_cs_s <= '1';
						wait_states_s <= 5;
						bus_state_s := WS;
					elsif (is_sdram(cpu_addr_s, gpio_dip_sw(2 downto 0))) then
						bus_state_s := ACK;
						sdram_cs_s <= '1';
						if (cpu_rw_n_s = '0') then
							sdram_write_req_s <= '1';
						else
							sdram_read_req_s <= '1';
						end if;
					elsif (cpu_addr_s(31 downto 12) = x"005f4") then
						pmmu_cs_s <= '1';
						bus_state_s := ACK;
					elsif (cpu_addr_s(31 downto 4) = x"005f800") then
						ptm_cs_s <= '1';
						bus_state_s := ACK;
					else
						-- synthesis translate_off
						if (cpu_rw_n_s = '0') then
							report "unknown write: " & to_hstring(cpu_addr_s) & ": " & to_hstring(cpu_data_out_s) & ": " & to_hstring(cpu_ds_s);
						else
							report "unknown read: " & to_hstring(cpu_addr_s) &  ": " & to_hstring(cpu_ds_s);
						end if;
						-- synthesis translate_on

						cpu_berr_n_s <= '0';
						bus_state_s := ERROR;
					 end if;
				elsif (cpu_as_n_s = '0' and cpu_fc_s = 7) then
					cpu_avec_n_s <= '0';
				else
					cpu_avec_n_s <= '1';
				end if;

			when WS =>
				if (wait_states_s > 0) then
					wait_states_s <= wait_states_s - 1;
				else
					bus_state_s := ACK;
				end if;

			when ACK =>
				if (sdram_cs_s = '1') then
					if (sdram_read_req_s = '1' and sdram_read_ack_s = '1') then
						-- synthesis translate_off
						report "sdram read: " & to_hstring(cpu_addr_s) & ": " & to_hstring(cpu_data_in_s) severity warning;
						-- synthesis translate_on
						sdram_read_req_s <= '0';
						cpu_dsack_n_s <= DS_32BIT;
					end if;
					if (sdram_write_req_s = '1' and sdram_write_ack_s = '1') then
						-- synthesis translate_off
						report "sdram write: " & to_hstring(cpu_addr_s) & ": " & to_hstring(cpu_data_out_s) severity warning;
						-- synthesis translate_on
						sdram_write_req_s <= '0';
						cpu_dsack_n_s <= DS_32BIT;
					end if;
--				elsif (fb_cs_s = '1') then
--					cpu_dsack_n_s <= DS_32BIT;
				elsif (videoctl_cs_s = '1' or fb_cs_s = '1') then
					cpu_dsack_n_s <= DS_8BIT;
				else
					cpu_dsack_n_s <= DS_16BIT;
				end if;


				-- synthesis translate_off
				-- if (sram_cs_s = '1') then
				-- 	if (cpu_rw_n_s = '1') then
				-- 		report "SRAM read: " & to_hstring(cpu_addr_s) & ": " & to_hstring(cpu_data_in_s);
				-- 	else
				-- 		report "SRAM write: " & to_hstring(cpu_addr_s) & ": " & to_hstring(cpu_data_out_s) & " ds: " & to_hstring(cpu_ds_s);
				-- 	end if;
				-- end if;
				-- synthesis translate_on
				if (cpu_as_n_s = '1') then
					cpu_dsack_n_s <= "11";
					bus_state_s := IDLE;
					bootrom_cs_s <= '0';
					fb_cs_s <= '0';
					videorom_cs_s <= '0';
					pmmu_cs_s <= '0';
					ptm_cs_s <= '0';
					hif_cs_s <= '0';
					videoctl_cs_s <= '0';
					flash_ce_b <= '1';
					flash_oe_b <= '1';
				 end if;

			when ERROR =>
				cpu_berr_n_s <= '0';
				if (cpu_as_n_s = '1') then
					bus_state_s := IDLE;
				end if;
		end case;
	end if;
end process;

ledwr: process(reset_s, clk_s)
begin
	if (reset_s = '1') then
		led <= x"ff";
	elsif (rising_edge(clk_s)) then
		if (cpu_rw_n_s = '0' and cpu_addr_s = x"0001ffff") then
			led <= not cpu_data_out_s(7 downto 0);
-- synthesis translate_off
			report "LED: " & to_hstring(cpu_data_out_s(7 downto 0));
-- synthesis translate_on
		end if;
	end if;
end process;

cpu_data_in_s <= sram_flash_d & sram_flash_d when bootrom_cs_s = '1' else
		 sdram_read_data_s when sdram_cs_s = '1' else
		 x"ff" & videorom_data_s & x"ffff" when videorom_cs_s = '1' else
		 fb_data_s & x"ffff" when (fb_cs_s = '1' or videoctl_cs_s = '1') else
		 x"ff" & ptm_data_s & x"ffff" when ptm_cs_s = '1' else
		 x"ff" & hif_data_s & x"ffff" when hif_cs_s = '1' else
		 x"ffffffff";

end rtl;
