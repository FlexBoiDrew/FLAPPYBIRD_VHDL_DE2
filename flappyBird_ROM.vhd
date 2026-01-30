LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY flappyBird_ROM IS
PORT (
    clk           : IN std_logic;
    pixel_row     : IN std_logic_vector(9 DOWNTO 0);
    pixel_col     : IN std_logic_vector(9 DOWNTO 0);
    bird_y, bird_x: IN integer range 0 to 480;
    
    bird_on       : OUT std_logic;
    red, green, blue : OUT std_logic_vector(9 DOWNTO 0)
);
END flappyBird_ROM;

ARCHITECTURE behavior OF flappyBird_ROM IS
    SIGNAL rom_address : std_logic_vector(7 DOWNTO 0);
    SIGNAL rom_q       : std_logic_vector(2 DOWNTO 0); 
    SIGNAL bird_active : std_logic;
    
    -- =======================================================================
    -- CONFIGURATION CONSTANTS (Change these to resize!)
    -- =======================================================================
    CONSTANT SCALE         : integer := 2;  -- Set to 1, 2, 3, 4, etc.
    CONSTANT ORIGINAL_SIZE : integer := 16; -- The size of the image in .mif
    
    -- Automatically calculate the bounding box based on scale
    CONSTANT BIRD_SIZE     : integer := ORIGINAL_SIZE * SCALE; 
    -- =======================================================================
     
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
        address_a : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
        q_a       : OUT STD_LOGIC_VECTOR (2 DOWNTO 0)
    );
    END COMPONENT;

BEGIN
    -- ADDRESS CALCULATION
    PROCESS(pixel_row, pixel_col, bird_y, bird_x)
        VARIABLE r_idx, c_idx : integer;
    BEGIN
        r_idx := CONV_INTEGER(pixel_row) - bird_y;
        c_idx := CONV_INTEGER(pixel_col) - bird_x;

        bird_active <= '0';
        rom_address <= (OTHERS => '0');

        -- Check Dynamic Bounds (BIRD_SIZE scales automatically)
        IF r_idx >= 0 AND r_idx < BIRD_SIZE AND c_idx >= 0 AND c_idx < BIRD_SIZE THEN
            bird_active <= '1';
            
            -- SCALING LOGIC:
            -- (r_idx / SCALE) Slows down the scan to stretch pixels
            -- (* ORIGINAL_SIZE) Jumps to the correct row in memory
            rom_address <= CONV_STD_LOGIC_VECTOR( 
                ((r_idx / SCALE) * ORIGINAL_SIZE) + (c_idx / SCALE), 
                8
            );
        END IF;
    END PROCESS;

    -- MEMORY INSTANCE
    altsyncram_component : altsyncram
    GENERIC MAP (
        operation_mode => "ROM",
        width_a => 3,            -- 3 bits per pixel
        widthad_a => 8,          -- 256 words
        numwords_a => 256,
        lpm_type => "altsyncram",
        width_byteena_a => 1,
        outdata_reg_a => "UNREGISTERED",
        outdata_aclr_a => "NONE",
        address_aclr_a => "NONE",
        clock_enable_input_a => "BYPASS",
        clock_enable_output_a => "BYPASS",
        init_file => "flappyBird.mif",
        intended_device_family => "Cyclone II"
    )
    PORT MAP (
        clock0 => clk,
        address_a => rom_address,
        q_a => rom_q
    );

    -- COLOR DECODER
    PROCESS(bird_active, rom_q)
    BEGIN
        bird_on <= '0';
        red <= (OTHERS => '0'); green <= (OTHERS => '0'); blue <= (OTHERS => '0');

        IF bird_active = '1' THEN
            CASE rom_q IS
                WHEN "001" => -- Black (Outline)
                    bird_on <= '1';
                    red <= "0000000000"; green <= "0000000000"; blue <= "0000000000";
                WHEN "010" => -- White (Eye/Wing)
                    bird_on <= '1';
                    red <= "1111111111"; green <= "1111111111"; blue <= "1111111111";
                WHEN "011" => -- Yellow (Body)
                    bird_on <= '1';
                    red <= "1111111111"; green <= "1111111111"; blue <= "0000000000";
                WHEN "100" => -- Red (Beak)
                    bird_on <= '1';
                    red <= "1111111111"; green <= "0000000000"; blue <= "0000000000";
                WHEN OTHERS => -- Transparent
                    bird_on <= '0';
            END CASE;
        END IF;
    END PROCESS;
END behavior;