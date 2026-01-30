LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
ENTITY clkdiv 	IS
PORT(
 	  clk_50mhz 				: IN std_logic;
     clk_25mhz					: OUT std_logic); 
END clkdiv;

architecture behavior of clkdiv is
signal temporal_25mhz: STD_LOGIC;

BEGIN
	frequency_divider: process(clk_50mhz)
	BEGIN
		IF rising_edge(clk_50mhz) THEN
			temporal_25mhz <= NOT(temporal_25mhz);
		END IF;
		clk_25mhz <= temporal_25mhz;
	END PROCESS;
END behavior;
