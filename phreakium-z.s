rJOYP       EQU $ff00
rTIMA       EQU $ff05
rTMA        EQU $ff06
rTAC        EQU $ff07
rNR30       EQU $ff1a
rNR31       EQU $ff1b
rNR32       EQU $ff1c
rNR33       EQU $ff1d
rNR34       EQU $ff1e
rNR50       EQU $ff24
rNR51       EQU $ff25
rNR52       EQU $ff26
rWave_0     EQU $ff30
rWave_1     EQU $ff31
rWave_2     EQU $ff32
rWave_3     EQU $ff33
rWave_4     EQU $ff34
rWave_5     EQU $ff35
rWave_6     EQU $ff36
rWave_7     EQU $ff37
rWave_8     EQU $ff38
rWave_9     EQU $ff39
rWave_a     EQU $ff3a
rWave_b     EQU $ff3b
rWave_c     EQU $ff3c
rWave_d     EQU $ff3d
rWave_e     EQU $ff3e
rWave_f     EQU $ff3f
rLCDC       EQU $ff40
rSTAT       EQU $ff41
rSCY        EQU $ff42
rSCX        EQU $ff43
rDMA        EQU $ff46
rBGP        EQU $ff47
rOBP0       EQU $ff48
rOBP1       EQU $ff49
rIE         EQU $ffff

size_font	  EQU $0600
size_symbols  EQU $0200
tilemap       EQU $9800

name      EQUS "Phreakium-Z"
sq_0      EQU $00
arrow_u   EQU $01
arrow_d   EQU $02
arrow_r   EQU $03
arrow_l   EQU $04
line_h    EQU $05
line_v    EQU $06
corner_tl EQU $07
corner_tr EQU $08
corner_br EQU $09
corner_bl EQU $0a
tee_u     EQU $0b
tee_r     EQU $0c
tee_d     EQU $0d
tee_l     EQU $0e
sq_1      EQU $0f
sq_2      EQU $10
sq_3      EQU $11

disp_y    EQU $50
disp_x    EQU $2c

SECTION "vblank",HOME[$40]
	jp vblank

SECTION "timer",HOME[$50]
	jp next_table

SECTION "boot",HOME[$100]
	jp _start

SECTION "main", HOME[$150]
_start:
	xor a
	ldio [rNR52], a

	ld hl, active_slot
	ld [hl], $0

	ld hl, ramtable
	ld bc, firez
.copy_table:
	ld a, [bc]
	inc bc
	ld [hl+], a
	or a
	jr nz, .copy_table

	xor a
	ldio [rLCDC], a

	ld hl, symbols
	ld bc, tiles
	ld de, size_symbols + size_font
	call copy

	ld hl, header
	ld bc, tilemap
	ld de, end_header - header
	call copy

	ld hl, tilemap+end_header - header
	ld bc, $03C0
	call zero

	ld hl, oam_dma_rom
	ld bc, oam_dma
	ld de, end_oam_dma_rom - oam_dma_rom
	call copy

	ld hl, oam
	ld bc, $a0
	call zero

	ld hl, header_oam
	ld bc, oam
	ld de, end_header_oam - header_oam
	call copy
	call oam_dma

	ld a, $c4
	ldio [rBGP], a
	ld a, $d4
	ldio [rOBP0], a
	ld a, $d0
	ldio [rOBP1], a
	ld a, $04
	ldio [rSCX], a
	ld a, $93
	ldio [rLCDC], a
	ld a, $01
	ldio [rIE], a
	ld a, $10
	ldio [rSTAT], a

	ei
runloop:
	halt
	nop
	ld a, [down_buttons]
	bit 0, a
	call nz, play_ramtable
	jr runloop

copy:
	ld a, [hl+]
	ld [bc], a
	inc bc
	dec de
	ld a, d
	or a, e
	jr nz, copy
	ret

zero:
	xor a
	ld [hl+], a
	dec bc
	ld a, b
	or a, c
	jr nz, zero
	ret

play_ramtable:
	push hl
	ld hl, ramtable
	call play_table
	pop hl
	ret

wait_sec:
	ld b, a
.wait0:
	ld c, $3C
.wait1:
	ldio a, [rSTAT]
	and a, $3
	cp a, $1
	jr z, .wait2
	halt
.wait2:
	ldio a, [rSTAT]
	and a, $3
	cp a, $1
	jr z, .wait2
	dec c
	jr nz, .wait1
	dec b
	jr nz, .wait0
	ret

play_table:
	ld a, $80
	ldio [rNR52], a
	ld a, $ff
	ldio [rNR50], a
	ld a, $44
	ldio [rNR51], a
	ld a, $20
	ldio [rNR32], a

	ld a, $fc
	ldio [rWave_0], a
	ldio [rWave_4], a
	ldio [rWave_8], a
	ldio [rWave_c], a
	ld a, $84
	ldio [rWave_1], a
	ldio [rWave_5], a
	ldio [rWave_9], a
	ldio [rWave_d], a
	ld a, $04
	ldio [rWave_2], a
	ldio [rWave_6], a
	ldio [rWave_e], a
	ldio [rWave_a], a
	ld a, $8c
	ldio [rWave_3], a
	ldio [rWave_7], a
	ldio [rWave_b], a
	ldio [rWave_f], a

	di
	ld a, $80
	ldio [rNR30], a
	xor a
	ldio [rTIMA], a
	ld a, $52
	ldio [rTMA], a

	ld a, $04
	ldio [rTAC], a
	ldio [rIE], a
	ei
.play_loop:
	halt
	nop
	ldio a, [rNR30]
	and a, $80
	or a
	jr nz, .play_loop
	xor a
	ldio [rNR52], a
	ldio [rTAC], a
	ld a, $01
	ldio [rIE], a
	ret

next_table:
	ld a, [hl+]
	or a
	jr z, .end_table
	ldio [rNR33], a
	ld a, $a0
	ldio [rTMA], a
	xor a
	ldio [rNR30], a
	nop
	nop
	nop
	ld a, $80
	ldio [rNR30], a
	ld a, $87
	ldio [rNR34], a
	reti

.end_table:
	dec hl
	xor a
	ldio [rNR30], a
	reti

vblank:
	push hl
	push bc
	push de
	call read_buttons
	ld b, a
	ld a, [down_buttons]
	and a, b
	ld a, b
	ld [down_buttons], a
	jp nz, .reti
	bit 4, b
	call nz, cursor_right
	bit 5, b
	call nz, cursor_left
	bit 6, b
	call nz, cursor_increase
	bit 7, b
	call nz, cursor_decrease

	ld bc, ramtable
	ld a, [bc]
	inc bc
	add sp, -$2
	ld hl, sp 0
	call write_hex
	pop de
	ld hl, oam + end_header_oam - header_oam

	ld [hl], disp_y + $10
	inc hl
	ld [hl], disp_x
	inc hl
	ld a, e
	ld [hl+], a
	ld [hl], 0
	inc hl

	ld [hl], disp_y + $10
	inc hl
	ld [hl], disp_x + 8
	inc hl
	ld a, d
	ld [hl+], a
	ld [hl], 0
	inc hl

	ld a, [active_slot]
	add a, a
	add a, a
	add a, a
	ld d, a
	add a, a
	add a, d
	add a, disp_x + $1c

	ld [hl], disp_y + $18
	inc hl
	ld [hl], a
	inc hl
	ld [hl], arrow_d
	inc hl
	ld [hl], 0
	inc hl

	ld [hl], disp_y + $8
	inc hl
	ld [hl], a
	inc hl
	ld [hl], arrow_u
	inc hl
	ld [hl], 0
	inc hl

	call oam_dma

	ld hl, table_text
	ld a, [bc]
	inc bc
	call write_hex
	xor a
	ld [hl+], a
	ld a, [bc]
	inc bc
	call write_hex
	xor a
	ld [hl+], a
	ld a, [bc]
	inc bc
	call write_hex
	ld hl, table_text
	ld bc, tilemap + disp_y * 4 + disp_x / 8 + 3
	ld de, $8
	call copy

.reti:
	pop de
	pop bc
	pop hl
	reti

write_hex:
	push bc
	ld b, a
	swap a
	and a, $f
	or a, $30
	cp a, $3a
	jr c, .a
	add a, $7
.a:
	ld [hl+], a
	ld a, b
	and a, $f
	or a, $30
	cp a, $3a
	jr c, .b
	add a, $7
.b:
	ld [hl+], a
	pop bc
	ret

read_buttons:
	ld a, $20
	ldio [rJOYP], a
	ldio a, [rJOYP]
	ldio a, [rJOYP]
	ldio a, [rJOYP]
	ldio a, [rJOYP]
	cpl
	and a, $f
	swap a
	ld b, a
	ld a, $10
	ldio [rJOYP], a
	ldio a, [rJOYP]
	ldio a, [rJOYP]
	ldio a, [rJOYP]
	ldio a, [rJOYP]
	cpl
	and a, $f
	or a, b
	ret

cursor_left:
	ld a, [active_slot]
	and a
	ret z
	dec a
	ld [active_slot], a
	ret

cursor_right:
	ld a, [active_slot]
	cp a, $2
	ret z
	inc a
	ld [active_slot], a
	ret

cursor_increase:
	push hl
	push bc
	ld hl, ramtable+1
	ld a, [active_slot]
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	inc a
	ld [hl], a
	pop bc
	pop hl
	ret

cursor_decrease:
	push hl
	push bc
	ld hl, ramtable+1
	ld a, [active_slot]
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	dec a
	ld [hl], a
	pop bc
	pop hl
	ret

table:
	dw waterium
	db $10
	dw firez
	db $0d
	dw 0
	db $10
	dw 0

firez:
	db $c6, $ca, $d0, $ce, 0

waterium:
	db $c6, $ce, $d0, $c9, 0

psychium:
	db $c6, $ce, $d1, $cb, 0

header:
REPT ($14 - strlen("{name}")) / 2
	db sq_1
ENDR

	db corner_tl
REPT strlen("{name}")
	db line_h
ENDR
	db corner_tr
REPT $1e - strlen("{name}")
	db sq_1
ENDR

	db line_v, "{name}", line_v
REPT ($12 - strlen("{name}")) / 2 + $c
	db sq_1
ENDR

REPT ($13 - strlen("{name}")) / 2
	db line_h
ENDR
	db tee_u
REPT strlen("{name}")
	db line_h
ENDR
	db tee_u
REPT ($13 - strlen("{name}")) / 2
	db line_h
ENDR
end_header:

header_oam:
	db $20, $4 + ($13 - strlen("{name}")) * 4
	db tee_u, $0

	db $20, $c + ($13 + strlen("{name}")) * 4
	db tee_u, $0

	db $18, $c + ($13 + strlen("{name}")) * 4
	db line_v, $10

	db $18, $c + ($13 + strlen("{name}")) * 4
	db line_v, $10
end_header_oam:

oam_dma_rom:
	ld a, oam / $100
	ld [rDMA], a
	ld a, $28
.loop
	dec a
	jr nz, .loop
	ret
end_oam_dma_rom

SECTION "ram",BSS
oam:
	ds $a0
ramtable:
	ds 5
active_slot:
	ds 1
down_buttons:
	ds 1
table_text:
	ds 8

SECTION "tilerom",HOME
symbols:
INCBIN "symbols.bin"
font:
INCBIN "font.bin"

SECTION "tiles",VRAM[$8000]
tiles:
	ds size_symbols
	ds size_font

SECTION "oam_dma",HRAM
oam_dma:
	ds end_oam_dma_rom - oam_dma_rom
