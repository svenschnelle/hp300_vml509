library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- synthesis translate_off
use ieee.numeric_std.ALL;
-- synthesis translate_on

entity hp300 is port(
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

	-- config values
	dram_size		: in std_logic_vector(2 downto 0)
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

component bootrom is port (
	clk_i           : in std_logic;
	addr_i          : in std_logic_vector(14 downto 0);
	data_o          : out std_logic_vector(31 downto 0));
end component;

component sram is port(
	clka	: in std_logic;
	wea	: in std_logic_vector(3 downto 0);
	addra	: in std_logic_vector(16 downto 0);
	dina	: in std_logic_vector(31 downto 0);
	douta	: out std_logic_vector(31 downto 0));
end component;

component videorom is port (
	clk_i		: in std_logic;
	addr_i		: in std_logic_vector(12 downto 0);
	data_o		: out std_logic_vector(7 downto 0));
end component;

component fb is port (
	clk_i		: in std_logic;
	clk_pixel_i	: in std_logic;
	reset_i		: in std_logic;
	ce_pixel_o	: out std_logic;
	hblank_o	: out std_logic;
	vblank_o	: out std_logic;
	hsync_o		: out std_logic;
	vsync_o		: out std_logic;
	r_o		: out std_logic_vector(7 downto 0);
	g_o		: out std_logic_vector(7 downto 0);
	b_o		: out std_logic_vector(7 downto 0);

	db_i		: in std_logic_vector(15 downto 0);
	db_o		: out std_logic_vector(15 downto 0);
	addr_i		: in std_logic_vector(19 downto 0);
	vram_cs_i	: in std_logic;
	rwn_i		: in std_logic;
	rdy_o		: out std_logic;
	udsn_i          : in std_logic;
	ldsn_i          : in std_logic;
	ctl_cs_i	: in std_logic);
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
	ps2_key_i	: in std_logic_vector(10 downto 0));
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

signal bootrom_data_s		: std_logic_vector(31 downto 0);
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
signal cpu_rw_n_s		: std_logic;
signal cpu_avec_n_s		: std_logic;
signal cpu_ds_s			: std_logic_vector(3 downto 0);

signal ptm_data_s		: std_logic_vector(7 downto 0);
signal ptm_clk_counter_s	: std_logic_vector(6 downto 0);
signal ptm_o3_s			: std_logic;
signal ptm_cs_s			: std_logic;
signal ptm_irq_s		: std_logic;
signal ptm_clk_s		: std_logic;

signal fb_data_s		: std_logic_vector(15 downto 0);
signal resetcnt_s		: std_logic_vector(15 downto 0);

signal sram_we_s		: std_logic_vector(3 downto 0);
signal sram_data_in_s		: std_logic_vector(31 downto 0);
signal sram_data_out_s		: std_logic_vector(31 downto 0);
signal reset_probe_s		: std_logic;

signal bootrom_cs_s		: std_logic;
signal sram_cs_s		: std_logic;
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

signal clk_div_s		: std_logic_vector(1 downto 0);

signal reset_s			: std_logic;

signal high_s			: std_logic := '1';
signal low_s			: std_logic := '0';
type state_type is ( IDLE, ACK, ERROR );
signal bus_state_s		: state_type;

begin

cpu_i: WF68K30L_TOP port map(
	CLK => clk_i,
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
	RWn => cpu_rw_n_s,
	STERMn => cpu_sterm_n_s,
	BRn => cpu_br_n_s,
	BGACkn => cpu_bgack_n_s);

bootrom_i: bootrom port map(
	clk_i => clk_i,
	data_o => bootrom_data_s,
	addr_i => cpu_addr_s(16 downto 2));

sram_i: sram port map(
	clka => clk_i,
	wea => sram_we_s,
	addra => cpu_addr_s(18 downto 2),
	dina => sram_data_in_s,
	douta => sram_data_out_s);

videorom_i: videorom port map(
	clk_i => clk_i,
	data_o => videorom_data_s,
	addr_i => cpu_addr_s(13 downto 1));

fb_i: fb port map(
	clk_i => clk_i,
	clk_pixel_i => clk_pixel_i,
	reset_i => reset_s,
	ce_pixel_o => ce_pixel_o,
	hblank_o => hblank_o,
	vblank_o => vblank_o,
	hsync_o => hsync_o,
	vsync_o => vsync_o,
	r_o => r_o,
	g_o => g_o,
	b_o => b_o,
	db_i => cpu_data_out_s(31 downto 16),
	db_o => fb_data_s,
	addr_i => cpu_addr_s(19 downto 0),
	vram_cs_i => fb_cs_s,
	rwn_i => cpu_rw_n_s,
	udsn_i => cpu_uds_n_s,
	ldsn_i => cpu_lds_n_s,
	ctl_cs_i => videoctl_cs_s,
	rdy_o => fb_rdy_s);

ptm_i: ptm6840 port map(
	db_i => cpu_data_out_s(7 downto 0),
	db_o => ptm_data_s,
	rs_i => cpu_addr_s(3 downto 1),
	clk_i => clk_i,
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
	clk_i => clk_i,
	reset_i => hif_reset_s,
	nmi_o => hif_nmi_s,
	irq_o => hif_irq_s,
	db_i => cpu_data_out_s(7 downto 0),
	db_o => hif_data_s,
	addr_i => cpu_addr_s,
	cs_i => hif_cs_s,
	rwn_i => cpu_rw_n_s,
	ps2_key_i => ps2_key_i);

cpu_bgack_n_s <= '1';
cpu_br_n_s <= '1';
cpu_sterm_n_s <= '1';
cpu_uds_n_s <= cpu_ds_s(3) and cpu_ds_s(1);
cpu_lds_n_s <= cpu_ds_s(2) and cpu_ds_s(0);
cpu_reset_n_s <= not reset_s;
hif_reset_s <= reset_s or cpu_reset_out_s;
sram_data_in_s <= cpu_data_out_s;

resetgen: process(reset_sw_i, clk_i)
	variable resetcnt : integer;
begin
	if (reset_sw_i = '1') then
		resetcnt := 0;
	elsif rising_edge(clk_i) then
		if (resetcnt < 33) then
			resetcnt := resetcnt + 1;
			reset_s <= '1';
		else
			reset_s <= '0';
		end if;
	end if;
end process;

ptmclk: process(reset_s, clk_i)
begin
	if (reset_s = '1') then
		ptm_clk_counter_s <= (others => '0');
	elsif rising_edge(clk_i) then
		ptm_clk_counter_s <= ptm_clk_counter_s + 1;
		ptm_clk_s <= ptm_clk_counter_s(6);
	end if;
end process;

clkdiv: process(reset_s, clk_i)
begin
	if (reset_s = '1') then
		clk_div_s <= (others => '0');
	elsif rising_edge(clk_i) then
		clk_div_s <= clk_div_s + 1;
	end if;
end process;

ipl: process(reset_s, clk_i)
begin
	if (reset_s = '1') then
		cpu_ipl_n_s <= (others => '1');
	elsif rising_edge(clk_i) then
		if (hif_irq_s = '1') then
			cpu_ipl_n_s <= "110";
		elsif (ptm_irq_s = '1') then
			cpu_ipl_n_s <= "001";
		else
			cpu_ipl_n_s <= "111";
		end if;
	end if;
end process;

dsgen: process(clk_i)
begin
	if (rising_edge(clk_i)) then
		cpu_ds_s(3) <= not(cpu_rw_n_s or (not cpu_addr_s(0) and not cpu_addr_s(1)));
		cpu_ds_s(2) <= not(cpu_rw_n_s or (not cpu_size_s(0) and not cpu_addr_s(1)) or (not cpu_addr_s(1) and cpu_addr_s(0)) or (cpu_size_s(1) and not cpu_addr_s(1)));
		cpu_ds_s(1) <= not(cpu_rw_n_s or (not cpu_addr_s(0) and cpu_addr_s(1)) or (not cpu_addr_s(1) and not cpu_size_s(0) and not cpu_size_s(1)) or (cpu_size_s(1) and cpu_size_s(0) and not cpu_addr_s(1)) or (not cpu_size_s(0) and not cpu_addr_s(1) and cpu_addr_s(0)));
		cpu_ds_s(0) <= not(cpu_rw_n_s or (cpu_addr_s(0) and cpu_size_s(0) and cpu_size_s(1)) or (not cpu_size_s(0) and not cpu_size_s(1)) or (cpu_addr_s(0) and cpu_addr_s(1)) or (cpu_addr_s(1) and cpu_size_s(1)));
	end if;
end process;

watchdog: process(clk_i)
	variable watchdogcnt : integer;
begin
	if bus_state_s = IDLE then
		watchdogcnt := watchdogcnt + 1;
		assert (watchdogcnt < 1024) report "Watchdog timeout" severity failure;
	else
		watchdogcnt := 0;
	end if;
end process;

addr_decode: process(reset_s, clk_i)
begin
	if (reset_s = '1') then
		bus_state_s <= IDLE;
	elsif (rising_edge(clk_i)) then
		case bus_state_s is
			when IDLE =>
				cpu_dsack_n_s <= "11";
				cpu_berr_n_s <= '1';
				bootrom_cs_s <= '0';
				fb_cs_s <= '0';
				videorom_cs_s <= '0';
				pmmu_cs_s <= '0';
				ptm_cs_s <= '0';
				hif_cs_s <= '0';
				gpib_cs_s <= '0';
				sram_cs_s <= '0';
				videoctl_cs_s <= '0';
				sram_we_s <= (others => '0');
				if (cpu_as_n_s = '0' and cpu_fc_s /= 7) then
					cpu_avec_n_s <= '1';
					if (cpu_addr_s(31 downto 20) = x"002") then
						fb_cs_s <= '1';
						bus_state_s <= ACK;
					elsif (cpu_addr_s(31 downto 16) = x"0042") then
						hif_cs_s <= '1';
						bus_state_s <= ACK;
					elsif (cpu_addr_s(31 downto 16) = x"0047") then
						gpib_cs_s <= '1';
						bus_state_s <= ACK;
					elsif (cpu_addr_s(31 downto 14) = x"0056" & "00") then
						videorom_cs_s <= '1';
						bus_state_s <= ACK;
					elsif (cpu_addr_s(31 downto 14) = x"0056" & "01") then
						videoctl_cs_s <= '1';
						bus_state_s <= ACK;
					elsif (cpu_addr_s(31 downto 20) = x"000") then -- boot rom
						bootrom_cs_s <= '1';
						bus_state_s <= ACK;
					elsif (cpu_addr_s(31 downto 19) = "1111111111111") then -- internal sram
						sram_cs_s <= '1';
						bus_state_s <= ACK;
					elsif (cpu_addr_s(31 downto 12) = x"005f4") then
						pmmu_cs_s <= '1';
						bus_state_s <= ACK;
					elsif (cpu_addr_s(31 downto 4) = x"005f800") then
						ptm_cs_s <= '1';
						bus_state_s <= ACK;
					else
						-- synthesis translate_off
						if (cpu_rw_n_s = '0') then
							report "unknown write: " & to_hstring(cpu_addr_s) & ": " & to_hstring(cpu_data_out_s) & ": " & to_hstring(cpu_ds_s);
						else
							report "unknown read: " & to_hstring(cpu_addr_s) &  ": " & to_hstring(cpu_ds_s);
						end if;
						-- synthesis translate_on

						cpu_berr_n_s <= '0';
						bus_state_s <= ERROR;
					 end if;
				elsif (cpu_as_n_s = '0' and cpu_fc_s = 7) then
					cpu_avec_n_s <= '0';
				else
					cpu_avec_n_s <= '1';
				end if;

			when ACK =>
				if (sram_cs_s = '1' and cpu_rw_n_s = '0') then
					sram_we_s(0) <= not cpu_ds_s(0);
					sram_we_s(1) <= not cpu_ds_s(1);
					sram_we_s(2) <= not cpu_ds_s(2);
					sram_we_s(3) <= not cpu_ds_s(3);
				else
					sram_we_s <= (others => '0');
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

				if (bootrom_cs_s = '1' or sram_cs_s = '1' or fb_cs_s = '1') then
					cpu_dsack_n_s <= "00";
				elsif (videoctl_cs_s = '1') then
--						if (fb_rdy_s = '1') then
							cpu_dsack_n_s <= "10";
--						end if;
				else
					cpu_dsack_n_s <= "01";
				end if;

				if (cpu_as_n_s = '1') then
					cpu_dsack_n_s <= "11";
					bus_state_s <= IDLE;
					bootrom_cs_s <= '0';
					fb_cs_s <= '0';
					videorom_cs_s <= '0';
					pmmu_cs_s <= '0';
					ptm_cs_s <= '0';
					hif_cs_s <= '0';
					videoctl_cs_s <= '0';
					sram_cs_s <= '0';
					sram_we_s <= (others => '0');
				 end if;

			when ERROR =>
				cpu_berr_n_s <= '0';
				if (cpu_as_n_s = '1') then
					bus_state_s <= IDLE;
				end if;
		end case;
	end if;
end process;

ledwr: process(reset_s, clk_i)
begin
	if (reset_s = '1') then
		led <= x"ff";
	elsif (rising_edge(clk_i)) then
		if (bus_state_s = IDLE and cpu_rw_n_s = '0' and cpu_addr_s = x"0001ffff") then
			led <= not cpu_data_out_s(7 downto 0);
-- synthesis translate_off
			report "LED: " & to_hstring(cpu_data_out_s(7 downto 0));
-- synthesis translate_on
		end if;
	end if;
end process;

cpu_data_in_s <= bootrom_data_s when bootrom_cs_s = '1' else
		 sram_data_out_s when sram_cs_s = '1' else
		 x"ff" & videorom_data_s & x"ffff" when videorom_cs_s = '1' else
		 fb_data_s & x"ffff" when (fb_cs_s = '1' or videoctl_cs_s = '1') else
		 x"ff" & ptm_data_s & x"ffff" when ptm_cs_s = '1' else
		 x"ff" & hif_data_s & x"ffff" when hif_cs_s = '1' else
		 x"ffffffff";

end rtl;
