Pacman For Console for GFOS
===========================

Mike Billars' Pacman For Console: eat every pellet in the maze while
four ghosts chase you. A power pellet (*) turns the ghosts blue for a
while, and then Pacman can eat them. Nine levels, one after another.

The cursor keys (or W, A, S and D) turn Pacman. P pauses until a key,
Q ends the game (as does the window's close gadget) and shows the score.
Pacman N starts at level N (1 to 9); Pacman FILE plays a level file.

PacmanEdit, from a Shell, edits a level file: PacmanEdit FILE. The
cursor keys (or W A S D) move the cursor, 0 to 9 put a blank, a wall, a
pellet, a power pellet, the ghosts' door, the ghosts (5 to 8) and Pacman
(9); F fills the blanks with pellets, C clears the pellets, Q saves the
file and ends. The game's own levels are in the drawer's Levels.

What it needs
-------------
GFOS (AmigaOS 3.2 with GFOpenUp) on a 68040 or 68060; the FPU is not
needed. The game runs in a console window 32 lines high on any screen
with eight colours or more: no SDL, no ACGame, no GFOpenGPU.

How it was ported
-----------------
The game is built from upstream as it is, with one patch
(amiga/patches/0001): the levels come from PROGDIR:Levels; pauses are
dos.library Delay; the game and the editor wait for keys (curses'
timeout) where upstream reads them in a loop that would keep the CPU
busy; the closing message and the score stay in the window until a key.

amiga/curses.c is the part of ncurses the game uses: the layer of
DalsinAI/amiga2048 (windows in memory, a refresh that sends the console
only what changed, as ANSI that console.device reads, colour pairs on the
screen's first eight pens), here built for a 40 x 32 screen.
amiga/console_amiga.c opens the window, puts it in raw mode and reads the
keys (amiga/keys.c: the cursor keys as curses' KEY_*).

Tests: tests/host/test_pacman.sh builds the game and the editor on the
build machine over a plain terminal, plays them with keys sent over time
and reads back the screen: the 40 x 32 screen, the intro, level 1 from
PROGDIR:Levels (walls, pellets, power pellets, ghosts, status line),
Pacman eating and turning by cursor keys and by A, P, Q with the score,
the message for a missing level, the editor's drawing and its save.

Credits
-------
Pacman For Console (c) 2006 Mike Billars, GPL-2.0 (COPYING.txt).
Amiga port: Designed, tested and delivered by The AmiCradle Team.
Copyright (c) 2026 AmiCradle Team; the port's own files MIT.
