include "addrs.inc"

SECTION  "Vblank", ROM0[$0040]
  reti
SECTION  "LCDC", ROM0[$0048]
  reti
SECTION  "Timer_Overflow", ROM0[$0050]
  reti
SECTION  "Serial", ROM0[$0058]
  reti
SECTION  "p1thru4", ROM0[$0060]
  reti

; Point-of-entry
SECTION  "start", ROM0[$0100]

  nop
  jp main

SECTION "variables", WRAM0
COUNTER:: ds 1

SECTION "main", ROMX

main::
  nop
.reset
  xor a
  ld [COUNTER], a

; Counts up from 0, in units of 19
.loop
  ld a, [COUNTER]
  ld b, a
  ld a, $13 ; 19
  add a, b
  ld [COUNTER], a
  jp .loop
