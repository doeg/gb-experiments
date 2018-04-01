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
  jp main

SECTION "variables", WRAM0
COUNTER:: ds 3
COUNTER_BYTES EQU 3
COUNTER_LEN EQU 6
COUNTER_INCR EQU $01 ; 5
pCOUNTER_MAP_POS EQU $9988

; Address of "0" tile
pASCII_TILE_ZERO EQU $81a0

SECTION "main", ROMX

main::
  nop

.wait_vblank
  push af
.vblank_loop
  ld A, [pLCD_LINE_Y]
  cp 144
  jr nz, .vblank_loop
  pop af

.disable_interrupts
  di
.lcd_off
  ld hl, pLCD_CTRL
  res 7, [hl]
.enable_vblank
  ld a, %00000001
  ld [pINTERRUPT_ENABLE], a
.load_ascii
  ld bc, ascii
  ld hl, pASCII_TILE_ZERO
  ld de, ascii_end - ascii
  call memcpy
.enable_interrupts
  ei
.lcd_on
  ld hl, pLCD_CTRL
  set 7, [hl]

.reset_counter
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

on_vblank::
  push af
  push bc
  push hl

.draw_lowest_digit
  xor a
  ld b, a
  ld c, a

  ld hl, COUNTER
  ld a, [hl]
  and a, $0f
  add a, $1a
  ; ld c, a

; .calc_tile_addr
  ; ld hl, pASCII_TILE_ZERO
  ; hl now contains the address of the tile to draw
  ; add hl, bc

  ld hl, $9988
  ld [hl], a

  pop hl
  pop bc
  pop af
  reti

ascii:
  db $00, $00, $18, $18, $24, $24, $2c, $2c, $34, $34, $24, $24, $18, $18, $00, $00
  db $00, $00, $18, $18, $08, $08, $08, $08, $08, $08, $08, $08, $1c, $1c, $00, $00
  db $00, $00, $18, $18, $24, $24, $04, $04, $08, $08, $10, $10, $3c, $3c, $00, $00
  db $00, $00, $38, $38, $04, $04, $18, $18, $04, $04, $04, $04, $38, $38, $00, $00
  db $00, $00, $20, $20, $28, $28, $28, $28, $3c, $3c, $08, $08, $08, $08, $00, $00
  db $00, $00, $3c, $3c, $20, $20, $38, $38, $04, $04, $04, $04, $38, $38, $00, $00
  db $00, $00, $18, $18, $20, $20, $38, $38, $24, $24, $24, $24, $18, $18, $00, $00
  db $00, $00, $3c, $3c, $04, $04, $08, $08, $10, $10, $10, $10, $10, $10, $00, $00
  db $00, $00, $18, $18, $24, $24, $18, $18, $24, $24, $24, $24, $18, $18, $00, $00
  db $00, $00, $18, $18, $24, $24, $24, $24, $1c, $1c, $04, $04, $18, $18, $00, $00
ascii_end:
