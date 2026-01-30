LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY physicsEngine IS 
    PORT(
        vert_sync, buttonPress : IN std_logic;
        
        bird_x, bird_y : OUT integer range 0 to 480;
        pipe1_x, pipe1_y : OUT integer range -100 to 2000;
        
        game_state : BUFFER std_logic_vector(1 downto 0);
        current_score : BUFFER integer range 0 to 999;
          
        pipe2_x, pipe2_y : OUT integer range -100 to 2000;
        pipe3_x, pipe3_y : OUT integer range -100 to 2000
    );
END physicsEngine;

ARCHITECTURE behavior OF physicsEngine IS

    SIGNAL b_x : integer range 0 to 480 := 100;
    SIGNAL b_y : integer range 0 to 480 := 240;
    SIGNAL velocity : integer range -50 to 50 := 0;
    
    SIGNAL gravity_counter : integer range 0 to 5 := 0;

    -- MULTIPLE PIPES SETUP
    TYPE pipe_array IS ARRAY (0 TO 2) OF integer range -100 to 2000;
    TYPE height_array IS ARRAY (0 TO 2) OF integer range 0 to 480;
    
    SIGNAL pipes_x_pos : pipe_array := (640, 890, 1140);
    SIGNAL pipes_y_pos : height_array := (300, 250, 350); 

    SIGNAL score        : integer range 0 to 999 := 0;
    SIGNAL curr_game_state : std_logic_vector(1 downto 0) := "00";
    SIGNAL collision : std_logic := '0';
    SIGNAL last_buttonPress : std_logic := '1';
    
    -- POWER ON RESET COUNTER
    -- Forces the game to reset for the first 15 frames (approx 0.25s)
    SIGNAL power_on_delay : integer range 0 to 20 := 0;
    
    CONSTANT GRAVITY       : integer := 1;
    CONSTANT FLAP_STRENGTH : integer := -5;
    CONSTANT PIPE_SPEED    : integer := 3;
    CONSTANT PIPE_WIDTH    : integer := 52;
    CONSTANT BIRD_SIZE     : integer := 48;
    CONSTANT GAP_SIZE      : integer := 200;
    CONSTANT PIPE_SPACING  : integer := 250;

BEGIN

    PROCESS(vert_sync)
        VARIABLE i : integer;
    BEGIN
        IF rising_edge(vert_sync) THEN
            -- Update Input History (Always track button to prevent glitches)
            last_buttonPress <= buttonPress;

            -- POWER ON RESET LOGIC
            -- If the FPGA just turned on, force everything to reset for a moment
            IF power_on_delay < 15 THEN
                power_on_delay <= power_on_delay + 1;
                
                -- FORCE START STATE
                curr_game_state <= "00";
                b_y <= 240;
                velocity <= 0;
                score <= 0;
                collision <= '0';
                pipes_x_pos(0) <= 640;
                pipes_x_pos(1) <= 640 + PIPE_SPACING;
                pipes_x_pos(2) <= 640 + (PIPE_SPACING * 2);
                pipes_y_pos <= (300, 250, 350);

            ELSE
                -- Normal Game Logic (Only runs after power-on delay finishes)
                
                -----------------------------------------------------------
                -- STATE 00: START SCREEN
                -----------------------------------------------------------
                IF (curr_game_state = "00") THEN
                    b_y <= 240;
                    velocity <= 0;
                    score <= 0;
                    collision <= '0';
                    pipes_x_pos(0) <= 640;
                    pipes_x_pos(1) <= 640 + PIPE_SPACING;
                    pipes_x_pos(2) <= 640 + (PIPE_SPACING * 2);
                    
                    -- Start Game on Button Press (Falling Edge)
                    IF (last_buttonPress = '1' AND buttonPress = '0') THEN
                        curr_game_state <= "01";
                        velocity <= FLAP_STRENGTH; 
                    END IF;

                -----------------------------------------------------------
                -- STATE 01: PLAYING
                -----------------------------------------------------------
                ELSIF (curr_game_state = "01") THEN -- State 01: Playing
                    
                    -- FLAP LOGIC
						  -- Check for new button press
                    IF (last_buttonPress = '1' AND buttonPress = '0') THEN 
								-- If new button pressed, jump
                        velocity <= FLAP_STRENGTH;
								-- Resets gravity counter
                        gravity_counter <= 0; 
								
						  -- While the player is not hitting jump button	
                    ELSE
								-- Wait to apply gravity every 3rd frame (0,1,2)
                        IF gravity_counter >= 2 THEN
								    -- If the bird is not already falling very fast
                            IF velocity < 15 THEN
										  -- Apply gravity to the bird
										  -- Acts as acceleration
                                velocity <= velocity + GRAVITY;
                            END IF;
									 -- Reset gravity counter
                            gravity_counter <= 0;
                        ELSE
									 -- Increment counter if it is not = 2 or the button is not pressed
                            gravity_counter <= gravity_counter + 1;
                        END IF;
                    END IF;

                    -- 2. Bird Physics
                    b_y <= b_y + velocity;
                    if b_y < 0 then b_y <= 0; velocity <= 0;
                    elsif b_y > (480 - BIRD_SIZE) then b_y <= 480 - BIRD_SIZE; collision <= '1'; end if;

                    -- PIPE LOGIC
						  -- For each pipe (3)
                    FOR i IN 0 TO 2 LOOP
								-- If the pipe is have moved across left side of screen
                        IF pipes_x_pos(i) <= -PIPE_WIDTH THEN
									 -- Move it back to the right side of the screen 
									 -- Use spacing so the pipes are spread out enough
                            pipes_x_pos(i) <= pipes_x_pos(i) + (PIPE_SPACING * 3);
									 
									 -- "Randomize" pipes
									 -- Cycles through 3 different pipe heights
                            if pipes_y_pos(i) = 300 then 
										pipes_y_pos(i) <= 250;
                            elsif pipes_y_pos(i) = 250 then 
										pipes_y_pos(i) <= 350;
                            else pipes_y_pos(i) <= 300; end if;
									 
                        ELSE
									 -- If pipe is still on screen, move it left at pipe speed
                            pipes_x_pos(i) <= pipes_x_pos(i) - PIPE_SPEED;
                        END IF;

                        IF (pipes_x_pos(i) + PIPE_WIDTH < b_x) AND (pipes_x_pos(i) + PIPE_WIDTH >= b_x - PIPE_SPEED) THEN
                            score <= score + 1;
                        END IF;

                        IF (b_x + BIRD_SIZE > pipes_x_pos(i)) AND (b_x < pipes_x_pos(i) + PIPE_WIDTH) THEN
                            IF (b_y + BIRD_SIZE > pipes_y_pos(i)) OR (b_y < pipes_y_pos(i) - GAP_SIZE) THEN
                                collision <= '1';
                            END IF;
                        END IF;
                    END LOOP;

                    IF collision = '1' THEN curr_game_state <= "10"; END IF;

                -----------------------------------------------------------
                -- STATE 10: GAME OVER
                -----------------------------------------------------------
                ELSIF (curr_game_state = "10") THEN
                    -- Restart Game (Edge Detection)
                    IF (last_buttonPress = '1' AND buttonPress = '0') THEN 
                        curr_game_state <= "00";
                    END IF;
                END IF;
            END IF; -- End of Power On Check
            
        END IF; 
    END PROCESS;

    bird_x <= b_x; bird_y <= b_y;
    pipe1_x <= pipes_x_pos(0); pipe1_y <= pipes_y_pos(0);
    pipe2_x <= pipes_x_pos(1); pipe2_y <= pipes_y_pos(1);
    pipe3_x <= pipes_x_pos(2); pipe3_y <= pipes_y_pos(2);
    
    current_score <= score; game_state <= curr_game_state;

END behavior;