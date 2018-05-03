# TreeFarm

## Problem

Do you need fuel for your turtles? Gathering resources with your turtles isn't efficient?
Don't cry anymore...
**Automatic turtle tree farm is solution for you!**

This program will gather wood, saplings, log for you! You can process wood into coal.

## Introduction

Minecraft automatic tree farm using computercraft mod

### Features:
* Unlimited size *( Need more optimizations - lag - Recommended max ( 10+10 )x( 10+10 ) size )*
* Unlimited Turtle count *( Need more optimizations - lag - Recommended max 30 turtles )*
* Self sufficient *( You only need to create automatic log to coal processing )*
* Automatic refueling

### Resources needed:
* Coal ( starting fuel for each turtle ( ~64 coal ) )
* Chest x5
* Turtle with wireless modem and pickaxe or axe;
* Saplings ( depends on farm size )
* Dirt ( depends on farm size )
* Torches ( depends on farm size )
* Computer with wireless modem
	* *(Optimal) Monitor*

### Program files

* lain.lua - In game rename to - *lain*
	* library with
		* Turtle movement functions
		* Display functions
* worker.lua
	* Turtle program
	* - uses lain library
* control.lua
	* Control computer ( Server ) program
	* - uses lain library

### Installation

![Image](../development/screenshots/j.png?raw=true)

0. Setup farm
	1. Choose Treefarm location ( Advice: place block in the ground like in image )
		- Farm location needs to be flattened
	2. Place 5 chests like in the first image ( one block space between them )
	3. Fill chests from the right side with: *(Turtle will build farm only if there is enough resources)*
		0. Nothing
			- Chest will be used for harvested wood
		1. Birch saplings
		2. Fuel ( Coal )
		3. Torches
		4. Dirt
1. Setup server computer
	0. Place computer on ground and attach modem ( right side )
		- Optimal - Attach monitor ( back side )
	1. Download *lain.lua*, *control.lua* files
	2. Rename *lain.lua* to *lain*
	3. Launch *control.lua*
	4. Answer all questions
		- TreeFarm coordinates are coordinates what you see when standing on block before the first chest from the right side (*obisidan* block in image) and looking to the first (*Wood*/empty) chest
		- Recommended: don't use farm larger than 15, 15, 15, 15
	5. Restart computer
	6. Rename *control.lua* to *startup*
	7. Restart computer
2. Setup turtle
	0. Place turtle with wireless modem (right side) and pickaxe or axe on the ground
	1. Download *lain.lua*, *worker.lua* files
	2. Rename *worker.lua* to *startup*
	3. Restart turtle
	4. Answer all questions
		- Cordinates - turtle block coordinates and facing direction
	5. Insert Coal in the last inventory slot
3. Setup Wood to Coal processing ( For full self sufficiently )

> If some computer isn't working like expected - reboot. Please report problems.

### Screenshots

![Image](../development/screenshots/j.png)

![Image](../development/screenshots/i.png)

![Image](../development/screenshots/k.png)

![Image](../development/screenshots/o.png)

![Image](../development/screenshots/q.png)

![Image](../development/screenshots/f.png)

![Image](../development/screenshots/w.png)

![Image](../development/screenshots/y.png)

![Image](../development/screenshots/u.png)

![Image](../development/screenshots/zz.png)

*Wood to coal processing*

![Image](../development/screenshots/set.png)

## To do

* (High priority) More efficient sapling gathering

* Support for larger farm size
	* Divide program saved log data into multiple files (*robot.log*)
		* Less data to resave in each move
* Support larger turtle count
	* Problem: traffic congestion at first supply chest
	* Problem: slow job assignment

* (Low priority) Automatic production of coal
	- Can be done more efficient with other mods...

