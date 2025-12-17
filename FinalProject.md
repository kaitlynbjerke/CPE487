# Circles vs. Squares - CPE 487 Final Project
**By Kaitlyn Bjerke, Jacqueline Castro, and Gianina Maldonado**

A tower defense game, based on Plants Vs Zombies

---

## Introduction

For our final project, we were tasked with creating a game using the VHDL language. This project allowed us to test our knowledge of VHDL while also expanding into topics that were not covered extensively in class. For our game, we decided to mimic the functional mechanics of Plants vs. Zombies. To recreate this concept, we developed a game titled **Circles vs. Squares**, where circles represent the plants and squares represent the zombies. Note, much of our code refers to the entities as plants and zombies, but to match what is displayed, the game is titled **Circles vs. Squares**!

[image of plants vs zombies]

We considered various game mechanics from Plants Vs Zombies, including:

- Defensive Units (circles/plants)
- Offensive Units (squares/zombies)
- Projectile system (bullet)
- Health system
- Attack timing
- Collision
- User placement of defense units
- Offense unit spawning

In addition, we aimed to include various types of defensive and offensive units, as well as adjustable game difficulty. Our primary focus was basic functionality, specifically that defensive units could attack offensive units to prevent them from reaching the home base. Another critical aspect of the game was allowing the user to choose where to place defensive units. Overall, the expected gameplay involves circles shooting projectiles at advancing squares, with each entity having a set amount of health and being eliminated once that health is depleted. The user interacts with the game by strategically placing defensive units to stop the offensive units from reaching the base.

[diagram]

## How To Setup the Game

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

## Inputs and Outputs

**vga_grid**
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
        btnd : IN STD_LOGIC;
        hard: IN STD_LOGIC;
        pass : out std_logic:='0'
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
- hard: difficulty control input

Outputs for vga_grid:
- vga_r: 3-bit red color channel output for VGA
- vga_g: 3-bit green color channel output for VGA
- vga_b: 3-bit blue color channel output for VGA
- vga_hsync: horizontal synchronization signal required by the VGA standard
- vga_vsync: vertical synchronization signal required by the VGA standard
- pass: status output signal


**vga_sync**
```
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
```
Inputs for vga_sync:
- pixel_clk: pixel clock used to drive VGA timing
- red_in: 4-bit red color input for the current pixel
- green_in: 4-bit green color input for the current pixel
- blue_in: 4-bit blue color input for the current pixel

Outputs for vga_sync:
- red_out: 4-bit red color output synchronized with VGA timing
- green_out: 4-bit green color output synchronized with VGA timing
- blue_out: 4-bit blue color output synchronized with VGA timing
- hsync: horizontal synchronization signal required by the VGA standard
- vsync: vertical synchronization signal required by the VGA standard
- pixel_row: current vertical pixel position on the screen
- pixel_col: current horizontal pixel position on the screen


**plant**
```
 COMPONENT plant
        PORT (
            v_sync       : IN STD_LOGIC;
            pixel_row    : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            pixel_col    : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            plant_enable : IN STD_LOGIC;
            take_damage  : IN STD_LOGIC;
            damage_amt   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            shoot_enable : IN STD_LOGIC;
            red          : OUT STD_LOGIC;
            green        : OUT STD_LOGIC;
            blue         : OUT STD_LOGIC;
            start_x        : in integer;
            start_y         : in integer;
            num             : in integer
        );
    END COMPONENT;
```
Inputs for plant:
- v_sync: vertical synchronization signal from the VGA controller
- pixel_row: current vertical pixel coordinate being drawn on the screen
- pixel_col: current horizontal pixel coordinate being drawn on the screen
- plant_enable: enables or disables the plant
- take_damage: indicates that the plant has been hit by an offensive unit
- shoot_enable: specifying how much damage the plant takes when take_damage is asserted
- start_x: horizontal starting position of the plant (in pixels)
- start_y: vertical starting position of the plant (in pixels)
- num: identifies plant instance

Outputs for plant:
- red: red color output for the plant at the current pixel location
- green: green color output for the plant at the current pixel location
- blue: blue color output for the plant at the current pixel location

**bullet**
```
COMPONENT bullet
        PORT (
            v_sync       : IN STD_LOGIC;
            pixel_row    : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            pixel_col    : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            bullet_enable : IN STD_LOGIC;  -- '1' to spawn/activate bullet
            start_x       : IN STD_LOGIC_VECTOR(10 DOWNTO 0);  -- Starting X position
            start_y       : IN STD_LOGIC_VECTOR(10 DOWNTO 0);  -- Starting Y position
            bullet_active : OUT STD_LOGIC;  -- '1' when bullet is active/visible
            bullet_x_pos  : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);  -- Current X position
            bullet_y_pos  : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);  -- Current Y position
            red          : OUT STD_LOGIC;
            green        : OUT STD_LOGIC;
            blue         : OUT STD_LOGIC;
            placed       : in std_logic
        );
    END COMPONENT;
```
Inputs for bullet:
- v_sync: vertical synchronization signal from the VGA controller
- pixel_row: current vertical pixel coordinate being drawn
- pixel_col: current horizontal pixel coordinate being drawn
- bullet_enable: activates bullet
- start_x: initial horizontal position of the bullet in pixels
- start_y: initial vertical position of the bullet in pixels
- placed: indicates whether bullet has been placed

Outputs for bullet:
- bullet_active: indicates whether the bullet is currently active
- bullet_x_pos: current horizontal pixel position of the bullet
- bullet_y_pos: current vertical pixel position of the bullet
- red: red color output for the bullet at the current pixel location
- green: green color output for the bullet at the current pixel location
- blue: blue color output for the bullet at the current pixel location

**zombie**
```
 COMPONENT ball
        PORT (
            v_sync     : IN STD_LOGIC;
            pixel_row  : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            pixel_col  : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            red        : OUT STD_LOGIC;
            green      : OUT STD_LOGIC;
            blue       : OUT STD_LOGIC;
            zom_enable : IN STD_LOGIC;
            zom_damage : IN STD_LOGIC;
            attack     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            zom_alive  : OUT STD_LOGIC;
            zom_health : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
            zom_loc_x    : OUT INTEGER RANGE 0 TO 1023;
            zom_loc_y    : OUT INTEGER RANGE 0 TO 1023;
            offset     : IN INTEGER RANGE 0 TO 1023
            start_x        : in integer;
            start_y         : in integer;
            hit_count       : in integer range 0 to 1023;
            hard            : std_logic
        );
    END COMPONENT;
```
Inputs for zombie:
- v_sync: vertical synchronization signal from the VGA controller
- pixel_row: current vertical pixel coordinate being drawn
- pixel_col: current horizontal pixel coordinate being drawn
- zom_enable: enables the zombie
- zom_damage: indicates that the zombie has taken damage
- attack: the amount of damage inflicted on the zombie when zom_damage is asserted
- offset: positional offset value used to control the zombie’s horizontal placement and movement timing
- start_x: specifies the initial horizontal position of the zombie 
- start_y: specifies the initial vertical position of the zombie
- hit_count: tracks the number of times the zombie has been hit by projectiles
- hard: difficulty control signal

Outputs for zombie:
- red: red color output for the zombie at the current pixel location
- green: green color output for the zombie at the current pixel location
- blue: blue color output for the zombie at the current pixel location
- zom_alive: indicates whether the zombie is still alive
- zome_health: current health value of the zombie
- zom_loc_x: current horizontal position of the zombie in pixels
- zom_loc_y: current vertical position of the zombie in pixels

---
## Project in Action!

[project in action[

## The Process

Although we used some logic from previous labs, we did not do a continuation project and instead made this game from scratch. To begin, we assessed the various aspects of the original game we needed to implement into our game as listed in the **Introduction**. In order to match the same game mechanics, we decided to begin with creating a grid on the screen. This grid functions to easily display where the plants can be placed, outlines the path the zombie and bullet will travel through, and generally matches the background of the original game. This initial grid showed to be a big obstacle for us. At first, it would not display on the screen, and it came out a bit wonky when it did eventually display. Meanwhile, the initial plant entity and zombie entity were being created as to not fall too behind with the grid. Since these three were done individually, we found there to be many inconsistencies with sizes, speeds, colors, etc. This impacted the functionality of the game. 

[image of grid inconsistency]

[image of early plant and zombie]

Before combining all the code, we made sure all entities worked individually and then began matching every entity to one another for visualization and functionality. After a few runs, we were able to get a working game where a plant and zombie in motion were displayed on top of the grid.

[image of plant and zombie on grid]

Now that we were able to get a basic display, we had to tackle evolving the plant and zombie to involve more complexity. We also began to work on the bullet entity. For the plant and zombie, we implemented health, taking damage, and attacks. We also implemented enabling inputs and positioning outputs. From these additions, we were able to include collision which is a key part of the game's functionality. This will be expanded on later in the project.

Nextly, we worked on getting the plant to move based on the user's input. This is where the btnl, btnr, btnu, btnd, and btnc button come into play as the user chooses where to place their defenses. We had to make sure that when the user was moving the plant in multiple directions, the plant was moving a whole grid square, not just a pixel. Moreover, when the user had chosen where they wished to place their plant, the btnc button confirms their position. But, we needed to implement multiple plants, so after the user sets down a plant, the user can immediately place down another plant. This is where we were able to create two types of plants. The first plant is the walnut, which the user is given first and it essentially acts as a buffer or wall, it does not cause damage to the zombies. We set the walnut to be able to withstand The second plant is the pea shooter, which is the plant that actually causes damage to the zombies. The pea shooter is able to withstand. There were many bumps when creating these objects including timing errors, visual errors, and control bugs. 

As for the zombies, we had set the various 



