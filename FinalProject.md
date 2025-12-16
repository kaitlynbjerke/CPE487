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


