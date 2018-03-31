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
COUNTER:: ds 3
COUNTER_BYTES EQU 3
COUNTER_INCR EQU $10 ; 5

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

.counter_start
  ld c, COUNTER_INCR
  ld hl, COUNTER

; c - increment for 1s digit
; hl - address of 1byte BCD digit pair to increment
.counter_loop
  ld a, [hl]
  ld b, a
  ld a, c
  add a, b
  daa
  ld [hl], a
  jr nc, .counter_loop_done
  inc l
  ld c, 1
  jr .counter_loop
.counter_loop_done::
  nop
  ; TODO update screen here
  jr .counter_start
