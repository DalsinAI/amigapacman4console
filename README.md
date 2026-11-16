# Pacman For Console for GFOS

The AmiCradle Team's port of Mike Billars' Pacman For Console 1.2, a
Pacman game for the text console, and its level editor, to GFOS: AmigaOS
3.2 with GFOpenUp, 68040/68060. They run in their own 40 x 32 console
window, in colour: no SDL, no ACGame and no GFOpenGPU. It ships as a
release archive with an Installer and as the GFOpenUp part
Parts/Pacman4Console.

Upstream is fetched at build time (package/pacman4console.lock) and
patched (amiga/patches); this repository holds only the Amiga port. See
[AMIGA_PORT.md](AMIGA_PORT.md).

Pacman For Console is GPL-2.0 (COPYING.txt in the drawer); the port's own
files (amiga/, tests/, package/, tools/) are MIT. Copyright (c) 2026
AmiCradle Team.
