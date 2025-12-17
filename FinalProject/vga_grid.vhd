LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY vga_grid IS
    GENERIC (
        SQUARE_SIZE    : INTEGER := 100;  -- size of each grid square in pixels
        LINE_THICKNESS : INTEGER := 2    -- thickness of grid lines in pixels
    );
    PORT (
        clk         : IN  STD_LOGIC; -- 100 MHz board clock
        reset_n     : IN  STD_LOGIC;
        -- VGA outputs (3 bits per channel)
        vga_r       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        vga_g       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        vga_b       : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        vga_hsync   : OUT STD_LOGIC;
        vga_vsync   : OUT STD_LOGIC;
        btnl : IN STD_LOGIC;
        btnr : IN STD_LOGIC;
        btnc : IN STD_LOGIC; 
        btnu : IN STD_LOGIC;
        btnd : IN STD_LOGIC;
        hard: IN STD_LOGIC;
        pass : out std_logic:='0'
    );
END ENTITY;

ARCHITECTURE behave OF vga_grid IS
    -- Clock wizard component
    COMPONENT clk_wiz_0
        PORT (
            clk_in1  : IN STD_LOGIC;
            clk_out1 : OUT STD_LOGIC
        );
    END COMPONENT;
    
    -- VGA sync component
    COMPONENT vga_sync
        PORT (
            pixel_clk : IN STD_LOGIC;
            red_in    : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            green_in  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            blue_in   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            red_out   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            green_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            blue_out  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            hsync     : OUT STD_LOGIC;
            vsync     : OUT STD_LOGIC;
            pixel_row : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
            pixel_col : OUT STD_LOGIC_VECTOR(10 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Plant component
    COMPONENT plant
        PORT (
            v_sync       : IN STD_LOGIC;
            pixel_row    : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            pixel_col    : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            plant_enable : IN STD_LOGIC;
            take_damage  : IN STD_LOGIC;
            damage_amt   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            shoot_enable : IN STD_LOGIC;
            --plant_alive  : OUT STD_LOGIC;
            --health       : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
            red          : OUT STD_LOGIC;
            green        : OUT STD_LOGIC;
            blue         : OUT STD_LOGIC;
            start_x        : in integer;
            start_y         : in integer;
            num             : in integer
        );
    END COMPONENT;
    
    COMPONENT bullet
        PORT (
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
            bullet_x_pos  : out integer range 0 to 1023; -- Current X position
            bullet_y_pos  : out integer range 0 to 1023; -- Current Y position
        
        -- VGA output
            red          : OUT STD_LOGIC;
            green        : OUT STD_LOGIC;
            blue         : OUT STD_LOGIC;
            
            placed       : in std_logic
        );
    END COMPONENT;
    
    -- Zombie component
    
    COMPONENT ball
        PORT (
            clk        : IN STD_LOGIC;
            v_sync     : IN STD_LOGIC;
            pixel_row  : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            pixel_col  : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            red        : OUT STD_LOGIC;
            green      : OUT STD_LOGIC;
            blue       : OUT STD_LOGIC;
            zom_enable : IN STD_LOGIC;
            zom_damage : IN STD_LOGIC;
            attack     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            zom_alive  : OUT integer;
            zom_health : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
            zom_loc_x    : out integer range 0 to 1023;
            zom_loc_y    : out integer range 0 to 1023;
            offset     : in integer range 0 to 1023;
            start_x        : in integer;
            start_y         : in integer;
            hit_count       : in integer range 0 to 1023;
            hard            : std_logic
        );
    END COMPONENT;
    TYPE integer_array IS ARRAY(0 to 11) OF INTEGER RANGE 0 TO 1023;
    TYPE zom_array IS ARRAY(0 to 3) OF INTEGER RANGE 0 TO 1023;
    TYPE zom_health_arr IS ARRAY(0 to 3) OF std_logic_vector(9 downto 0);
    TYPE collision_2d_array IS ARRAY(0 TO 3, 0 TO 11) OF STD_LOGIC;
    SIGNAL collision_prev : collision_2d_array := (OTHERS => (OTHERS => '0'));
    SIGNAL collision_detected : collision_2d_array := (OTHERS => (OTHERS => '0'));


    -- Signals
    SIGNAL pixel_clk    : STD_LOGIC;
    SIGNAL pixel_row    : STD_LOGIC_VECTOR(10 DOWNTO 0);
    SIGNAL pixel_col    : STD_LOGIC_VECTOR(10 DOWNTO 0);
    SIGNAL v_sync_sig   : STD_LOGIC;
    
    -- VGA sync signals
    SIGNAL red_4bit     : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL green_4bit   : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL blue_4bit    : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL red_out_4bit : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL green_out_4bit : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL blue_out_4bit : STD_LOGIC_VECTOR(3 DOWNTO 0);
    
    -- Grid drawing signals
    SIGNAL hx, vx       : INTEGER RANGE 0 TO 2047;
    SIGNAL grid_on      : STD_LOGIC;
    
    -- Plant signals
    SIGNAL plant_red    : STD_LOGIC_vector(11 downto 0);
    SIGNAL plant_green  : STD_LOGIC_vector(11 downto 0);
    SIGNAL plant_blue   : STD_LOGIC_vector(11 downto 0);
    SIGNAL plants_red    : STD_LOGIC;
    SIGNAL plants_green  : STD_LOGIC;
    SIGNAL plants_blue   : STD_LOGIC;
    SIGNAL plant_alive  : STD_LOGIC;
    SIGNAL plant_health : STD_LOGIC_VECTOR(11 DOWNTO 0);
    signal plant_enable : std_logic_vector(11 downto 0) := "000000000001";
    
    -- Zombie signals
    SIGNAL zombie_red   : STD_LOGIC_vector(0 to 3);
    SIGNAL zombie_green : STD_LOGIC_vector(0 to 3);
    SIGNAL zombie_blue  : STD_LOGIC_vector(0 to 3);
    SIGNAL zoms_red    : STD_LOGIC;
    SIGNAL zoms_green  : STD_LOGIC;
    SIGNAL zoms_blue   : STD_LOGIC;
    SIGNAL zombie_alive : zom_array;
    SIGNAL zombie_health : zom_health_arr:=("0011001000", "0011001000", "0011001000", "0011001000");
    SIGNAL zombie_loc_x : zom_array := (700, 600, 650, 750);
    signal hit_detected    : collision_2d_array := (OTHERS => (OTHERS => '0'));
    signal zom_enable    : std_logic_vector(0 to 3) := "1111";
    signal hit_prev    : collision_2d_array := (OTHERS => (OTHERS => '0'));
    signal hit_count       : zom_array:=(0,0, 0, 0);
    SIGNAL temp    : integer range 0 to 1023;
    SIGNAL zombie_loc_y    : zom_array;
    SIGNAL offset        : zom_array:= (0, 0, 0, 0);
    signal bullet_active : std_logic_vector(5 downto 0);
    signal bullet_x_pos : integer_array;
    signal bullet_y_pos : integer_array;
    signal zom_start_x  : zom_array := (700, 600, 650, 750);
    signal zom_start_y  : zom_array := (250, 450, 150, 550);
    SIGNAL zom_damage : STD_LOGIC_VECTOR(0 TO 3) := "0000";
    --signal zom_damage_latch : std_logic_vector(0 to 1) := "00";
    SIGNAL attack_amt : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00110010";  -- 50 damage per hit
    SIGNAL bullet_reset : STD_LOGIC_vector(5 downto 0) := "000001";
        
        -- VGA output
    SIGNAL bullet_blue : std_logic_vector(5 downto 0);
    SIGNAL clear : std_logic_vector(5 downto 0);
    signal bullet_hit : std_logic_vector(5 downto 0) := (others => '0');
    SIGNAL bullet_green : std_logic_vector(5 downto 0);
    SIGNAL bullet_red : std_logic_vector(5 downto 0);
    SIGNAL plant_x : integer_array := (50, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000);
    SIGNAL plant_y : integer_array := (50, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000);
    SIGNAL count : unsigned (20 DOWNTO 0):= (OTHERS => '0');
    signal btn_pressed: std_logic;
    signal btnc_pressed : std_logic := '0';
    signal btnc_count: integer := 0;
   -- SIGNAL collision_prev : STD_LOGIC_vector (0 to 5) := "000000";
    --SIGNAL collision_detected : STD_LOGIC_vector (0 to 5) := "000000";
    signal collision_count : integer_array := (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    SIGNAL i : INTEGER RANGE 0 TO 11 := 0;
    signal game_end : std_logic := '0';
    signal game_win : std_logic := '0';
    signal placed : std_logic_vector(11 downto 0):="000000000000";
    signal sum : integer :=0;
    signal game_started : std_logic := '0';

   -- type font_row_t is std_logic_vector(7 downto 0);
    type font_t is array (0 to 7) of std_logic_vector(7 downto 0);

constant FONT_Y : font_t := (
    "10000001",
    "01000010",
    "00100100",
    "00011000",
    "00011000",
    "00011000",
    "00011000",
    "00011000"
);

constant FONT_O : font_t := (
    "00111100",
    "01000010",
    "10000001",
    "10000001",
    "10000001",
    "10000001",
    "01000010",
    "00111100"
);

constant FONT_U : font_t := (
    "10000001",
    "10000001",
    "10000001",
    "10000001",
    "10000001",
    "10000001",
    "01000010",
    "00111100"
);

constant FONT_W : font_t := (
    "10000001",
    "10000001",
    "10000001",
    "10011001",
    "10011001",
    "10011001",
    "01011010",
    "00111100"
);

constant FONT_I : font_t := (
    "00111100",
    "00011000",
    "00011000",
    "00011000",
    "00011000",
    "00011000",
    "00011000",
    "00111100"
);

constant FONT_N : font_t := (
    "10000001",
    "11000001",
    "10100001",
    "10010001",
    "10001001",
    "10000101",
    "10000011",
    "10000001"
);
constant FONT_L : font_t := (
    "10000000",
    "10000000",
    "10000000",
    "10000000",
    "10000000",
    "10000000",
    "10000000",
    "11111111"
);
constant FONT_E : font_t := (
    "11111111",
    "10000000",
    "10000000",
    "11111111",
    "10000000",
    "10000000",
    "10000000",
    "11111111"
);
constant FONT_S : font_t := (
    "11111111",
    "10000000",
    "10000000",
    "11111111",
    "00000001",
    "00000001",
    "00000001",
    "11111111"
);
constant WIN_X : integer := 372; -- (800-56)/2
constant WIN_Y : integer := 296; -- (600-8)/2
constant lose_X : integer := 368; -- (800-56)/2
constant lose_Y : integer := 296; -- (600-8)/2
BEGIN
    -- Clock wizard: 100 MHz -> 40 MHz
    clk_wizard : clk_wiz_0
        PORT MAP (
            clk_in1  => clk,
            clk_out1 => pixel_clk
        );
    
    -- VGA sync generator
    vga_driver : vga_sync
        PORT MAP (
            pixel_clk => pixel_clk,
            red_in    => red_4bit,
            green_in  => green_4bit,
            blue_in   => blue_4bit,
            red_out   => red_out_4bit,
            green_out => green_out_4bit,
            blue_out  => blue_out_4bit,
            hsync     => vga_hsync,
            vsync     => v_sync_sig,
            pixel_row => pixel_row,
            pixel_col => pixel_col
        );
    
    vga_vsync <= v_sync_sig;
     -- Random number generator

    hx <= TO_INTEGER(UNSIGNED(pixel_col));
    vx <= TO_INTEGER(UNSIGNED(pixel_row));
    
    -- Plant instance
    plant_inst : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(0),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(0),
            green        => plant_green(0),
            blue         => plant_blue(0),
            start_x      => plant_x(0),
            start_y      => plant_y(0),
            num          => 1
        );
    plant_inst2 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(1),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(1),
            green        => plant_green(1),
            blue         => plant_blue(1),
            start_x      => plant_x(1),
            start_y      => plant_y(1),
            num          => 2
        );
    plant_inst3 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(2),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(2),
            green        => plant_green(2),
            blue         => plant_blue(2),
            start_x      => plant_x(2),
            start_y      => plant_y(2),
            num          => 3
        );
    
    plant_inst4 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(3),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(3),
            green        => plant_green(3),
            blue         => plant_blue(3),
            start_x      => plant_x(3),
            start_y      => plant_y(3),
            num          => 4
        );
    plant_inst5 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(4),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(4),
            green        => plant_green(4),
            blue         => plant_blue(4),
            start_x      => plant_x(4),
            start_y      => plant_y(4),
            num          => 5
        );
    plant_inst6 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(5),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(5),
            green        => plant_green(5),
            blue         => plant_blue(5),
            start_x      => plant_x(5),
            start_y      => plant_y(5),
            num          => 6
        );
    plant_inst7 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(6),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(6),
            green        => plant_green(6),
            blue         => plant_blue(6),
            start_x      => plant_x(6),
            start_y      => plant_y(6),
            num          => 7
        );
        plant_inst8 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(7),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(7),
            green        => plant_green(7),
            blue         => plant_blue(7),
            start_x      => plant_x(7),
            start_y      => plant_y(7),
            num          => 8
        );
        plant_inst9 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(8),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(8),
            green        => plant_green(8),
            blue         => plant_blue(8),
            start_x      => plant_x(8),
            start_y      => plant_y(8),
            num          => 9
        );
        plant_inst10 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(9),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(9),
            green        => plant_green(9),
            blue         => plant_blue(9),
            start_x      => plant_x(9),
            start_y      => plant_y(9),
            num          => 10
        );
        plant_inst11 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(10),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(10),
            green        => plant_green(10),
            blue         => plant_blue(10),
            start_x      => plant_x(10),
            start_y      => plant_y(10),
            num          => 11
        );
        plant_inst12 : plant
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
            plant_enable => plant_enable(11),
            take_damage  => '0',
            damage_amt   => (OTHERS => '0'),
            shoot_enable => '0',
            --plant_alive  => plant_alive,
            --health       => plant_health,
            red          => plant_red(11),
            green        => plant_green(11),
            blue         => plant_blue(11),
            start_x      => plant_x(11),
            start_y      => plant_y(11),
            num          => 12
        );
    bullet_inst : bullet
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
        
        -- Control signals
            bullet_enable=>placed(6),
            bullet_reset  => bullet_reset(0), 
            start_x      =>plant_x(6),
            start_y      =>plant_y(6),
        
        -- Status outputs
            bullet_active => bullet_active(0),
            bullet_x_pos =>bullet_x_pos(0),
            bullet_y_pos =>bullet_y_pos(0),
        
        -- VGA output
            red          =>bullet_blue(0),
            green        =>bullet_green(0),
            blue         =>bullet_red(0),
            
            placed       =>placed(6)
        );
        
        bullet_inst2 : bullet
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
        
        -- Control signals
            bullet_enable=>placed(7),
            bullet_reset  => bullet_reset(1), 
            start_x      =>plant_x(7),
            start_y      =>plant_y(7),
        
        -- Status outputs
            bullet_active => bullet_active(1),
            bullet_x_pos =>bullet_x_pos(1),
            bullet_y_pos =>bullet_y_pos(1),
        
        -- VGA output
            red          =>bullet_blue(1),
            green        =>bullet_green(1),
            blue         =>bullet_red(1),
            
            placed       =>placed(7)
        );
        
        bullet_inst3 : bullet
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
        
        -- Control signals
            bullet_enable=>placed(8),
            bullet_reset  => bullet_reset(2), 
            start_x      =>plant_x(8),
            start_y      =>plant_y(8),
        
        -- Status outputs
            bullet_active => bullet_active(2),
            bullet_x_pos =>bullet_x_pos(2),
            bullet_y_pos =>bullet_y_pos(2),
        
        -- VGA output
            red          =>bullet_blue(2),
            green        =>bullet_green(2),
            blue         =>bullet_red(2),
            
            placed       =>placed(8)
        );
        
        bullet_inst4 : bullet
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
        
        -- Control signals
            bullet_enable=>placed(9),
            bullet_reset  => bullet_reset(3), 
            start_x      =>plant_x(9),
            start_y      =>plant_y(9),
        
        -- Status outputs
            bullet_active => bullet_active(3),
            bullet_x_pos =>bullet_x_pos(3),
            bullet_y_pos =>bullet_y_pos(3),
        
        -- VGA output
            red          =>bullet_blue(3),
            green        =>bullet_green(3),
            blue         =>bullet_red(3),
            
            placed       =>placed(9)
        );
        
        bullet_inst5 : bullet
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
        
        -- Control signals
            bullet_enable=>placed(10),
            bullet_reset  => bullet_reset(4), 
            start_x      =>plant_x(10),
            start_y      =>plant_y(10),
        
        -- Status outputs
            bullet_active => bullet_active(4),
            bullet_x_pos =>bullet_x_pos(4),
            bullet_y_pos =>bullet_y_pos(4),
        
        -- VGA output
            red          =>bullet_blue(4),
            green        =>bullet_green(4),
            blue         =>bullet_red(4),
            
            placed       =>placed(10)
        );
        
        bullet_inst6 : bullet
        PORT MAP (
            v_sync       => v_sync_sig,
            pixel_row    => pixel_row,
            pixel_col    => pixel_col,
        
        -- Control signals
            bullet_enable=>placed(11),
            bullet_reset  => bullet_reset(5), 
            start_x      =>plant_x(11),
            start_y      =>plant_y(11),
        
        -- Status outputs
            bullet_active => bullet_active(5),
            bullet_x_pos =>bullet_x_pos(5),
            bullet_y_pos =>bullet_y_pos(5),
        
        -- VGA output
            red          =>bullet_blue(5),
            green        =>bullet_green(5),
            blue         =>bullet_red(5),
            
            placed       =>placed(11)
        );
    
    -- Zombie instance
    zombie_inst : ball
        PORT MAP (
            clk        => clk, 
            v_sync     => v_sync_sig,
            pixel_row  => pixel_row,
            pixel_col  => pixel_col,
            red        => zombie_red(0),
            green       => zombie_green(0),
            blue        => zombie_blue(0),
            zom_enable => zom_enable(0),
            zom_damage => zom_damage(0),  -- Now connected!
            attack     => attack_amt,  
            zom_alive  => zombie_alive(0),
            zom_health => zombie_health(0),
            zom_loc_x    => zombie_loc_x(0),
            zom_loc_y    => zombie_loc_y(0),
            offset     =>offset(0),
            start_x      => zom_start_x(0),
            start_y      => zom_start_y(0),
            hit_count    => hit_count(0),
            hard         => hard
        );
    zombie_inst2 : ball
        PORT MAP (
            clk        => clk,
            v_sync     => v_sync_sig,
            pixel_row  => pixel_row,
            pixel_col  => pixel_col,
            red        => zombie_red(1),
            green       => zombie_green(1),
            blue        => zombie_blue(1),
            zom_enable => zom_enable(1),
            zom_damage => zom_damage(1),  -- Now connected!
            attack     => attack_amt,  
            zom_alive  => zombie_alive(1),
            zom_health => zombie_health(1),
            zom_loc_x    => zombie_loc_x(1),
            zom_loc_y    => zombie_loc_y(1),
            offset     =>offset(1),
            start_x      => zom_start_x(1),
            start_y      => zom_start_y(1),
            hit_count    => hit_count(1),
            hard         => hard
        );
        zombie_inst3 : ball
        PORT MAP (
            clk        => clk,
            v_sync     => v_sync_sig,
            pixel_row  => pixel_row,
            pixel_col  => pixel_col,
            red        => zombie_red(2),
            green       => zombie_green(2),
            blue        => zombie_blue(2),
            zom_enable => zom_enable(2),
            zom_damage => zom_damage(2),  
            attack     => attack_amt,  
            zom_alive  => zombie_alive(2),
            zom_health => zombie_health(2),
            zom_loc_x    => zombie_loc_x(2),
            zom_loc_y    => zombie_loc_y(2),
            offset     =>offset(2),
            start_x      => zom_start_x(2),
            start_y      => zom_start_y(2),
            hit_count    => hit_count(2),
            hard         => hard
        );
        zombie_inst4 : ball
        PORT MAP (
            clk        => clk,
            v_sync     => v_sync_sig,
            pixel_row  => pixel_row,
            pixel_col  => pixel_col,
            red        => zombie_red(3),
            green       => zombie_green(3),
            blue        => zombie_blue(3),
            zom_enable => zom_enable(3),
            zom_damage => zom_damage(3),  
            attack     => attack_amt,  
            zom_alive  => zombie_alive(3),
            zom_health => zombie_health(3),
            zom_loc_x    => zombie_loc_x(3),
            zom_loc_y    => zombie_loc_y(3),
            offset     =>offset(3),
            start_x      => zom_start_x(3),
            start_y      => zom_start_y(3),
            hit_count    => hit_count(3),
            hard         => hard
        );
        
    -- Grid generation process (using variables for modulo)
    grid_proc : PROCESS(hx, vx)
        VARIABLE hmod, vmod : INTEGER;
    BEGIN
        hmod := hx MOD SQUARE_SIZE;
        vmod := vx MOD SQUARE_SIZE;
        
        IF (hmod < LINE_THICKNESS) OR (vmod < LINE_THICKNESS) THEN
            grid_on <= '1';  -- Draw white grid line
        ELSE
            grid_on <= '0';  -- Black background
        END IF;
    END PROCESS;
    
    -- Combine grid, plant, and zombie colors
    combine_proc : PROCESS(grid_on, plant_red(0), plant_red(1), plant_red(2), plant_red(3), plant_red(4), plant_red(5), plant_green(0), plant_green(1), plant_green(2), plant_green(3), plant_green(4), plant_green(5), plant_blue(0), plant_blue(1), plant_blue(2), plant_blue(3), plant_blue(4), plant_blue(5), 
                           zombie_red, zombie_green, zombie_blue, game_end)
    variable bit_on : std_logic;
    variable char_x : integer;
    variable row    : integer;
    variable col    : integer;
    BEGIN
        -- Start with grid (black background or white lines)
        if game_end = '1' then
        red_4bit   <= "1111";
        green_4bit <= "1111";
        blue_4bit  <= "1111";
        IF vx >= lose_Y AND vx < lose_Y + 8 AND
            hx >= lose_X AND hx < lose_X + 64 THEN

       

        row := vx - lose_Y;
        char_x := (hx - lose_X) / 8;
        col := 7 - ((hx - lose_X) mod 8);

        case char_x is
            when 0 => bit_on := FONT_Y(row)(col);
            when 1 => bit_on := FONT_O(row)(col);
            when 2 => bit_on := FONT_U(row)(col);
            when 3 => bit_on := '0'; -- space
            when 4 => bit_on := FONT_L(row)(col);
            when 5 => bit_on := FONT_O(row)(col);
            when 6 => bit_on := FONT_S(row)(col);
            when 7 => bit_on := FONT_E(row)(col);
            when others => bit_on := '0';
        end case;

        IF bit_on = '1' THEN
            red_4bit   <= "0000";
            green_4bit <= "0000";
            blue_4bit  <= "0000";
        END IF;
        end if;
        elsif game_win = '1' then
            red_4bit   <= "0000";
            green_4bit <= "0000";
            blue_4bit  <= "0000";
            
            pass<='1';

    -- YOU WIN text
            IF vx >= WIN_Y AND vx < WIN_Y + 8 AND
            hx >= WIN_X AND hx < WIN_X + 56 THEN

       

        row := vx - WIN_Y;
        char_x := (hx - WIN_X) / 8;
        col := 7 - ((hx - WIN_X) mod 8);

        case char_x is
            when 0 => bit_on := FONT_Y(row)(col);
            when 1 => bit_on := FONT_O(row)(col);
            when 2 => bit_on := FONT_U(row)(col);
            when 3 => bit_on := '0'; -- space
            when 4 => bit_on := FONT_W(row)(col);
            when 5 => bit_on := FONT_I(row)(col);
            when 6 => bit_on := FONT_N(row)(col);
            when others => bit_on := '0';
        end case;

        IF bit_on = '1' THEN
            red_4bit   <= "1111";
            green_4bit <= "1111";
            blue_4bit  <= "1111";
        END IF;
    END IF;
    else
        IF grid_on = '1' THEN
            red_4bit   <= "1111";  -- White line
            green_4bit <= "1111";
            blue_4bit  <= "1111";
        ELSE
            red_4bit   <= "0000";  -- Black background
            green_4bit <= "0001";
            blue_4bit  <= "0000";
        end if;
        --if plant_red(0) = '1' or plant_red(1) = '1' or plant_red(2) = '1' or plant_red(3) = '1' or plant_red(4) = '1' or plant_red(5) = '1' then
          --  plants_red <= '1';
        --end if;
--        if plant_green(0) = '1' or plant_green(1) = '1' or plant_green(2) = '1' or plant_green(3) = '1' or plant_green(4) = '1' or plant_green(5) = '1' then
  --          plants_green <= '1';
    --    end if;
      --  if plant_blue(0) = '1' or plant_blue(1) = '1' or plant_blue(2) = '1' or plant_blue(3) = '1' or plant_blue(4) = '1' or plant_blue(5) = '1' then
        --    plants_blue <= '1';
--        end if;
  --      if zombie_red(0) = '1' or zombie_red(1) = '1' then
    --        zoms_red <= '1';
      --  end if;
        --if zombie_green(0) = '1' or zombie_green(1) = '1' then
          --  zoms_green <= '1';
--        end if;
  --      if zombie_blue(0) = '1' or zombie_blue(1) = '1' then
    --        zoms_blue <= '1';
      --  end if;
        -- Plant overrides grid (plant outputs '1' for background, color for plant)
        FOR j IN 0 TO 11 LOOP
        IF plant_red(j) = '1' AND plant_green(j) = '1' AND plant_blue(j) = '0' THEN
            red_4bit   <= "1111";
            green_4bit <= "1111";
            blue_4bit  <= "0000";
        END IF;
        IF plant_red(j) = '0' AND plant_green(j) = '1' AND plant_blue(j) = '0' THEN
            red_4bit   <= "0000";
            green_4bit <= "1111";
            blue_4bit  <= "0000";
        END IF;
        END LOOP;
        FOR j IN 0 TO 3 LOOP
        IF zombie_red(j) = '1' and zombie_green(j) = '0' and zombie_blue(j) = '0' THEN
            red_4bit   <= "1111";
            green_4bit <= "0000";
            blue_4bit  <= "0000";
        END IF;
        IF zombie_red(j) = '1' and zombie_green(j) = '0' and zombie_blue(j) = '1' THEN
            red_4bit   <= "1111";
            green_4bit <= "0000";
            blue_4bit  <= "1111";
        END IF;
        END LOOP;
        
        -- Zombie overrides everything (zombie outputs '1' for red, '0' for green/blue)
        --IF zoms_red = '1' AND zoms_green = '0' AND zoms_blue = '0' THEN
        --    red_4bit   <= "1111";  -- Red zombie
        --    green_4bit <= "0000";
        --    blue_4bit  <= "0000";
        --END IF;
        FOR j IN 0 TO 5 LOOP
        IF bullet_red(j) = '0' AND bullet_green(j) = '1' AND bullet_blue(j) = '0' THEN
            red_4bit   <= "0000";  -- Red zombie
            green_4bit <= "1111";
            blue_4bit  <= "0000";
        END IF;
        end loop;
        
        end if;
    END PROCESS;
    
    -- Convert 4-bit to 3-bit for output
    vga_r <= red_out_4bit(3 DOWNTO 1);
    vga_g <= green_out_4bit(3 DOWNTO 1);
    vga_b <= blue_out_4bit(3 DOWNTO 1);
    pos : PROCESS (clk) is
    variable sum_v : integer;
    BEGIN
        if rising_edge(clk) then
            sum_v := 0;
            for j in 0 to 3 loop
                sum_v := sum_v + zombie_alive(j);
            end loop;
            sum <= sum_v;
            count <= count + 1;
            zom_damage <= "0000";
            
            IF (btnl = '0' AND btnr = '0' AND btnu = '0' AND btnd = '0') THEN
                btn_pressed <= '0';
            END IF;
            IF (btnc = '0') THEN
                btnc_pressed <= '0';
            END IF;
            
            if btn_pressed = '0' and collision_count(i) < 3 and btnc_count<12 then
            IF (btnl = '1' and count = 0 and plant_x(i)>100) THEN
                plant_x(i) <= plant_x(i) - 100;
                btn_pressed <= '1';
            ELSIF (btnr = '1' and count = 0 and plant_x(i) < 700) THEN
                btn_pressed <= '1';
                plant_x(i) <= plant_x(i) + 100;
            ELSIF (btnd = '1' and count = 0 and plant_y(i) < 500) THEN
                btn_pressed <= '1';
                plant_y(i) <= plant_y(i) + 100;
            ELSIF (btnu = '1' and count = 0 and plant_y(i) > 100) THEN
                btn_pressed <= '1';
                plant_y(i) <= plant_y(i) - 100;
            END IF;
            end if;
            if btnc_pressed = '0' then
                if btnc = '1' then
                    btnc_pressed <= '1';
                    placed(i) <= '1';
                    btnc_count <= btnc_count + 1;
                    if i < 11 then
                    plant_enable(i+1) <= '1';
                    plant_x(i+1) <= 50;
                    plant_y(i+1) <= 50;
                    end if;
                    if i < 11 then
                        i <= i + 1;   -- MOVE TO NEXT PLANT SLOT
                    end if;
                    game_started <= '1';
                 end if;
            end if;
           -- if zombie_loc_x <= plant_x and (zombie_loc_y>plant_y-50 and zombie_loc_y<plant_y+50) then
             --   offset <= offset+100;
           -- end if;
            for j in 0 to 3 loop
            FOR k IN 0 TO 11 LOOP
            IF plant_enable(k) = '1' THEN
            IF zombie_loc_x(j) <= plant_x(k) + 40+15 AND 
               zombie_loc_y(j) > plant_y(k) - 50 AND 
               zombie_loc_y(j) < plant_y(k) + 50 THEN
                collision_detected(j,k) <= '1';
            ELSE
                collision_detected(j,k) <= '0';
            END IF;
        
        -- Only increase offset on RISING EDGE of collision (0 -> 1 transition)
            IF collision_detected(j,k) = '1' AND collision_prev(j,k) = '0' THEN
                collision_count(k) <= collision_count(k) +1;
                offset(j) <= offset(j) + 80;

            END IF;
            collision_prev(j,k) <= collision_detected(j,k);
            if collision_count(k) >= 3 then
                plant_enable(k) <= '0';
                plant_x(k) <= 1000;
                plant_y(k) <= 1000;
            end if;
            end if;
            end loop;
            IF zombie_alive(j) = 1 AND zombie_loc_x(j) = 40 then 
              game_end <= '1';
            end if;
            
            for k IN 0 TO 5 LOOP
            --bullet_reset(k-1) <= '0';
            --bullet_reset(k) <= '0';
            IF placed(k+6) = '1' THEN
            IF bullet_x_pos(k) >= zombie_loc_x(j) - 40 AND 
                bullet_x_pos(k) <= zombie_loc_x(j) + 40 AND 
                bullet_y_pos(k) >= zombie_loc_y(j) - 50 AND 
                bullet_y_pos(k) <= zombie_loc_y(j) + 50 AND
                bullet_hit(k) = '0' THEN
                hit_detected(j, k) <= '1';
            ELSE
                hit_detected(j, k) <= '0';
            END IF;
             IF hit_detected(j, k) = '1' AND hit_prev(j,k) = '0' and bullet_hit(k) = '0' THEN
                bullet_hit(k) <= '1';           -- Mark bullet as hit
                hit_count(j) <= hit_count(j) + 1;
                zom_damage(j) <= '1';
                offset(j) <= offset(j) + 10;
                bullet_reset(k) <= '1';         -- Trigger reset
            END IF;
            if clear(k) = '1' then
                bullet_hit(k) <='0';
                bullet_reset(k) <= '0';
            end if;
            
            hit_prev(j, k) <= hit_detected(j, k);

            end if;
            end loop;
            end loop;
            IF sum = 0 and game_end = '0' AND game_started = '1' then 
               game_win <= '1';
            else
               game_win <='0';
            end if;
            
        end if;
    END PROCESS;
    bullet_rst : PROCESS (v_sync_sig) is
    BEGIN
        if rising_edge(v_sync_sig) then 
            for k in 0 to 5 loop
                IF bullet_reset(k) = '1' THEN
                    clear(k) <= '1';
                else
                    clear(k) <= '0';
                END IF;
            end loop;
        end if;
    end process;
END ARCHITECTURE;
