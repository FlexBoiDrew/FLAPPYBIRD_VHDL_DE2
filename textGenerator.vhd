LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY textGenerator IS
    PORT ( 
        Pixel_row     : IN std_logic_vector(9 downto 0);
        Pixel_col     : IN std_logic_vector(9 downto 0); 
        current_score : IN integer range 0 to 999;
        game_state    : IN std_logic_vector(1 downto 0);
        Char_address  : OUT std_logic_vector (5 downto 0);
        Font_row      : OUT std_logic_vector (2 downto 0);
        Font_col      : OUT std_logic_vector (2 downto 0)
    );
END textGenerator;

ARCHITECTURE xyz OF textGenerator IS
BEGIN
    PROCESS (Pixel_Row, Pixel_Col, current_score, game_state)
        VARIABLE score_hunds : integer;
        VARIABLE score_tens  : integer;
        VARIABLE score_ones  : integer;
        VARIABLE score_int   : integer;
        -- Helper variable to fix the alignment/smooshing issues
        VARIABLE relative_col : std_logic_vector(9 downto 0);
    BEGIN
        -- Defaults (Transparent Space)
        Char_address <= CONV_STD_LOGIC_VECTOR(32,6); 
        
        -- Default Scaling (1x)
        Font_row     <= Pixel_row(2 downto 0);
        Font_col     <= Pixel_col(2 downto 0);

        score_int    := current_score;
        score_hunds := score_int / 100;
        score_tens  := (score_int / 10) mod 10;
        score_ones  := score_int mod 10;

        -----------------------------------------------------------------------
        -- STATE 01: PLAYING (Scoreboard - Top Left)
        -----------------------------------------------------------------------
        IF game_state = "01" THEN
            -- 2x SCALING
            Font_row <= Pixel_row(3 downto 1);
            Font_col <= Pixel_col(3 downto 1); -- Starts at 16, which aligns with bit 3, so no math needed

            IF Pixel_row >= 16 AND Pixel_row <= 31 THEN
                IF    Pixel_col >= 16  AND Pixel_col <= 31  THEN Char_address <= CONV_STD_LOGIC_VECTOR(83,6); -- S
                ELSIF Pixel_col >= 32  AND Pixel_col <= 47  THEN Char_address <= CONV_STD_LOGIC_VECTOR(67,6); -- C
                ELSIF Pixel_col >= 48  AND Pixel_col <= 63  THEN Char_address <= CONV_STD_LOGIC_VECTOR(79,6); -- O
                ELSIF Pixel_col >= 64  AND Pixel_col <= 79  THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R
                ELSIF Pixel_col >= 80  AND Pixel_col <= 95  THEN Char_address <= CONV_STD_LOGIC_VECTOR(69,6); -- E
                ELSIF Pixel_col >= 96  AND Pixel_col <= 111 THEN Char_address <= CONV_STD_LOGIC_VECTOR(58,6); -- :
                ELSIF Pixel_col >= 112 AND Pixel_col <= 127 THEN Char_address <= CONV_STD_LOGIC_VECTOR(32,6); -- space
                ELSIF Pixel_col >= 128 AND Pixel_col <= 143 THEN Char_address <= CONV_STD_LOGIC_VECTOR(48 + score_hunds,6); 
                ELSIF Pixel_col >= 144 AND Pixel_col <= 159 THEN Char_address <= CONV_STD_LOGIC_VECTOR(48 + score_tens,6);
                ELSIF Pixel_col >= 160 AND Pixel_col <= 175 THEN Char_address <= CONV_STD_LOGIC_VECTOR(48 + score_ones,6);
                END IF;
            END IF;
        END IF;

        -----------------------------------------------------------------------
        -- STATE 00: START SCREEN
        -----------------------------------------------------------------------
        IF game_state = "00" THEN
            
            -- "START" (8x Scaling)
            -- Start X is 160. 
            IF Pixel_row >= 192 AND Pixel_row <= 255 THEN
                Font_row <= Pixel_row(5 downto 3);
                -- FIX: Subtract 160 to realign bits to 0
                relative_col := Pixel_col - 160; 
                Font_col <= relative_col(5 downto 3);

                IF    Pixel_col >= 160 AND Pixel_col <= 223 THEN Char_address <= CONV_STD_LOGIC_VECTOR(83,6); -- S
                ELSIF Pixel_col >= 224 AND Pixel_col <= 287 THEN Char_address <= CONV_STD_LOGIC_VECTOR(84,6); -- T
                ELSIF Pixel_col >= 288 AND Pixel_col <= 351 THEN Char_address <= CONV_STD_LOGIC_VECTOR(65,6); -- A
                ELSIF Pixel_col >= 352 AND Pixel_col <= 415 THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R
                ELSIF Pixel_col >= 416 AND Pixel_col <= 479 THEN Char_address <= CONV_STD_LOGIC_VECTOR(84,6); -- T
                END IF;

            -- "GAME" (8x Scaling)
            -- Start X is 192. (192 aligns perfectly with bit 6, so usually safe, but let's be consistent)
            ELSIF Pixel_row >= 256 AND Pixel_row <= 319 THEN
                Font_row <= Pixel_row(5 downto 3);
                relative_col := Pixel_col - 192;
                Font_col <= relative_col(5 downto 3);

                IF    Pixel_col >= 192 AND Pixel_col <= 255 THEN Char_address <= CONV_STD_LOGIC_VECTOR(71,6); -- G
                ELSIF Pixel_col >= 256 AND Pixel_col <= 319 THEN Char_address <= CONV_STD_LOGIC_VECTOR(65,6); -- A
                ELSIF Pixel_col >= 320 AND Pixel_col <= 383 THEN Char_address <= CONV_STD_LOGIC_VECTOR(77,6); -- M
                ELSIF Pixel_col >= 384 AND Pixel_col <= 447 THEN Char_address <= CONV_STD_LOGIC_VECTOR(69,6); -- E
                END IF;

            -- "PRESS TO PLAY" (2x Scaling)
            -- Start X is 216. 
            ELSIF Pixel_row >= 464 AND Pixel_row <= 479 THEN
                Font_row <= Pixel_row(3 downto 1);
                -- FIX: Subtract 216 to realign bits to 0
                relative_col := Pixel_col - 216;
                Font_col <= relative_col(3 downto 1);

                IF    Pixel_col >= 216 AND Pixel_col <= 231 THEN Char_address <= CONV_STD_LOGIC_VECTOR(80,6); -- P
                ELSIF Pixel_col >= 232 AND Pixel_col <= 247 THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R
                ELSIF Pixel_col >= 248 AND Pixel_col <= 263 THEN Char_address <= CONV_STD_LOGIC_VECTOR(69,6); -- E
                ELSIF Pixel_col >= 264 AND Pixel_col <= 279 THEN Char_address <= CONV_STD_LOGIC_VECTOR(83,6); -- S
                ELSIF Pixel_col >= 280 AND Pixel_col <= 295 THEN Char_address <= CONV_STD_LOGIC_VECTOR(83,6); -- S

                ELSIF Pixel_col >= 296 AND Pixel_col <= 311 THEN Char_address <= CONV_STD_LOGIC_VECTOR(32,6); -- space

                ELSIF Pixel_col >= 312 AND Pixel_col <= 327 THEN Char_address <= CONV_STD_LOGIC_VECTOR(84,6); -- T
                ELSIF Pixel_col >= 328 AND Pixel_col <= 343 THEN Char_address <= CONV_STD_LOGIC_VECTOR(79,6); -- O

                ELSIF Pixel_col >= 344 AND Pixel_col <= 359 THEN Char_address <= CONV_STD_LOGIC_VECTOR(32,6); -- space

                ELSIF Pixel_col >= 360 AND Pixel_col <= 375 THEN Char_address <= CONV_STD_LOGIC_VECTOR(80,6); -- P
                ELSIF Pixel_col >= 376 AND Pixel_col <= 391 THEN Char_address <= CONV_STD_LOGIC_VECTOR(76,6); -- L
                ELSIF Pixel_col >= 392 AND Pixel_col <= 407 THEN Char_address <= CONV_STD_LOGIC_VECTOR(65,6); -- A
                ELSIF Pixel_col >= 408 AND Pixel_col <= 423 THEN Char_address <= CONV_STD_LOGIC_VECTOR(89,6); -- Y
                END IF;
            END IF;
        END IF;

        -----------------------------------------------------------------------
        -- STATE 10: GAME OVER
        -----------------------------------------------------------------------
        IF game_state = "10" THEN

            -- "GAME" (8x Scaling)
            -- Start X is 192.
            IF Pixel_row >= 192 AND Pixel_row <= 255 THEN 
                Font_row <= Pixel_row(5 downto 3);
                relative_col := Pixel_col - 192;
                Font_col <= relative_col(5 downto 3);
                
                IF    Pixel_col >= 192 AND Pixel_col <= 255 THEN Char_address <= CONV_STD_LOGIC_VECTOR(71,6); -- G
                ELSIF Pixel_col >= 256 AND Pixel_col <= 319 THEN Char_address <= CONV_STD_LOGIC_VECTOR(65,6); -- A
                ELSIF Pixel_col >= 320 AND Pixel_col <= 383 THEN Char_address <= CONV_STD_LOGIC_VECTOR(77,6); -- M
                ELSIF Pixel_col >= 384 AND Pixel_col <= 447 THEN Char_address <= CONV_STD_LOGIC_VECTOR(69,6); -- E
                END IF;
            END IF;

            -- "OVER" (8x Scaling)
            -- Start X is 192.
            IF Pixel_row >= 256 AND Pixel_row <= 319 THEN 
                Font_row <= Pixel_row(5 downto 3);
                relative_col := Pixel_col - 192;
                Font_col <= relative_col(5 downto 3);

                IF    Pixel_col >= 192 AND Pixel_col <= 255 THEN Char_address <= CONV_STD_LOGIC_VECTOR(79,6); -- O
                ELSIF Pixel_col >= 256 AND Pixel_col <= 319 THEN Char_address <= CONV_STD_LOGIC_VECTOR(86,6); -- V
                ELSIF Pixel_col >= 320 AND Pixel_col <= 383 THEN Char_address <= CONV_STD_LOGIC_VECTOR(69,6); -- E
                ELSIF Pixel_col >= 384 AND Pixel_col <= 447 THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R
                END IF;
            END IF;

            -- "YOUR SCORE: ###" (2x Scaling)
            -- Start X is 200.
            IF Pixel_row >= 448 AND Pixel_row <= 463 THEN 
                Font_row <= Pixel_row(3 downto 1);
                -- FIX: Subtract 200 to realign bits to 0
                relative_col := Pixel_col - 200;
                Font_col <= relative_col(3 downto 1);

                IF    Pixel_col >= 200 AND Pixel_col <= 215 THEN Char_address <= CONV_STD_LOGIC_VECTOR(89,6); -- Y
                ELSIF Pixel_col >= 216 AND Pixel_col <= 231 THEN Char_address <= CONV_STD_LOGIC_VECTOR(79,6); -- O
                ELSIF Pixel_col >= 232 AND Pixel_col <= 247 THEN Char_address <= CONV_STD_LOGIC_VECTOR(85,6); -- U
                ELSIF Pixel_col >= 248 AND Pixel_col <= 263 THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R

                ELSIF Pixel_col >= 264 AND Pixel_col <= 279 THEN Char_address <= CONV_STD_LOGIC_VECTOR(32,6); -- space

                ELSIF Pixel_col >= 280 AND Pixel_col <= 295 THEN Char_address <= CONV_STD_LOGIC_VECTOR(83,6); -- S
                ELSIF Pixel_col >= 296 AND Pixel_col <= 311 THEN Char_address <= CONV_STD_LOGIC_VECTOR(67,6); -- C
                ELSIF Pixel_col >= 312 AND Pixel_col <= 327 THEN Char_address <= CONV_STD_LOGIC_VECTOR(79,6); -- O
                ELSIF Pixel_col >= 328 AND Pixel_col <= 343 THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R
                ELSIF Pixel_col >= 344 AND Pixel_col <= 359 THEN Char_address <= CONV_STD_LOGIC_VECTOR(69,6); -- E
                ELSIF Pixel_col >= 360 AND Pixel_col <= 375 THEN Char_address <= CONV_STD_LOGIC_VECTOR(58,6); -- :

                ELSIF Pixel_col >= 376 AND Pixel_col <= 391 THEN Char_address <= CONV_STD_LOGIC_VECTOR(32,6); -- space
                ELSIF Pixel_col >= 392 AND Pixel_col <= 407 THEN Char_address <= CONV_STD_LOGIC_VECTOR(48 + score_hunds,6); 
                ELSIF Pixel_col >= 408 AND Pixel_col <= 423 THEN Char_address <= CONV_STD_LOGIC_VECTOR(48 + score_tens,6);
                ELSIF Pixel_col >= 424 AND Pixel_col <= 439 THEN Char_address <= CONV_STD_LOGIC_VECTOR(48 + score_ones,6);
                END IF;
            END IF;

            -- "PRESS TO RESTART" (2x Scaling)
            -- Start X is 192.
            IF Pixel_row >= 464 AND Pixel_row <= 479 THEN 
                Font_row <= Pixel_row(3 downto 1);
                -- FIX: Subtract 192 to be safe
                relative_col := Pixel_col - 192;
                Font_col <= relative_col(3 downto 1);
                
                IF    Pixel_col >= 192 AND Pixel_col <= 207 THEN Char_address <= CONV_STD_LOGIC_VECTOR(80,6); -- P
                ELSIF Pixel_col >= 208 AND Pixel_col <= 223 THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R
                ELSIF Pixel_col >= 224 AND Pixel_col <= 239 THEN Char_address <= CONV_STD_LOGIC_VECTOR(69,6); -- E
                ELSIF Pixel_col >= 240 AND Pixel_col <= 255 THEN Char_address <= CONV_STD_LOGIC_VECTOR(83,6); -- S
                ELSIF Pixel_col >= 256 AND Pixel_col <= 271 THEN Char_address <= CONV_STD_LOGIC_VECTOR(83,6); -- S

                ELSIF Pixel_col >= 272 AND Pixel_col <= 287 THEN Char_address <= CONV_STD_LOGIC_VECTOR(32,6); -- space

                ELSIF Pixel_col >= 288 AND Pixel_col <= 303 THEN Char_address <= CONV_STD_LOGIC_VECTOR(84,6); -- T
                ELSIF Pixel_col >= 304 AND Pixel_col <= 319 THEN Char_address <= CONV_STD_LOGIC_VECTOR(79,6); -- O

                ELSIF Pixel_col >= 320 AND Pixel_col <= 335 THEN Char_address <= CONV_STD_LOGIC_VECTOR(32,6); -- space

                ELSIF Pixel_col >= 336 AND Pixel_col <= 351 THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R
                ELSIF Pixel_col >= 352 AND Pixel_col <= 367 THEN Char_address <= CONV_STD_LOGIC_VECTOR(69,6); -- E
                ELSIF Pixel_col >= 368 AND Pixel_col <= 383 THEN Char_address <= CONV_STD_LOGIC_VECTOR(83,6); -- S
                ELSIF Pixel_col >= 384 AND Pixel_col <= 399 THEN Char_address <= CONV_STD_LOGIC_VECTOR(84,6); -- T
                ELSIF Pixel_col >= 400 AND Pixel_col <= 415 THEN Char_address <= CONV_STD_LOGIC_VECTOR(65,6); -- A
                ELSIF Pixel_col >= 416 AND Pixel_col <= 431 THEN Char_address <= CONV_STD_LOGIC_VECTOR(82,6); -- R
                ELSIF Pixel_col >= 432 AND Pixel_col <= 447 THEN Char_address <= CONV_STD_LOGIC_VECTOR(84,6); -- T
                END IF;
            END IF;
        END IF;

    END PROCESS;
END xyz;