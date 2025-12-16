# Circles Vs Squares - CPE 487 Final Project
**By Kaitlyn Bjerke, Jacqueline Castro, and Gianina Maldonado**

A tower defense game, based on Plants Vs Zombies

---

**Introduction**

For our final project, we were tasked with creating a game using the VHDL language. This project allowed us to test our knowledge of VHDL while also expanding into topics that were not covered extensively in class. For our game, we decided to mimic the functional mechanics of Plants vs. Zombies. To recreate this concept, we developed a game titled **Circles vs. Squares**, where circles represent the plants and squares represent the zombies. 

[image of plants vs zombies]

We considered various game mechanics from Plants Vs Zombies, including:

- Defensive Units (circles)
- Offensive Units (squares)
- Projectile system
- Health system
- Attack timing
- Collision
- User placement of defense units
- Offense unit spawning

In addition, we aimed to include various types of defensive and offensive units, as well as adjustable game difficulty. Our primary focus was basic functionality, specifically that defensive units could attack offensive units to prevent them from reaching the home base. Another critical aspect of the game was allowing the user to choose where to place defensive units. Overall, the expected gameplay involves circles shooting projectiles at advancing squares, with each entity having a set amount of health and being eliminated once that health is depleted. The user interacts with the game by strategically placing defensive units to stop the offensive units from reaching the base.

[diagram]

**How To Setup the Game**

The required hardware are listed below:
- Nexys A7-100T FPGA Board
- VGA Cable
- Micro USB Cable
- Monitor with VGA port
- Computer with Vivado installed

The required steps to set up the game are listed below:
1. Download all necessary files (list of files)
2. Connect computer to the Nexys A7-100T FPGA board using the micro USB cable
3. Connect the Nexys A7-100T FPGA board to the monitor using the VGA cable
4. Create new RTL project on Vivado
5. For source files, add in all .vhd files
6. For constraint files, add in all .xdc files
7. For "Default Part", choose "Nexys A7-100T" under “Boards”
8. Run synthesis
9. Run implementation
10. Generate bitstream
11. Open the hardware manager
12. Select "Open Target" and "Autoconnect"
13. Select "Program Device" and click on xc7a100t_0

After performing all these steps, the game should be displayed on the monitor.

---

**Inputs and Outputs**

vga_grid
```
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
        btnd : IN STD_LOGIC
    );
END ENTITY;
```
Generics for vga_grid:
- square_size: defines the width and height of every square within the grid (in pixels)
- line_thickness: specifies the thickness of the lining of the grid (in pixels)

Inputs for vga_grid:
- clk: the system clock, drives VGA timing logic and internal state machines
- reset_n: active-low reset signal, resets the VGA controller and internal logic to a known initial state
- btnl: input button used to move cursor left
- btnr: input button used to move cursor right
- btnc: input button used to select/confirm
- btnu: input button used to move cursor up
- btnd: input button used to move cursor down

Outputs for vga_grid:
- vga_r: 3-bit red color channel output for VGA
- vga_g: 3-bit green color channel output for VGA
- vga_b: 3-bit blue color channel output for VGA
- vga_hsync: Horizontal synchronization signal required by the VGA standard
- vga_vsync: Vertical synchronization signal required by the VGA standard


v



