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
COUNTER:: ds 2
COUNTER_BYTES EQU 2
COUNTER_INCR EQU %00000101 ; 5

SECTION "main", ROMX

main::
  nop

.reset
  ld hl, COUNTER
  ld b, COUNTER_BYTES
  xor a
.reset_counter_loop
  ld [hl], a
  inc l
  dec b
  jr nz, .reset_counter_loop

; Count up from 0
.loop
  ld a, [COUNTER]
  ld b, a
  ld a, COUNTER_INCR
  add a, b
  daa
  ld [COUNTER], a
  jp .loop
