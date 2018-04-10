include "addrs.inc"
include "memory.inc"

; Shadow OAM. Needs to be 16-byte aligned. The last two hex digits of the
; address are assumed to be 00 during DMA transfer (through use of `ldh`).
SECTION "shadow_oam", WRAM0, ALIGN[2]
pSHADOW_OAM:: ds 40 * 4 ; $c000

SECTION "variables", WRAM0

; Set to 1 whenever the vblank handler occurs.
; This is so that game logic can take place in the main loop while still
; retaining a loop rate (or frequency) equal to vblank (60 times/second).
pVBLANK_FLAG:: ds 1

; Each individual tile is 16 bytes
TILE_SIZE_BYTES EQU 16

; Each sprite is composed of 4 tiles
SPRITE_SIZE_BYTES EQU TILE_SIZE_BYTES * 4

; The location of all Gengar tiles in VRAM. This places the sprites
; after the Nintendo logo.
pGENGAR_TILES EQU pVRAM_TILES_SPRITE + $01a0

pGENGAR_X:: ds 1
GENGAR_X_DEFAULT EQU $50

pGENGAR_Y:: ds 1
GENGAR_Y_DEFAULT EQU $46

; 0 - open
; 1 - closed
pGENGAR_CURRENT_FRAME:: ds 1

pGENGAR_FRAME_COUNTER:: ds 1
GENGAR_FRAME_RATE EQU 15

SECTION  "Vblank", ROM0[$0040]
  jp pHRAM
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

SECTION "main", ROMX
init::
  nop

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

.set_sprites_enabled
  ld hl, pLCD_CTRL
  set 1, [HL]

.clear_hram
  ; Clear HRAM. -2 to save room for the stack,
  ; and because the range is inclusive.
  xor a
  ld hl, pHRAM
  ld bc, pHRAM_END - pHRAM - 2
  call memset

.clear_oam::
  xor a
  ld hl, $FE00 ; start of OAM
  ld bc, $A0 ; the full size of the OAM area: 40 bytes, 4 bytes per sprite
  call memset

  xor a
  ld hl, pSHADOW_OAM
  ld bc, $9f
  call memset

; Copies the DMA handler code to HRAM
.init_dma
  ld de, on_vblank_end - on_vblank + 1
  ld bc, on_vblank
  ld hl, pHRAM
  call memcpy

.set_palettes
  ld hl, pLCD_BG_PAL
  LD [hl], %11111100
  ld hl, pOBJ0_PAL
  ld [hl], %11100100
  ld hl, pOBJ1_PAL
  ld [hl], %11100100

.init_variables::
  ld hl, pGENGAR_X
  ld [hl], GENGAR_X_DEFAULT
  ld hl, pGENGAR_Y
  ld [hl], GENGAR_Y_DEFAULT

  xor a
  ld [pGENGAR_CURRENT_FRAME], a

  ld a, GENGAR_FRAME_RATE
  ld [pGENGAR_FRAME_COUNTER], a

.load_tiles
  ld bc, gengar ; source
  ld hl, pGENGAR_TILES  ; dest
  ld de, SPRITE_SIZE_BYTES * 2  + 1  ; size
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
.clear_vblank_flag
  xor a
  ld [pVBLANK_FLAG], a
.do_stuff
  call draw_gengar_0
.continue
  jr main_loop


draw_gengar_0::
  ; a - accumulator
  ; b - gengar y-pos
  ; c - gengar x-pos
  ; d - tile index
  ; e - dunno but it's used
  push af
  push bc
  push de
  push hl

.dec_frame_counter
  ld hl, pGENGAR_FRAME_COUNTER
  dec [hl]
  jr nz, .done

  ld a, GENGAR_FRAME_RATE
  ld [pGENGAR_FRAME_COUNTER], a

.load_first_tile
  ld d, $1a

.load_current_frame
  ld a, [pGENGAR_CURRENT_FRAME]
  ; If current frame is 0, we are done and can jump to animation
  cp a, $00
  jr z, .update_frame

.set_current_tile
  ld d, $1e

  ; If current frame is 1, we need to add 4 to d (tile idx)
  ; Then we need to update pGENGAR_CURRENT_FRAME in memory to the next frame
.update_frame
  ld a, [pGENGAR_CURRENT_FRAME]
  cpl
  ld [pGENGAR_CURRENT_FRAME], a

.load_position
  ld hl, pGENGAR_Y
  ld b, [hl]
  ld hl, pGENGAR_X
  ld c, [hl]

.top_left
  ld hl, pSHADOW_OAM
  ld [hl], b
  inc l
  ld [hl], c
  inc l
  ld [hl], d; tile number
  inc d

.top_right
  ld hl, pSHADOW_OAM + $04
  ld e, c
  ld a, c
  adc a, 8
  ld c, a
  ld [hl], b ; y-pos
  inc l
  ld [hl], c ; x-pos
  inc l
  ld [hl], d; tile number
  inc d

.bottom_left
  ld hl, pSHADOW_OAM + $0c
  ld a, b
  adc a, 8
  ld b, a
  ld [hl], b ; y-pos
  inc l
  ld [hl], e ; x-pos
  inc l
  ld [hl], d; tile number
  inc d

.bottom_right
  ld hl, pSHADOW_OAM + $08
  ld [hl], b ; y-pos
  inc l
  ld [hl], c ; x-pos
  inc l
  ld [hl], d; tile number

.done
  pop hl
  pop de
  pop bc
  pop af
  ret


; V-blank interrupt handler code. This is not jumped to directly.
; Rather, it is copied to HRAM by the `.init_dma` block. Sets
; the pVBLANK_FLAG to one to indicate that the main loop should run
; (giving a main loop frequency of ~60 times/second).
on_vblank::
  push af
.set_vblank_flag
  ld a, 1
  ld [pVBLANK_FLAG], a
.invoke_dma
  ; Division by 100 since we're in HRAM, and all addresses for ldh are
  ; relative to $FF00
  ld a, pSHADOW_OAM / $100
  ldh [pOAM_DMA_TRANS], a
  ; Delay for 28 (5 x 50) cycles (~200ms)
  ld a, $28
.dma_wait
  dec a
  jr nz, .dma_wait
.dma_wait_done
  pop af
  reti
on_vblank_end::

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
