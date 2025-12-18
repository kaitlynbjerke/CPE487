LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY bullet IS
    PORT (
        clk          : IN std_logic;
        v_sync       : IN STD_LOGIC;
        pixel_row    : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col    : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        
        -- Control signals
        bullet_enable : IN STD_LOGIC;  -- '1' to spawn/activate bullet
        bullet_reset  : IN STD_LOGIC;
        start_x       : IN integer range 0 to 1023;  -- Starting X position
        start_y       : IN integer range 0 to 1023;  -- Starting Y position
        
        -- Status outputs
        bullet_active : OUT STD_LOGIC;  -- '1' when bullet is active/visible
        bullet_x_pos  : out integer range 0 to 1023;  -- Current X position
        bullet_y_pos  : out integer range 0 to 1023;  -- Current Y position
        
        -- VGA output
        red          : OUT STD_LOGIC;
        green        : OUT STD_LOGIC;
        blue         : OUT STD_LOGIC;
        
        placed       : in std_logic
    );
END bullet;

ARCHITECTURE Behavioral OF bullet IS
    -- Bullet appearance constants
    CONSTANT BULLET_SIZE  : INTEGER := 5;   -- radius in pixels (small circle)
    CONSTANT BULLET_SPEED : INTEGER := 3;   -- pixels per frame (faster than zombie)
    
    -- Screen boundaries
    CONSTANT SCREEN_WIDTH : INTEGER := 800;
    
    -- Bullet position and state
    SIGNAL bullet_x      : INTEGER RANGE 0 TO 1023 := 0;
    SIGNAL bullet_y      : INTEGER RANGE 0 TO 1023 := 0;
    SIGNAL active        : STD_LOGIC := '0';
    SIGNAL bullet_on     : STD_LOGIC;
    signal collision     : std_logic_vector(0 to 1);
    
BEGIN
    -- Output current position and active status
    bullet_active <= active;
    bullet_x_pos <=bullet_x;
    bullet_y_pos <=bullet_y;
    
    -- Process to handle bullet movement
    movement_proc : PROCESS(v_sync)
    BEGIN
        IF rising_edge(v_sync) THEN
            -- Spawn new bullet when enabled and not already active
            IF bullet_enable = '1' AND active = '0' THEN
                bullet_x <= start_x;
                bullet_y <= start_y;
                active <= '1';
            END IF;
            
            -- Move bullet to the right if active
            IF active = '1' THEN
                -- Check if bullet has gone off screen
                IF bullet_reset = '1'  THEN
                    active <= '0';
                    bullet_x <= start_x;
                    bullet_y <= start_y;
                elsiF bullet_x >= SCREEN_WIDTH THEN
                    active <= '0';  -- Deactivate bullet
                    bullet_x <= start_x;
                    bullet_y <= start_y;
                ELSE
                    -- Move bullet right
                    if placed = '1' then
                        bullet_x <= bullet_x + BULLET_SPEED;
                    else
                        bullet_x <= bullet_x;
                    end if;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- Process to draw bullet at current pixel position
    draw_proc : PROCESS(bullet_x, bullet_y, pixel_row, pixel_col, active)
        VARIABLE dx, dy : INTEGER;
        VARIABLE dist_sq : INTEGER;
    BEGIN
        bullet_on <= '0';
        
        IF active = '1' THEN
            -- Calculate distance from bullet center
            dx := ABS(TO_INTEGER(UNSIGNED(pixel_col)) - bullet_x);
            dy := ABS(TO_INTEGER(UNSIGNED(pixel_row)) - bullet_y);
            dist_sq := (dx * dx) + (dy * dy);
            
            -- Check if pixel is within bullet circle
            IF dist_sq <= (BULLET_SIZE * BULLET_SIZE) THEN
                bullet_on <= '1';
            END IF;

        END IF;
    END PROCESS;
    
    -- Color assignment - Lime green bullet (brighter than plant)
    -- Output final colors (only show when bullet is at current pixel)
    red   <= '0' WHEN bullet_on = '1' ELSE '0';
    green <= '1' WHEN bullet_on = '1' ELSE '0';
    blue  <= '0' WHEN bullet_on = '1' ELSE '0';
    
END Behavioral;
