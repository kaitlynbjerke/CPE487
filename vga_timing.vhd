LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY vga_sync IS
    PORT (
        pixel_clk : IN STD_LOGIC;
        red_in    : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        green_in  : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        blue_in   : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        red_out   : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        green_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        blue_out  : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        hsync     : OUT STD_LOGIC;
        vsync     : OUT STD_LOGIC;
        pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
        pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
    );
END vga_sync;

ARCHITECTURE Behavioral OF vga_sync IS
    SIGNAL h_cnt, v_cnt : STD_LOGIC_VECTOR (10 DOWNTO 0);
    
    -- 800x600 @ 60Hz timing parameters (40 MHz pixel clock)
    CONSTANT H      : INTEGER := 800;   -- Horizontal display area
    CONSTANT V      : INTEGER := 600;   -- Vertical display area
    CONSTANT H_FP   : INTEGER := 40;    -- Horizontal front porch
    CONSTANT H_BP   : INTEGER := 88;    -- Horizontal back porch
    CONSTANT H_SYNC : INTEGER := 128;   -- Horizontal sync pulse
    CONSTANT V_FP   : INTEGER := 1;     -- Vertical front porch
    CONSTANT V_BP   : INTEGER := 23;    -- Vertical back porch
    CONSTANT V_SYNC : INTEGER := 4;     -- Vertical sync pulse
    
BEGIN
    sync_pr : PROCESS
        VARIABLE video_on : STD_LOGIC;
    BEGIN
        WAIT UNTIL rising_edge(pixel_clk);
        
        -- Generate Horizontal Timing Signals
        -- Total horizontal line width = H + H_FP + H_SYNC + H_BP = 1056
        IF (h_cnt >= H + H_FP + H_SYNC + H_BP - 1) THEN
            h_cnt <= (OTHERS => '0');
        ELSE
            h_cnt <= h_cnt + 1;
        END IF;
        
        -- Generate horizontal sync pulse
        IF (h_cnt >= H + H_FP) AND (h_cnt < H + H_FP + H_SYNC) THEN
            hsync <= '1';  -- Positive polarity for 800x600
        ELSE
            hsync <= '0';
        END IF;
        
        -- Generate Vertical Timing Signals
        -- Total vertical frame height = V + V_FP + V_SYNC + V_BP = 628
        IF (v_cnt >= V + V_FP + V_SYNC + V_BP - 1) AND (h_cnt >= H + H_FP + H_SYNC + H_BP - 1) THEN
            v_cnt <= (OTHERS => '0');
        ELSIF (h_cnt >= H + H_FP + H_SYNC + H_BP - 1) THEN
            v_cnt <= v_cnt + 1;
        END IF;
        
        -- Generate vertical sync pulse
        IF (v_cnt >= V + V_FP) AND (v_cnt < V + V_FP + V_SYNC) THEN
            vsync <= '1';  -- Positive polarity for 800x600
        ELSE
            vsync <= '0';
        END IF;
        
        -- Generate Video Enable Signal
        IF (h_cnt < H) AND (v_cnt < V) THEN
            video_on := '1';
        ELSE
            video_on := '0';
        END IF;
        
        -- Output pixel addresses
        pixel_col <= h_cnt;
        pixel_row <= v_cnt;
        
        -- Register video to clock edge and suppress during blanking
        IF video_on = '1' THEN
            red_out   <= red_in;
            green_out <= green_in;
            blue_out  <= blue_in;
        ELSE
            red_out   <= "0000";
            green_out <= "0000";
            blue_out  <= "0000";
        END IF;
    END PROCESS;
END Behavioral;
