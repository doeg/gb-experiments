include "addrs.inc"

SECTION  "Vblank", ROM0[$0040]
  jp on_vblank
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
  jp init

INCLUDE "header.inc"

SECTION "variables", WRAM0

COUNTER_TIMER EQU 60
pVBLANK_FLAG:: ds 1

pCOUNTER:: ds 3
pCOUNTER_TIMER:: ds 1

SECTION "main", ROMX
init::
  nop

.reset_counter
  xor a
  ld [pCOUNTER], a

.init_counter_timer
  ld a, COUNTER_TIMER
  ld [pCOUNTER_TIMER], a

.wait_vblank_loop
  ld A, [pLCD_LINE_Y]
  cp 144
  jr nz, .wait_vblank_loop

.screen_off
  di
  ld hl, pLCD_CTRL
  res 7, [hl]

.set_interrupts_enabled
  ld a, %00000001
  ld [pINTERRUPT_ENABLE], a

.screen_on
  ei
  ld hl, pLCD_CTRL
  set 7, [hl]

main_loop::
  halt
  nop

  ; Vblank interrupt?
  ld a, [pVBLANK_FLAG]
  or a
  ; No, some other interrupt
  jr z, main_loop

  ; Clear the vblank flag
  xor a
  ld [pVBLANK_FLAG], a

  ld hl, pCOUNTER_TIMER
  dec [hl]
  jr nz, main_loop

.update_counter
  ld hl, pCOUNTER
  inc [hl]

.reset_counter_timer
  ld a, COUNTER_TIMER
  ld [pCOUNTER_TIMER], a

.continue
  jr main_loop

on_vblank::
  push af
  ; Draw stuff... a DMA transfer would happen here
  nop
  ; And set the vblank flag
  ld a, 1
  ld [pVBLANK_FLAG], a
  pop af
  reti
