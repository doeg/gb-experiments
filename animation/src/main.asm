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

; Each individual tile is 16 bytes
TILE_SIZE_BYTES EQU 16

; Each sprite is composed of 4 tiles
SPRITE_SIZE_BYTES EQU TILE_SIZE_BYTES * 4

pGENGAR_TILES EQU $81a0

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

.load_tiles
  ld bc, gengar ; source
  ld hl, pGENGAR_TILES  ; dest
  ld de, SPRITE_SIZE_BYTES * 2   ; size
  call memcpy

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

; de - block size
; bc - source address
; hl - destination address
memcpy::
  dec de
.memcpy_loop:
  ld a, [bc]
  ld [hl], a
  inc bc
  inc hl
  dec de
.memcpy_check_limit:
  ld a, e
  cp $00
  jr nz, .memcpy_loop
  ld a, d
  cp $00
  jr nz, .memcpy_loop
  ret

gengar::
  ; Frame 0
  db $00, $00, $00, $00, $00, $00, $00, $00, $32, $32, $3f, $3f, $3f, $3f, $1f, $1b
  db $00, $00, $00, $00, $00, $00, $00, $00, $4c, $4c, $fc, $fc, $fc, $fc, $f8, $d8
  db $3f, $39, $3f, $3f, $7d, $72, $7d, $7a, $3d, $3e, $1f, $1f, $1f, $1f, $0c, $0c
  db $fc, $9c, $fc, $fc, $be, $4e, $be, $5e, $bc, $7c, $f8, $f8, $f8, $f8, $30, $30
  ; Frame 1
  db $00, $00, $00, $00, $00, $00, $00, $00, $04, $04, $3f, $3f, $3f, $3f, $1f, $1f
  db $00, $00, $00, $00, $00, $00, $00, $00, $20, $20, $fc, $fc, $fc, $fc, $f8, $f8
  db $3f, $3b, $3f, $39, $3f, $3f, $7d, $7a, $7d, $7e, $3f, $3f, $1f, $1f, $0f, $0f
  db $fc, $dc, $fc, $9c, $fc, $fc, $be, $5e, $be, $7e, $fc, $fc, $f8, $f8, $f0, $f0
