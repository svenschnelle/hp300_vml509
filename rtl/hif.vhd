library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity hif is port(
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
end entity hif;

architecture rtl of hif is

component ps2_keyb is port (
	clk_i		: in std_logic;
	reset_i		: in std_logic;
	ps2_clk_i	: in std_logic;
	ps2_data_i	: in std_logic;
	rx_rdy_o	: out std_logic;
	rx_ack_i	: in std_logic;
	rx_data_o	: out std_logic_vector(7 downto 0)
);
end component;

signal dbbi_s		: std_logic_vector(7 downto 0);

signal read_s		: std_logic;
signal write_s		: std_logic;
signal last_read_s	: std_logic;
signal last_a0_s	: std_logic;
signal old_ps2_key_s	: std_logic_vector(10 downto 0);
signal obf_s		: std_logic;
signal f1_s		: std_logic;
signal ctrl_state_left_s	: std_logic;
signal ctrl_state_right_s	: std_logic;
signal shift_state_left_s	: std_logic;
signal shift_state_right_s	: std_logic;
signal ps2_key_s	: std_logic_vector(7 downto 0);
signal rx_rdy_s		: std_logic;
signal rx_rdy_old_s	: std_logic;
signal rx_ack_s		: std_logic;
signal is_break		: boolean;
signal is_extended	: boolean;

-- upper 4 bits are status
-- lower 8 data

type DBB_BUFFER is array (0 to 7) of std_logic_vector(11 downto 0);
signal dbbo_s		: DBB_BUFFER;

procedure map_scancode(signal scancode: in std_logic_vector(7 downto 0);
		       signal is_extended: in boolean;
		       variable result: out std_logic_vector(7 downto 0)) is
begin
	if (is_extended) then
		case scancode is
			when x"6b" => result := x"26"; -- Left
			when x"74" => result := x"27"; -- Right
			when x"72" => result := x"22"; -- Down
			when x"75" => result := x"23"; -- Up
			when x"71" => result := x"2c"; -- Delete character
			when x"70" => result := x"2b"; -- Insert character
			when x"6c" => result := x"0e"; -- Home
			when x"7d" => result := x"0f"; -- Page up
			when x"7a" => result := x"10"; -- Page down
			when others => result := x"00";
		end case;
	else
		case scancode is
			when x"1c" => result := x"70"; -- A
			when x"32" => result := x"7c"; -- B
			when x"21" => result := x"7a"; -- C
			when x"23" => result := x"72"; -- D
			when x"24" => result := x"6a"; -- E
			when x"2b" => result := x"73"; -- F
			when x"34" => result := x"74"; -- G
			when x"33" => result := x"75"; -- H
			when x"43" => result := x"6f"; -- I
			when x"3b" => result := x"76"; -- J
			when x"42" => result := x"66"; -- K
			when x"4b" => result := x"67"; -- L
			when x"3a" => result := x"77"; -- M
			when x"31" => result := x"7d"; -- N
			when x"44" => result := x"64"; -- O
			when x"4d" => result := x"65"; -- P
			when x"15" => result := x"68"; -- Q
			when x"2d" => result := x"6b"; -- R
			when x"1b" => result := x"71"; -- S
			when x"2c" => result := x"6c"; -- T
			when x"3c" => result := x"6e"; -- U
			when x"2a" => result := x"7b"; -- V
			when x"1d" => result := x"69"; -- W
			when x"22" => result := x"79"; -- X
			when x"35" => result := x"6d"; -- Y
			when x"1a" => result := x"78"; -- Z
			when x"45" => result := x"59"; -- 0
			when x"16" => result := x"50"; -- 1
			when x"1e" => result := x"51"; -- 2
			when x"26" => result := x"52"; -- 3
			when x"25" => result := x"53"; -- 4
			when x"2e" => result := x"54"; -- 5
			when x"36" => result := x"55"; -- 6
			when x"3d" => result := x"56"; -- 7
			when x"3e" => result := x"57"; -- 8
			when x"46" => result := x"58"; -- 9
			when x"66" => result := x"2e"; -- Backspace
			when x"29" => result := x"63"; -- Space
			when x"5a" => result := x"39"; -- Enter
			when x"05" => result := x"1b"; -- F1
			when x"06" => result := x"1c"; -- F2
			when x"04" => result := x"20"; -- F3
			when x"0c" => result := x"21"; -- F4
			when x"03" => result := x"1d"; -- F5
			when x"0b" => result := x"1e"; -- F6
			when x"83" => result := x"1f"; -- F7
			when x"0a" => result := x"24"; -- F8
			when x"0d" => result := x"19"; -- Tab
			when x"7e" => result := x"05"; -- Break/Reset
			when x"76" => result := x"03"; -- ESC
			when x"0e" => result := x"01"; -- ~/, ??
			when x"5d" => result := x"02"; -- | \
			when x"4e" => result := x"5a"; -- -
			when x"55" => result := x"5b"; -- =
			when x"54" => result := x"5c"; -- [
			when x"5b" => result := x"5d"; -- ]
			when x"4c" => result := x"5e"; -- ;
			when x"52" => result := x"5f"; -- '
			when x"41" => result := x"60"; -- ,
			when x"49" => result := x"61"; -- .
			when x"58" => result := x"18"; -- Caps lock
			when others => result := x"00";
		end case;
	end if;
end procedure map_scancode;

begin

ps2_keyb_i: ps2_keyb port map(
	clk_i => clk_i,
	reset_i => reset_i,
	ps2_clk_i => ps2_clk_i,
	ps2_data_i => ps2_data_i,
	rx_rdy_o => rx_rdy_s,
	rx_ack_i => rx_ack_s,
	rx_data_o => ps2_key_s
);

read_s <= cs_i and rwn_i;
write_s <= cs_i and not rwn_i;
nmi_o <= '0';

hif_main: process(reset_i, clk_i)

variable dbbo_cnt_v	: integer;
variable scancode	: std_logic_vector(7 downto 0);
begin
	if (reset_i = '1') then
		obf_s <= '1';
		dbbo_cnt_v := 1;
		dbbo_s(0) <= x"78e";
		irq_o <= '1';
		f1_s <= '1';
		is_break <= false;
		is_extended <= false;
		ctrl_state_left_s <= '0';
		ctrl_state_right_s <= '0';
		shift_state_left_s <= '0';
		shift_state_right_s <= '0';
	elsif (rising_edge(clk_i)) then
		rx_ack_s <= rx_rdy_s;
		rx_rdy_old_s <= rx_rdy_s;

		if (dbbo_cnt_v > 0) then
			obf_s <= '1';
			irq_o <= '1';
		else
			obf_s <= '0';
			irq_o <= '0';
		end if;

		last_read_s <= read_s;
		last_a0_s <= addr_i(1);

		if (rx_rdy_old_s = '0' and rx_rdy_s = '1') then
			if (ps2_key_s = x"f0") then
				is_break <= true;
			elsif (ps2_key_s = x"e0") then
				is_extended <= true;
			elsif (ps2_key_s = x"12" and not is_extended) then
				if (is_break) then
					shift_state_left_s <= '0';
				else
					shift_state_left_s <= '1';
				end if;
				is_break <= false;
			elsif (ps2_key_s = x"59" and not is_extended) then
				if (is_break) then
					shift_state_right_s <= '0';
				else
					shift_state_right_s <= '1';
				end if;
				is_break <= false;
			elsif (ps2_key_s = x"14"and not is_extended) then
				if (is_break) then
					ctrl_state_left_s <= '0';
				else
					ctrl_state_left_s <= '1';
				end if;
				is_break <= false;
			elsif (ps2_key_s = x"11" and not is_extended) then
				if (is_break) then
					ctrl_state_right_s <= '0';
				else
					ctrl_state_right_s <= '1';
				end if;
				is_break <= false;
			else
				if (not is_break) then
					map_scancode(ps2_key_s, is_extended, scancode);
					dbbo_s(0) <= "10" & not (ctrl_state_left_s or ctrl_state_right_s) &
						     not (shift_state_left_s or shift_state_right_s) & scancode;
					dbbo_cnt_v := 1;
					irq_o <= '1';
				end if;
				is_break <= false;
				is_extended <= false;
			end if;
		end if;

		if (read_s = '1') then
			if (addr_i(1) = '1') then
				-- status read
				if (dbbo_cnt_v > 0) then
					db_o <= dbbo_s(dbbo_cnt_v - 1)(11 downto 8) & f1_s & "00" & obf_s;
				else
					db_o <= x"7" & f1_s & "00" & obf_s;
				end if;
				irq_o <= '0';
			else
				-- data read
				if (dbbo_cnt_v > 0) then
					db_o <= dbbo_s(dbbo_cnt_v - 1)(7 downto 0);
				end if;
			end if;
		end if;

		if (write_s = '1') then
			if (addr_i(1) = '1') then
				-- command write
				f1_s <= '1';
				case db_i is
					when x"31" =>
--						dbbo[0] <= 1;
--						dbbo[1] <= 0;
--						dbbo[2] <= 0;
--						dbbo[3] <= 0;
--						dbbo_cnt <= 0;
					when x"11" =>
						-- configuration code
						dbbo_s(0) <= x"428";
						dbbo_cnt_v := 1;
						irq_o <= '1';

					when x"12" =>
						-- language code, return US-ASCII
						dbbo_s(0) <= x"41f";
						dbbo_cnt_v := 1;
						irq_o <= '1';

					when x"f9" => -- kbdsadr
						dbbo_s(0) <= x"401"; -- one HIL device
						dbbo_cnt_v := 1;
						irq_o <= '1';

					when x"fa" => -- lpstat
						dbbo_s(0) <= x"409"; -- one HIL device (bits 2 - 0), successful link config
						dbbo_cnt_v := 1;
						irq_o <= '1';

					when x"fe" => -- extended config
						dbbo_s(0) <= x"413"; -- no BBRTC, no SOUND, 1820-4784
						dbbo_cnt_v := 1;
						irq_o <= '1';

					when others =>
						dbbo_s(0) <= x"400";
						dbbo_cnt_v := 1;
						irq_o <= '1';
				end case;
			else
				-- data write
				f1_s <= '0';
				dbbi_s <= db_i;
				--	ibf <= 1;
			end if;
		end if;
		if (last_read_s = '1' and read_s = '0' and last_a0_s = '0') then
			if (dbbo_cnt_v > 0) then
				dbbo_cnt_v := dbbo_cnt_v - 1;
			end if;
		end if;
	end if;
end process;
end rtl;
