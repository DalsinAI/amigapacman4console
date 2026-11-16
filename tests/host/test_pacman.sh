#!/bin/sh
# Host tests of the port, on this machine: amiga/curses.c and amiga/keys.c
# built with upstream's Pacman and level editor (amiga/patches applied,
# __amigaos__ set, so the Amiga's code is the one built: the levels from
# PROGDIR:Levels, the waits for keys instead of busy loops) over a plain
# terminal (tests/host/console_host.c), played with keys sent over time;
# tests/host/vt.py reads back the 32-line screen as the Amiga's console
# would show it:
#  - curses: the screen is 40 x 32 (ACURSES_LINES/_COLS), the game's
#    check for 32 lines passes;
#  - the intro, skipped by a key; level 1 from PROGDIR:Levels: walls in
#    the wall pair's colours, pellets, power pellets, Pacman, the ghosts,
#    the status line;
#  - Pacman eats by itself (the score goes up), the cursor keys and
#    W A S D turn him;
#  - P pauses until a key; Q ends the game with the score;
#  - no level file: the message names PROGDIR:Levels/level01.dat;
#  - the editor loads a level, Q saves it (unchanged) and ends.
# Needs a C compiler and python3; skipped without a compiler.
#   UP=/path/to/pacman4console (patched) sh tests/host/test_pacman.sh
# Copyright (c) 2026 AmiCradle Team. MIT (the port's own files).
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
UP=${UP:?UP=upstream source}
CC=${HOSTCC:-cc}
command -v "$CC" >/dev/null 2>&1 || { echo "host tests: skipped (no C compiler)"; exit 0; }
T=$(mktemp -d "${TMPDIR:-/tmp}/pacman-host.XXXXXX")
[ -n "${TEST_KEEP:-}" ] || trap 'rm -rf "$T"' EXIT INT TERM
cd "$ROOT"

MINE="-std=gnu99 -Wall -Werror -D_XOPEN_SOURCE=600 -D_DEFAULT_SOURCE -Iamiga/include -Iamiga -DACURSES_LINES=32 -DACURSES_COLS=40"
for f in curses keys; do $CC $MINE -c -o "$T/$f.o" "amiga/$f.c"; done
$CC $MINE -c -o "$T/con.o" tests/host/console_host.c
for f in pacman pacmanedit; do
    $CC -std=gnu11 -w -Werror=implicit-function-declaration -D_DEFAULT_SOURCE -D__amigaos__ \
        -Iamiga/include -Iamiga -I"$UP" -c -o "$T/u_$f.o" "$UP/$f.c"
    $CC -o "$T/$f" "$T/u_$f.o" "$T/curses.o" "$T/keys.o" "$T/con.o"
done
# PROGDIR: is the program's drawer on the Amiga; here a directory of that name
mkdir -p "$T/PROGDIR:Levels"; cp "$UP"/Levels/*.dat "$T/PROGDIR:Levels/"
fails=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; fails=$((fails + 1)); }

cat > "$T/size_test.c" <<'C'
#include <stdio.h>
#include "curses.h"
int main(void)
{
	int h, w;
	initscr(); getmaxyx(stdscr, h, w); endwin();
	if (h != 32 || w != 40 || LINES != 32 || COLS != 40) { fprintf(stderr, "%d x %d\n", w, h); return 1; }
	return 0;
}
C
$CC $MINE -o "$T/size_test" "$T/size_test.c" "$T/curses.o" "$T/keys.o" "$T/con.o"
if "$T/size_test" > /dev/null 2> "$T/size.err"; then pass "curses: a 40 x 32 screen"; else fail "curses size: $(cat "$T/size.err")"; fi

play() {	# program, output, then WAIT KEYS pairs (seconds, printf formats) [WAIT]
    prog=$1; out=$2; shift 2
    (
        while [ $# -ge 2 ]; do sleep "$1"; printf "$2"; shift 2; done
        [ $# -eq 1 ] && sleep "$1"
    ) | (cd "$T" && timeout 60 $prog > "$out" 2> "$out.err") || true
}
screen() { python3 "$HERE/vt.py" "$1" --rows 32; }
want() {	# name, output, texts...
    name=$1; out=$2; shift 2
    n=$#
    for t in "$@"; do set -- "$@" --want "$t"; done
    shift "$n"
    if python3 "$HERE/vt.py" "$out" --rows 32 "$@" > "$T/vt.txt"; then pass "$name"; else fail "$name"; cat "$T/vt.txt"; fi
}
score() { screen "$1" | grep -o 'Score: [0-9]*' | tail -1 | tr -dc 0-9; }
pac_x() { screen "$1" | sed -n 2,30p | awk '{ i = index($0, "C"); if (i) { print i; exit } }'; }

play ./pacman "$T/intro.out" 0.5
want "the intro" "$T/intro.out" "Press any key..."
if ! grep -q "Sorry" "$T/intro.out" "$T/intro.out.err"; then pass "the game's 32-line check passes"; else fail "the game finds the screen too small"; fi

play ./pacman "$T/level.out" 0.3 x 0.6
want "level 1 and the status line" "$T/level.out" "Level: 1" "Score:" "."
if screen "$T/level.out" | grep -q '\*'; then pass "power pellets"; else fail "no power pellets"; fi
if screen "$T/level.out" | grep -q '&'; then pass "the ghosts"; else fail "no ghosts"; fi
if grep -q "$(printf '\033')\[0;37;47m" "$T/level.out"; then pass "walls in the wall pair (SGR 37;47)"; else fail "no walls"; fi

play ./pacman "$T/eat.out" 0.3 x 3.5
if [ "$(score "$T/eat.out")" -gt 0 ]; then pass "Pacman eats by himself (score $(score "$T/eat.out"))"; else fail "no score"; screen "$T/eat.out"; fi

# turning: right by the cursor key, left by A, from the same start
play ./pacman "$T/right.out" 0.3 x 1.2 '\033[C' 1.2
play ./pacman "$T/left.out" 0.3 x 1.2 'a' 1.2
xr=$(pac_x "$T/right.out"); xl=$(pac_x "$T/left.out")
if [ -n "$xr" ] && [ -n "$xl" ] && [ "$xr" -gt "$xl" ]; then pass "the cursor keys and A turn him ($xl < $xr)"; else fail "turning: left $xl, right $xr"; screen "$T/right.out"; fi

play ./pacman "$T/pause.out" 0.3 x 1.0 p 1.0
want "P pauses" "$T/pause.out" "*PAUSED*"
play ./pacman "$T/quit.out" 0.3 x 1.0 q 0.3
if grep -q "Bye" "$T/quit.out" && grep -q "Score: " "$T/quit.out"; then pass "Q ends the game with the score"; else fail "Q: $(tail -c 200 "$T/quit.out" | tr -d '\033')"; fi

mv "$T/PROGDIR:Levels" "$T/PROGDIR:Gone"
play ./pacman "$T/none.out" 0.3 x 0.5
mv "$T/PROGDIR:Gone" "$T/PROGDIR:Levels"
if grep -q "Cannot find level file: PROGDIR:Levels/level01.dat" "$T/none.out"; then pass "no level file: the message names PROGDIR:Levels"; else fail "no level file: $(tail -c 200 "$T/none.out")"; fi

cp "$T/PROGDIR:Levels/level02.dat" "$T/edit.dat"
play "./pacmanedit edit.dat" "$T/edit.out" 0.5 q 0.3
want "the editor draws the level and its keys" "$T/edit.out" "F/C/Q"
# the editor writes the 29 x 28 values it read (level02.dat has one more after them)
vals() { tr -s ' \t\n' '\n\n\n' < "$1" | grep . | head -n 812; }
if grep -q "File saved as: edit.dat" "$T/edit.out" && [ "$(vals "$T/edit.dat")" = "$(vals "$T/PROGDIR:Levels/level02.dat")" ]; then
    pass "the editor's Q saves the level (unchanged)"
else
    fail "the editor's save: $(tail -c 200 "$T/edit.out")"
fi

if [ "$fails" -ne 0 ]; then echo "host tests: $fails failed"; exit 1; fi
echo "host tests: all passed"
