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
rIE         EQU $ffff

SECTION "vblank",HOME[$40]
	jp vblank

SECTION "timer",HOME[$50]
	jp next_table

SECTION "boot",HOME[$100]
	jp _start

SECTION "main", HOME[$150]
_start:
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

	ld a, $80
	ldio [rLCDC], a
	ld a, $01
	ldio [rIE], a
	ld a, $10
	ldio [rSTAT], a

	ld hl, active_slot
	ld [hl], $0

	ld hl, ramtable
	ld bc, firez
copy_table:
	ld a, [bc]
	inc bc
	ld [hl+], a
	or a
	jr nz, copy_table

	ei
runloop:
	halt
	nop
	ld a, [down_buttons]
	bit 0, a
	call nz, play_ramtable
	jr runloop

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
	call read_buttons
	ld b, a
	ld a, [down_buttons]
	and a, b
	ld a, b
	ld [down_buttons], a
	jr nz, .reti
	bit 4, b
	call nz, cursor_right
	bit 5, b
	call nz, cursor_left
	bit 6, b
	call nz, cursor_increase
	bit 7, b
	call nz, cursor_decrease
.reti:
	reti

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
	db $c6
	db $ca
	db $d0
	db $ce
	db 0

waterium:
	db $c6
	db $ce
	db $d0
	db $c9
	db 0

SECTION "ram",BSS
ramtable:
	ds 5
active_slot:
	ds 1
down_buttons:
	ds 1

