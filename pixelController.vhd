library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity pixelController is
    port( 
        pixel_row, pixel_col: in std_logic_vector(9 downto 0);
        is_text_pixel, bird_on, pipes_on : in std_logic;
        game_state : in std_logic_vector(1 downto 0);
        bird_r, bird_g, bird_b, pipes_r, pipes_g, pipes_b : in std_logic_vector(9 downto 0);
        red_out, green_out, blue_out: out std_logic_vector(9 downto 0)
    );
end pixelController;

architecture behavior of pixelController is
    -- COLORS
    constant SKY_R   : std_logic_vector(9 downto 0) := "0000000000";
    constant SKY_G   : std_logic_vector(9 downto 0) := "1100000000"; 
    constant SKY_B   : std_logic_vector(9 downto 0) := "1111111111";
    constant GRASS_R : std_logic_vector(9 downto 0) := "0000000000";
    constant GRASS_G : std_logic_vector(9 downto 0) := "1111111111";
    constant GRASS_B : std_logic_vector(9 downto 0) := "0000000000";
    constant DIRT_R  : std_logic_vector(9 downto 0) := "1111111111";
    constant DIRT_G  : std_logic_vector(9 downto 0) := "1000000000"; 
    constant DIRT_B  : std_logic_vector(9 downto 0) := "0000000000";
    constant WHITE   : std_logic_vector(9 downto 0) := "1111111111";
    constant BLACK   : std_logic_vector(9 downto 0) := "0000000000";
    
    -- Function for Cloud Logic
    function draw_cloud (
        curr_x, curr_y : integer;
        cloud_x, cloud_y : integer)
        return boolean is 
    begin
        if ((curr_x >= cloud_x and curr_x < cloud_x + 60 and curr_y >= cloud_y + 10 and curr_y < cloud_y + 30) or
        (curr_x >= cloud_x + 10 and curr_x < cloud_x + 40 and curr_y >= cloud_y and curr_y < cloud_y + 20)) then
            return true;
        else
            return false;
        end if;
    end function;

begin
    process(pixel_row, pixel_col, game_state, is_text_pixel, bird_on, pipes_on)
        variable x, y : integer;
        variable is_any_cloud : boolean;
    begin
        x := CONV_INTEGER(pixel_col);
        y := CONV_INTEGER(pixel_row);
        is_any_cloud := false;

        -- CLOUD CHECK
        if draw_cloud(x, y, 50, 60) then is_any_cloud := true; end if;
        if draw_cloud(x, y, 200, 100) then is_any_cloud := true; end if;
        if draw_cloud(x, y, 400, 40) then is_any_cloud := true; end if;
        if draw_cloud(x, y, 550, 150) then is_any_cloud := true; end if;

        -------------------------------------------------------------
        -- STATE 01: PLAYING
        -------------------------------------------------------------
        if (game_state = "01") then
            -- 1. TEXT (Score)
            if (is_text_pixel = '1') then
                red_out <= WHITE; green_out <= WHITE; blue_out <= WHITE;
                
            -- 2. BIRD
            elsif (bird_on = '1') then
                red_out <= bird_r; green_out <= bird_g; blue_out <= bird_b;
            
            -- 3. PIPES
            elsif (pipes_on = '1') then 
                red_out <= pipes_r; green_out <= pipes_g; blue_out <= pipes_b;    
            
            -- 4. GROUND
            elsif (pixel_row >= 400) then
                if(pixel_row < 412) then
                    red_out <= GRASS_R; green_out <= GRASS_G; blue_out <= GRASS_B;
                else
                    red_out <= DIRT_R; green_out <= DIRT_G; blue_out <= DIRT_B;
                end if;
                
            -- 5. CLOUDS
            elsif (is_any_cloud = true) then
                red_out <= WHITE; green_out <= WHITE; blue_out <= WHITE;
                
            -- 6. SKY
            else
                red_out <= SKY_R; green_out <= SKY_G; blue_out <= SKY_B;
            end if;
        
        -------------------------------------------------------------
        -- STATE 00: START SCREEN
        -------------------------------------------------------------
        elsif (game_state = "00") then 
            -- Set Background First (Sky Blue)
            red_out   <= SKY_R; 
            green_out <= SKY_G;
            blue_out  <= SKY_B;

            -- Overwrite with Text if active
            if (is_text_pixel = '1') then
                red_out <= WHITE; green_out <= WHITE; blue_out <= WHITE;
            end if;
        
        -------------------------------------------------------------
        -- STATE 10: GAME OVER SCREEN
        -------------------------------------------------------------
        elsif (game_state = "10") then 
            -- Set Background First (Black)
            red_out   <= BLACK;
            green_out <= BLACK;
            blue_out  <= BLACK;

            -- Overwrite with Text if active
            if (is_text_pixel = '1') then
                red_out <= WHITE; green_out <= WHITE; blue_out <= WHITE;
            end if;
        end if;
    end process;
end behavior;