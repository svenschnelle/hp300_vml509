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
	ps2_key_i	: in std_logic_vector(10 downto 0));
end entity hif;

architecture rtl of hif is

signal dbbi_s		: std_logic_vector(7 downto 0);

signal read_s		: std_logic;
signal write_s		: std_logic;
signal last_read_s	: std_logic;
signal last_a0_s	: std_logic;
signal old_ps2_key_s	: std_logic_vector(10 downto 0);
signal key_s		: std_logic_vector(7 downto 0);
signal key_pressed_s	: std_logic;
signal obf_s		: std_logic;
signal f1_s		: std_logic;
signal ctrl_state_s	: std_logic;
signal shift_state_s	: std_logic;

-- upper 4 bits are status
-- lower 8 data

type DBB_BUFFER is array (0 to 7) of std_logic_vector(11 downto 0);
signal dbbo_s		: DBB_BUFFER;
begin
read_s <= cs_i and rwn_i;
write_s <= cs_i and not rwn_i;
nmi_o <= '0';

key_latch: process(clk_i)
begin
	if (rising_edge(clk_i)) then
		case to_integer(unsigned(ps2_key_i(8 downto 0))) is
			when 28 => key_s <= x"70"; -- A
			when 48 => key_s <= x"7c"; -- B
			when 33 => key_s <= x"7a"; -- C
			when 35 => key_s <= x"72"; -- D
			when 36 => key_s <= x"6a"; -- E
			when 43 => key_s <= x"73"; -- F
			when 52 => key_s <= x"74"; -- G
			when 51 => key_s <= x"75"; -- H
			when 67 => key_s <= x"6f"; -- I
			when 59 => key_s <= x"76"; -- J
			when 66 => key_s <= x"66"; -- K
			when 75 => key_s <= x"67"; -- L
			when 58 => key_s <= x"77"; -- M
			when 49 => key_s <= x"7d"; -- N
			when 68 => key_s <= x"64"; -- O
			when 77 => key_s <= x"65"; -- P
			when 21 => key_s <= x"68"; -- Q
			when 45 => key_s <= x"6b"; -- R
			when 27 => key_s <= x"71"; -- S
			when 44 => key_s <= x"6c"; -- T
			when 60 => key_s <= x"6e"; -- U
			when 42 => key_s <= x"7b"; -- V
			when 29 => key_s <= x"69"; -- W
			when 34 => key_s <= x"79"; -- X
			when 53 => key_s <= x"6d"; -- Y
			when 26 => key_s <= x"78"; -- Z
			when 69 => key_s <= x"59"; -- 0
			when 22 => key_s <= x"50"; -- 1
			when 30 => key_s <= x"51"; -- 2
			when 38 => key_s <= x"52"; -- 3
			when 37 => key_s <= x"53"; -- 4
			when 46 => key_s <= x"54"; -- 5
			when 54 => key_s <= x"55"; -- 6
			when 61 => key_s <= x"56"; -- 7
			when 62 => key_s <= x"57"; -- 8
			when 70 => key_s <= x"58"; -- 9
			when 102 => key_s <= x"2e"; -- BS
			when 41 => key_s <= x"63"; -- SPACE
			when 90 => key_s <= x"39"; -- ENTER
			when 5  => key_s <= x"1b"; -- F1
			when 6  => key_s <= x"1c"; -- F2
			when 4  => key_s <= x"20"; -- F3
			when 12 => key_s <= x"21"; -- F4
			when 3  => key_s <= x"1d"; -- F5
			when 11 => key_s <= x"1e"; -- F6
			when 131 => key_s <= x"1f"; -- F7
			when 10 => key_s <= x"24"; -- F8
			when 363 => key_s <= x"26"; -- LEFT CURSOR
			when 372 => key_s <= x"27"; -- RIGHT CURSOR
			when 370 => key_s <= x"22"; -- DOWN CURSOR
			when 373 => key_s <= x"23"; -- UP CURSOR
			when 369 => key_s <= x"2c"; -- DELETE CHAR
			when 368 => key_s <= x"2b"; -- INSERT CHAR
			when 364 => key_s <= x"0e"; -- HOME
			when 381 => key_s <= x"0f"; -- PREV
			when 378 => key_s <= x"10"; -- NEXT
			when 88 => key_s <= x"18"; -- CAPS
			when 13 => key_s <= x"19"; -- TAB
			when 63 => key_s <= x"05"; -- BREAK/RESET
			when 55 => key_s <= x"06"; -- STOP
			when 14 => key_s <= x"01"; -- ~/,
			when 93 => key_s <= x"02"; -- | \
			when 118 => key_s <= x"03"; -- ESC
			when 78 => key_s <= x"5a"; -- -
			when 85 => key_s <= x"5b"; -- =
			when 84 => key_s <= x"5c"; -- [
			when 91 => key_s <= x"5d"; -- ]
			when 76 => key_s <= x"5e"; -- ;
			when 82 => key_s <= x"5f"; -- '
			when 65 => key_s <= x"60"; -- ,
			when 73 => key_s <= x"61"; -- .
			when 74 => key_s <= x"62"; -- /
			when 17 => key_s <= x"7e";
			when 273 => key_s <= x"7f";
			when 303 => key_s <= x"05";
--			when x"00" => key_s <= "x4e"; -- )
--			when x"00" => key_s <= "x4f"; -- ^
--			when x"00" => key_s <= "x4e"; -- )

			when others => key_s <= x"00";
		end case;
		old_ps2_key_s <= ps2_key_i;
		if (old_ps2_key_s /= ps2_key_i) then
			if (ps2_key_i(8 downto 0) = '0' & x"12" or  ps2_key_i(8 downto 0) = '0' & x"59") then
				shift_state_s <= ps2_key_i(9);
			elsif (ps2_key_i(7 downto 0) = x"14") then
				ctrl_state_s <= ps2_key_i(9);
			else
				key_pressed_s <= ps2_key_i(9);
			end if;
		else
			key_pressed_s <= '0';
		end if;
	end if;
end process;

hif_main: process(reset_i, clk_i)

variable dbbo_cnt_v	: integer;

begin
	if (reset_i = '1') then
		obf_s <= '1';
		dbbo_cnt_v := 1;
		dbbo_s(0) <= x"78e";
		irq_o <= '1';
		f1_s <= '1';
	elsif (rising_edge(clk_i)) then
		if (dbbo_cnt_v > 0) then
			obf_s <= '1';
			irq_o <= '1';
		else
			obf_s <= '0';
			irq_o <= '0';
		end if;

		last_read_s <= read_s;
		last_a0_s <= addr_i(1);


		if (key_pressed_s = '1') then
			dbbo_s(0) <= "10" & not ctrl_state_s & not shift_state_s & key_s;
			dbbo_cnt_v := 1;
			irq_o <= '1';
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
