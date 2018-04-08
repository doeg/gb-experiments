include "addrs.inc"

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

.clear_oam::
  xor a
  ld hl, $FE00 ; start of OAM
  ld bc, $A0 ; the full size of the OAM area: 40 bytes, 4 bytes per sprite
  call mem_set

  xor a
  ld hl, pSHADOW_OAM
  ld bc, $9f
  call mem_set

; Copies the DMA handler code to HRAM
.init_dma
  ld de, on_vblank_end - on_vblank + 1
  ld bc, on_vblank
  ld hl, pHRAM
  call memcpy

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
  ; Do stuff here
.continue
  jr main_loop

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

; Set a memory region to a value.
; From GBHW.INC - Gameboy Hardware definitions for GALP.
;
; a - value
; hl - pMem
; bc - bytecount
;
mem_set::
  push bc
  push hl
	inc	b
	inc	c
	jr	.skip
.loop	ld	[hl+],a
.skip	dec	c
	jr	nz,.loop
	dec	b
	jr	nz,.loop
  pop hl
  pop bc
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
