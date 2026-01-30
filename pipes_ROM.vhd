LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY pipes_ROM IS
PORT (
    clk         : IN std_logic;
    pixel_row   : IN std_logic_vector(9 DOWNTO 0);
    pixel_col   : IN std_logic_vector(9 DOWNTO 0);
    pipe1_y, pipe1_x : IN integer range -100 to 2000;

    pipes_on    : OUT std_logic;
    red         : OUT std_logic_vector(9 DOWNTO 0);
    green       : OUT std_logic_vector(9 DOWNTO 0);
    blue        : OUT std_logic_vector(9 DOWNTO 0);
	 
    pipe2_x, pipe2_y : IN integer range -100 to 2000;
    pipe3_x, pipe3_y : IN integer range -100 to 2000

);
END pipes_ROM;

ARCHITECTURE behavior OF pipes_ROM IS

    SIGNAL rom_address : std_logic_vector(12 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rom_q       : std_logic_vector(2 DOWNTO 0);
    SIGNAL pipes_active: std_logic := '0';
    
    CONSTANT GAP_SIZE : integer := 200; 
    CONSTANT PIPE_H   : integer := 256; 
    CONSTANT MIF_H    : integer := 128; 

    COMPONENT altsyncram
    GENERIC (
        operation_mode         : STRING;
        width_a                : NATURAL;
        widthad_a              : NATURAL;
        numwords_a             : NATURAL;
        lpm_type               : STRING;
        width_byteena_a        : NATURAL;
        outdata_reg_a          : STRING;
        outdata_aclr_a         : STRING;
        address_aclr_a         : STRING;
        clock_enable_input_a   : STRING;
        clock_enable_output_a  : STRING;
        init_file              : STRING;
        intended_device_family : STRING
    );
    PORT (
        clock0    : IN STD_LOGIC ;
        address_a : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
        q_a       : OUT STD_LOGIC_VECTOR (2 DOWNTO 0)
    );
    END COMPONENT;

BEGIN

    PROCESS(pixel_row, pixel_col, pipe1_x, pipe1_y, pipe2_x, pipe2_y, pipe3_x, pipe3_y)
        VARIABLE curr_px, curr_py : integer;
        VARIABLE c_idx, r_idx_bottom, r_idx_top : integer;
        VARIABLE row_to_read, addr_int : integer;
        VARIABLE found_pipe : boolean;
    BEGIN
        pipes_active <= '0';
        rom_address <= (OTHERS => '0');
        found_pipe := false;

        -- CHECK ALL 3 PIPES
        FOR i IN 1 TO 3 LOOP
            IF NOT found_pipe THEN
                -- Select current pipe coordinates
                IF i = 1 THEN curr_px := pipe1_x; curr_py := pipe1_y;
                ELSIF i = 2 THEN curr_px := pipe2_x; curr_py := pipe2_y;
                ELSE curr_px := pipe3_x; curr_py := pipe3_y;
                END IF;

                c_idx := CONV_INTEGER(pixel_col) - curr_px;

                -- Horizontal Check
                IF (c_idx >= 0) AND (c_idx < 52) THEN
                    
                    -- BOTTOM PIPE
                    r_idx_bottom := CONV_INTEGER(pixel_row) - curr_py;
                    
                    IF (r_idx_bottom >= 0) AND (r_idx_bottom < PIPE_H) THEN
                        pipes_active <= '1';
                        found_pipe := true;
                        
                        -- STRETCH LOGIC (Bottom)
                        IF r_idx_bottom >= MIF_H THEN row_to_read := MIF_H - 1;
                        ELSE row_to_read := r_idx_bottom;
                        END IF;
                        
                        addr_int := (row_to_read * 52) + c_idx;
                        rom_address <= CONV_STD_LOGIC_VECTOR(addr_int, 13);
                        
                    ELSE
                        -- TOP PIPE
                        r_idx_top := (curr_py - GAP_SIZE) - CONV_INTEGER(pixel_row);
                        
                        IF (r_idx_top >= 0) AND (r_idx_top < PIPE_H) THEN
                            pipes_active <= '1';
                            found_pipe := true;
                            
                            -- STRETCH LOGIC (Top)
                            IF r_idx_top >= MIF_H THEN row_to_read := MIF_H - 1;
                            ELSE row_to_read := r_idx_top;
                            END IF;
                            
                            addr_int := (row_to_read * 52) + c_idx;
                            rom_address <= CONV_STD_LOGIC_VECTOR(addr_int, 13);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    END PROCESS;

    altsyncram_component : altsyncram
    GENERIC MAP (
        operation_mode => "ROM", width_a => 3, widthad_a => 13, numwords_a => 8192, 
        lpm_type => "altsyncram", width_byteena_a => 1, outdata_reg_a => "UNREGISTERED", 
        outdata_aclr_a => "NONE", address_aclr_a => "NONE", 
        clock_enable_input_a => "BYPASS", clock_enable_output_a => "BYPASS",
        init_file => "pipes.mif", intended_device_family => "Cyclone II"
    )
    PORT MAP ( clock0 => clk, address_a => rom_address, q_a => rom_q );

    PROCESS(pipes_active, rom_q)
    BEGIN
        pipes_on <= '0';
        red <= (OTHERS => '0'); green <= (OTHERS => '0'); blue <= (OTHERS => '0');
        IF pipes_active = '1' THEN
            CASE rom_q IS
                WHEN "101" => pipes_on <= '1'; red <= "0000000000"; green <= "0011001100"; blue <= "0000000000";
                WHEN "110" => pipes_on <= '1'; red <= "0000000000"; green <= "1111111111"; blue <= "0000000000";
                WHEN "010" => pipes_on <= '1'; red <= "1111111111"; green <= "1111111111"; blue <= "1111111111";
                WHEN OTHERS => pipes_on <= '0';
            END CASE;
        END IF;
    END PROCESS;
END behavior;