LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ball IS
    PORT (
        clk         : in std_logic;
        v_sync      : IN STD_LOGIC;
        pixel_row   : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col   : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        red         : OUT STD_LOGIC;
        green       : OUT STD_LOGIC;
        blue        : OUT STD_LOGIC;
        zom_enable  : IN STD_LOGIC;  -- Enable zombie
        zom_damage  : IN STD_LOGIC;          
        attack      : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        zom_alive   : OUT integer;
        zom_health  : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        zom_loc_x     : OUT Integer range 0 to 1023;
        zom_loc_y     : OUT Integer range 0 to 1023;
        offset      : in Integer range 0 to 1023;
        start_x        : in integer;
        start_y         : in integer;
        hit_count       : in integer range 0 to 1023;
        hard            : in std_logic
    );
END ball;

ARCHITECTURE Behavioral OF ball IS
    CONSTANT size  : INTEGER := 20;
    SIGNAL ball_on : STD_LOGIC;
    
    -- Position signals
    SIGNAL ball_x  : INTEGER RANGE 0 TO 1023;
    signal ball_x_display : integer range 0 to 1023;
    SIGNAL ball_y  : INTEGER RANGE 0 TO 1023;
    SIGNAL ball_x_motion : INTEGER := -1;  -- Move left
    SIGNAL initialized    : STD_LOGIC := '0';
    
    -- Health management
    CONSTANT MAX_HEALTH     : INTEGER := 200;
    SIGNAL zcurrent_health  : INTEGER RANGE 0 TO 1023 := MAX_HEALTH;
    SIGNAL zalive_internal  : STD_LOGIC := '0';
    
    -- Frame counter for slower movement
    SIGNAL frame_count : INTEGER RANGE 0 TO 15 := 0;
    CONSTANT zombie_WIDTH  : INTEGER := 55;  -- pixels wide
    CONSTANT zombie_HEIGHT : INTEGER := 60;  -- pixels tall

-- Define the plant sprite as a 2D bit array (32x32 = 1024 bits)
    --TYPE sprite_row IS ARRAY(0 TO PLANT_WIDTH-1) OF STD_LOGIC;
    type zombie_bitmap_t is array (0 to 59) of std_logic_vector(0 to 54);

-- Define your plant sprite pattern (1 = draw plant color, 0 = transparent)
    constant zombie : zombie_bitmap_t := (
-- 0
"0000000000000000000000000000000000000000000000000000000",
"0000000000000000000000000000000000000000000000000000000",
"0000000000000000000011111111110000000000000000000000000",
"0000000000000000011111111111111110000000000000000000000",
"0000000000000001111111111111111111000000000000000000000",
"0000000000000011111111111111111111110000000000000000000",
"0000000000000111111111111111111111111000000000000000000",
"0000000000000111111111111111111111111000000000000000000",
"0000000000000111111111111111111111111000000000000000000",
"0000000000000011111111111111111111110000000000000000000",
"0000000000000000111111111111111111000000000000000000000",
"0000000000000000001111111111111110000000000000000000000",
"0000000000000000000011111111111000000000000000000000000",

-- 10
"0000000000000000000000011111100000000000000000000000000",
"0000000000000000001111111111111110000000000000000000000",
"0000000000000001111111111111111111110000000000000000000",
"0001111111111111111111111111111111111000000000000000000",
"0001111111111111111111111111111111111000000000000000000",
"0001111111111111111111111111111111111000000000000000000",
"0001111111111111111111111111111111111100000000000000000",
"0001111111111111111111111111111111111100000000000000000",
"0000000000000011111111111111111111111000000000000000000",
"0000000000000111111111111111111111111000000000000000000",
"0000000000000111111111111111111111111000000000000000000",
"0000000000000111111111111111111111111000000000000000000",
"0000000000000111111111111111111111111000000000000000000",
"0000000000000111111111111111111111111000000000000000000",

-- waist (pinch)
"0000000000000111111111111111111111111100000000000000000",
"0000000000000111111111111111111111111100000000000000000",
"0000000000000111111111111111111111111100000000000000000",
"0000000000000111111111111111111111111100000000000000000",

-- 22
"0000000000000111111111111111111111111110000000000000000",
"0000000000000011111111111111111111111100000000000000000",

-- lower half
"0000000000000011111111111111111111111100000000000000000",
"0000000000000111111111111111111111111100000000000000000",
"0000000000001111111111111111111111111100000000000000000",
"0000000000011111111111110011111111111000000000000000000",
"0000000000111111111111000111111111111000000000000000000",
"0000000001111111111110000011111111111000000000000000000",
"0000000011111111111100000011111111111100000000000000000",
"0000000111111111110000000001111111111100000000000000000",
"0000000011111111111000000000111111111110000000000000000",

-- bottom taper
"0000000001111111111100000000001111111111000000000000000",
"0000000000111111111100000000000111111111100000000000000",
"0000000000111111111100000000000001111111110000000000000",
"0000001111111111111100000000111111111111110000000000000",
"0000011111111111111100000001111111111111110000000000000",
"0000011111111111111000000001111111111111100000000000000",
"0000000000000000000000000000000000000000000000000000000",

-- pad to 60 rows
others => (others => '0'));
    
BEGIN
    -- Output health and status
    zom_health <= STD_LOGIC_VECTOR(TO_UNSIGNED(zcurrent_health, 10));
    zom_alive <= 1 when zalive_internal = '1' else 0;
    ball_x_display <= ball_x + offset;
    
    -- Red zombie on white background
    --red   <= ball_on AND zalive_internal;
    --green <= NOT ball_on OR NOT zalive_internal;
    --blue  <= NOT ball_on OR NOT zalive_internal or hard;
    -- Health management process
    zhealth_proc : PROCESS(v_sync)
    BEGIN
        IF rising_edge(v_sync) THEN
            -- Zombie becomes alive when enabled
            IF zom_enable = '1' AND initialized = '0' THEN
                zalive_internal <= '1';
                zcurrent_health <= MAX_HEALTH;
                ball_x <= start_x;
                ball_y <= start_y;
                initialized <= '1';

            END IF;
            if hard = '0' then
            if hit_count >= 10 then
                zalive_internal <= '0';
                ball_y <= 900;
                ball_x_motion <= 0;
            end if;
            else
            if hit_count >= 15 then
                zalive_internal <= '0';
                ball_y <= 900;
                ball_x_motion <= 0;
            end if;
            end if;
            -- Take damage from shooter
            ----IF zom_damage = '1' AND zalive_internal = '1' THEN
            --    IF zcurrent_health > TO_INTEGER(UNSIGNED(attack)) THEN
              --      zcurrent_health <= zcurrent_health - TO_INTEGER(UNSIGNED(attack));
                --ELSE
                  --  zcurrent_health <= 0;
     --               --zalive_internal <= '0';  -- Zombie dies
       --         END IF;
         --   END IF;
            IF zalive_internal = '1' THEN
                -- Count frames for slower movement
                IF frame_count >= 15 THEN
                    frame_count <= 0;
                    
                    -- Bounce off left and right edges
                    --IF ball_x_display +size >= 800 THEN
                      --  ball_x_motion <= -1;
                    --END IF;
                    
                    -- Update position
                    ball_x <= ball_x + ball_x_motion;
                ELSE
                    if hard = '0' then
                    frame_count <= frame_count + 3;
                    else
                    frame_count <= frame_count + 5;
                    end if;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    -- Draw process
    bdraw : PROCESS (ball_x_display, ball_y, pixel_row, pixel_col, zalive_internal, offset)
    VARIABLE rel_x, rel_y : INTEGER;
        VARIABLE sprite_bit : STD_LOGIC;
    BEGIN
        --ball_on <= '0';
        
        --IF zalive_internal = '1' THEN
 --           IF (TO_INTEGER(UNSIGNED(pixel_col)) >= ball_x_display - size) AND
   --            (TO_INTEGER(UNSIGNED(pixel_col)) <= ball_x_display + size) AND
     --          (TO_INTEGER(UNSIGNED(pixel_row)) >= ball_y - size) AND
       --        (TO_INTEGER(UNSIGNED(pixel_row)) <= ball_y + size) THEN
         --       ball_on <= '1';
           -- END IF;
           
        --END IF;
        red   <= '0';
        green <= '0';
        blue  <= '0';
    
    IF zalive_internal = '1' THEN
        rel_x := TO_INTEGER(UNSIGNED(pixel_col)) - ball_x_display+ zombie_width/2;
        rel_y := TO_INTEGER(UNSIGNED(pixel_row)) - ball_y+ zombie_height/2;
        
        -- Check if we're within sprite bounds
        IF rel_x >= 0 AND rel_x < zombie_width AND
           rel_y >= 0 AND rel_y < zombie_height THEN
            
            sprite_bit := zombie(rel_y)(rel_x);
            
            IF sprite_bit = '1' THEN
                -- Draw plant color (green)
                if hard = '0' then
                red   <= '1';
                green <= '0';
                blue  <= '0';
                else
                red   <= '1';
                green <= '0';
                blue  <= '1';
                end if;
            END IF;
        END IF;
    END IF;
    END PROCESS;
    -- Movement process
 
    zom_loc_x <= ball_x_display+size;
    zom_loc_y <= ball_y;
end behavioral;
