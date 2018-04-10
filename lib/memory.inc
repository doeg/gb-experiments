SECTION "memory", ROMX

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
memset::
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
