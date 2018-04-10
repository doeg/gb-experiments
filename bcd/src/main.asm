include "memory.inc"

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

SECTION "variables", WRAM0
; Constants
COUNTER_BYTES EQU 5
COUNTER_LEN EQU COUNTER_BYTES * 2
COUNTER_INCR EQU 1 ; 5
COUNTER_TIMER EQU 60

; Variables
pCOUNTER:: ds 5
pVBLANK_FLAG:: ds 1
pCOUNTER_TIMER:: ds 1

; Address of "0" tile
pASCII_TILE_ZERO         EQU $81a0
; BG map address of leftmost digit
pCOUNTER_MAP_POS         EQU $9984

; Game Boy addresses
pLCD_CTRL                EQU $ff40
pLCD_LINE_Y              EQU $ff44
pINTERRUPT_ENABLE        EQU $ffff

SECTION "main", ROMX

init::
  nop

.wait_vblank_loop
  ld A, [pLCD_LINE_Y]
  cp 144
  jr nz, .wait_vblank_loop

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
  ld hl, pCOUNTER
  ld b, COUNTER_BYTES
  xor a
.reset_counter_loop
  ld [hl], a
  inc l
  dec b
  jr nz, .reset_counter_loop

.init_counter_timer
  ld a, COUNTER_TIMER
  ld [pCOUNTER_TIMER], a

.main_loop
  halt
  nop

.check_vblank_flag
  ld a, [pVBLANK_FLAG]
  or a
  jr z, main

.clear_vblank_flag
  xor a
  ld [pVBLANK_FLAG], a

.dec_counter_timer
  ld hl, pCOUNTER_TIMER
  dec [hl]
  jr nz, .continue

  call inc_counter

.reset_counter_timer
  ld a, COUNTER_TIMER
  ld [pCOUNTER_TIMER], a

.continue
  jr .main_loop

; Increments the value of the counter (in memory) by COUNTER_INCR,
; adjusting for BCD.
inc_counter::
  push af
  push bc
  push de
  push hl

  ld c, COUNTER_INCR
  ld hl, pCOUNTER
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
.counter_loop_done
  pop hl
  pop de
  pop bc
  pop af
  ret

; V-blank interrupt handler. Draws the digits of the counter's current value
; to the screen (as background tiles).
on_vblank::
  push af
  push bc
  push de
  push hl
.draw_loop_init
  ; bc tracks our position in the COUNTER's bytes. If the number we're drawing
  ; is "9876543210", then the value of pCOUNTER ($c000) is:
  ;
  ;  |  10  |  32  |  54  |  76  |  98  |
  ;   c000   c001   c002   c003   c004
  ;
  ; In this case, COUNTER_BYTES is 5 since the number is 5 bytes (10 digits).
  ld bc, $00
  ; de tracks our position on the screen (in the background map address space)
  ; as the offset from the leftmost address. On the screen we draw "backwards",
  ; right to left, one digit at a time:
  ;
  ; de val:     0     1     2     3     4     5     6     7     8     9
  ; digit:     |  9  |  8  |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
  ; address:    9986  9987  9988  9989  998A  998B  998C  998D  998E  008F
  ; direction:  <-----<-----<-----<-----<-----<-----<-----<-----<-----START
  ld de, COUNTER_LEN

.draw_loop
  nop
.draw_lo_digit
  ld hl, pCOUNTER
  add hl, bc
  ld a, [hl]
  and a, %00001111
  add a, $1a
  ld hl, pCOUNTER_MAP_POS
  add hl, de
  ld [hl], a
.draw_hi_digit
  dec e
  ld hl, pCOUNTER
  add hl, bc
  ld a, [hl]
  swap a
  and a, %00001111
  add a, $1a
  ld hl, pCOUNTER_MAP_POS
  add hl, de
  ld [hl], a
.draw_loop_continue
  inc bc
  ld a, c
  cp COUNTER_BYTES
  jr z, .draw_loop_done
  dec e
  jr .draw_loop
.draw_loop_done
  nop

.set_vblank_flag
  ld a, 1
  ld [pVBLANK_FLAG], a

.continue
  pop hl
  pop de
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
