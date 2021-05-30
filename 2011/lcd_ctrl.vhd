library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lcd_ctrl is Port ( 
	clk		: in	STD_LOGIC;
	rst		: in	STD_LOGIC;
	cmd		: in	STD_LOGIC_VECTOR (2 downto 0);
	cmd_valid	: in	STD_LOGIC;
	IROM_Q	: in	STD_LOGIC_VECTOR (7 downto 0);
	IROM_A	: out	STD_LOGIC_VECTOR (5 downto 0);
	IROM_EN	: out	STD_LOGIC;
	busy		: out	STD_LOGIC;
	done		: out	STD_LOGIC;
	IRB_A	: out	STD_LOGIC_VECTOR (5 downto 0);
	IRB_D	: out	STD_LOGIC_VECTOR (7 downto 0);
	IRB_RW	: out	STD_LOGIC);
end lcd_ctrl;

architecture lcd_ctrl_arc of ctrl is

begin


end lcd_ctrl_arc;
