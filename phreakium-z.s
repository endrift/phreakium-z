rJOYP       EQU $ff00
rTIMA       EQU $ff05
rTMA        EQU $ff06
rTAC        EQU $ff07
rNR21       EQU $ff16
rNR22       EQU $ff17
rNR23       EQU $ff18
rNR24       EQU $ff19
rNR50       EQU $ff24
rNR51       EQU $ff25
rNR52       EQU $ff26
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

disp_y    EQU $60
disp_x    EQU $24

preset_y  EQU $30

zpower_duration  EQU $0d

fixstr: MACRO
	db \1
REPT \2 - strlen(\1)
	db 0
ENDR
ENDM

F  EQUS " + $e5"
K  EQU  $e3

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
	ld [active_slot], a
	ld [active_preset], a
	ld [mode], a

	ld hl, patterns
	ld bc, ramtable
	ld de, 8
	call copy
	ld hl, ramtable
	ld [hl], K

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
	push hl
	push bc
	push de
.loop
	ld a, [hl+]
	ld [bc], a
	inc bc
	dec de
	ld a, d
	or a, e
	jr nz, .loop
	pop de
	pop bc
	pop hl
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
	ldio [rNR21], a
	ld a, $ff
	ldio [rNR50], a
	ld a, $22
	ldio [rNR51], a
	ld a, $f0
	ldio [rNR22], a

	di
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
	ldio a, [rNR51]
	and a, $22
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
	ldio [rNR23], a
	ld a, $a0
	ldio [rTMA], a
	ldio a, [rNR51]
	and a, $dd
	ldio [rNR51], a
	nop
	or a, $22
	ldio [rNR51], a
	ld a, $87
	ldio [rNR24], a
	reti

.end_table:
	dec hl
	ldio a, [rNR51]
	and a, $dd
	ldio [rNR51], a
	reti

vblank:
	push af
	push bc
	push de
	push hl
	call read_buttons
	ld b, a
	ld a, [down_buttons]
	and a, b
	ld a, b
	ld [down_buttons], a
	jr nz, .reti
	bit 2, b
	call nz, switch_mode
	ld a, [mode]
	or a
	jr nz, .call_custom_mode
	call preset_mode
	jr .copy_ram
.call_custom_mode
	call custom_mode
.copy_ram
	ld bc, ramtable
	ld hl, table_text
	ld a, [bc]
	inc bc
	ld a, $21
	ld [hl+], a
REPT 6
	ld a, [bc]
	inc bc
	or a
	jr z, .none_\@
	sub a, $b5
	jr .write_\@
.none_\@:
	ld a, $2d
.write_\@:
	ld [hl+], a
ENDR
	ld hl, table_text
	ld bc, tilemap + disp_y * 4 + disp_x / 8 + 3
	ld de, $7
	call copy
.reti:
	pop hl
	pop de
	pop bc
	pop af
	reti

preset_mode:
	push hl
	push bc
	bit 4, b
	call nz, preset_cursor_right
	bit 5, b
	call nz, preset_cursor_left

	ld a, [active_preset]
	call set_preset_name

	ld hl, oam + end_header_oam - header_oam

	ld [hl], preset_y + $10
	inc hl
	ld [hl], $7c
	inc hl
	ld [hl], arrow_l
	inc hl
	ld [hl], 0
	inc hl

	ld [hl], preset_y + $10
	inc hl
	ld [hl], $8c
	inc hl
	ld [hl], arrow_r
	inc hl
	ld [hl], 0
	inc hl

	call oam_dma

	pop bc
	pop hl
	ret

custom_mode:
	push hl
	push bc
	bit 4, b
	call nz, custom_cursor_right
	bit 5, b
	call nz, custom_cursor_left
	bit 6, b
	call nz, custom_cursor_increase
	bit 7, b
	call nz, custom_cursor_decrease

	ld hl, oam + end_header_oam - header_oam

	ld a, [active_slot]
	add a, a
	add a, a
	add a, a
	add a, disp_x + $20

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

	pop bc
	pop hl
	ret

switch_mode:
	ld a, [mode]
	xor a, $1
	ld [mode], a
	jr z, .load_preset_name
	ld a, $40
	jp set_preset_name
.load_preset_name
	jp load_preset

set_preset_name:
	push hl
	push bc
	ld h, 0
	ld l, a
	add hl, hl
	add hl, hl
	push hl
	add hl, hl
	add hl, hl
	add hl, hl
	pop bc
	add hl, bc
	ld bc, table

	add hl, bc
	ld bc, tilemap + (preset_y - 8) * $4 + 1
	ld de, $12
	call copy

	add hl, de
	ld bc, tilemap + preset_y * $4 + 1
	ld de, $11
	call copy

	pop bc
	pop hl
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

custom_cursor_left:
	ld a, [active_slot]
	and a
	ret z
	dec a
	ld [active_slot], a
	ret

custom_cursor_right:
	ld a, [active_slot]
	cp a, $5
	ret z
	inc a
	ld [active_slot], a
	ret

custom_cursor_increase:
	push hl
	push bc
	ld hl, ramtable+1
	ld a, [active_slot]
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	cp a, 3F
	jr z, .ret
	or a
	jr z, .set
	inc a
	ld [hl], a
.ret
	pop bc
	pop hl
	ret
.set
	ld [hl], 0F
	jr .ret

custom_cursor_decrease:
	push hl
	push bc
	ld hl, ramtable+1
	ld a, [active_slot]
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	cp a, 0F
	jr z, .clear
	or a
	jr z, .ret
	dec a
	ld [hl], a
.ret
	pop bc
	pop hl
	ret
.clear
	ld [hl], 0
	jr .ret

preset_cursor_right:
	ld a, [active_preset]
	inc a
	and a, $3f
	ld [active_preset], a
	jp load_preset

preset_cursor_left:
	ld a, [active_preset]
	dec a
	and a, $3f
	ld [active_preset], a
	jp load_preset

load_preset:
	push hl
	push bc
	push de
	ld a, [active_preset]
	ld l, a
	call set_preset_name
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	ld bc, patterns
	add hl, bc
	ld bc, ramtable
	ld de, $8
	call copy
	pop de
	pop bc
	pop hl
	ret

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
	ds 8
active_slot:
	ds 1
down_buttons:
	ds 1
table_text:
	ds 8
mode:
	ds 1
active_preset:
	ds 1

SECTION "tilerom",HOME
symbols:
INCBIN "symbols.bin"
font:
INCBIN "font.bin"

zpower: MACRO
	fixstr \1, $12
	fixstr "(Surrounded)", $11
	db zpower_duration
ENDM
zmove: MACRO
	fixstr \1, $12
	fixstr "(Z-Move)", $11
	db \2
ENDM
zunkn: MACRO
	fixstr \1, $12
	fixstr "(Unknown)", $11
	db \2
ENDM

SECTION "move_table",HOME
table:
	zpower "Normalium-Z"
	zpower "Firium-Z"
	zpower "Waterium-Z"
	zpower "Grassium-Z"
	zpower "Electrium-Z"
	zpower "Icium-Z"
	zpower "Fightium-Z"
	zpower "Poisonium-Z"
	zpower "Groundium-Z"
	zpower "Flyium-Z"
	zpower "Psycium-Z"
	zpower "Buginium-Z"
	zpower "Rockium-Z"
	zpower "Ghostium-Z"
	zpower "Dragonium-Z"
	zpower "Darkium-Z"
	zpower "Steelium-Z"
	zpower "Fairium-Z"
	zmove "Normalium-Z", $00
	zmove "Firium-Z", $00
	zmove "Waterium-Z", $00
	zmove "Grassium-Z", $00
	zmove "Electrium-Z", $00
	zmove "Icium-Z", $00
	zmove "Fightium-Z", $00
	zmove "Poisonium-Z", $00
	zmove "Groundium-Z", $00
	zmove "Flyium-Z", $00
	zmove "Psycium-Z", $00
	zmove "Bugium-Z", $00
	zmove "Rockium-Z", $00
	zmove "Ghostium-Z", $00
	zmove "Dragonium-Z", $00
	zmove "Darkium-Z", $00
	zmove "Steelium-Z", $00
	zmove "Fairium-Z", $00
	zmove "Decidium-Z", $00
	zmove "Incinium-Z", $00
	zmove "Primarium-Z", $00
	zmove "Pikachunium-Z", $00
	zmove "Tapunium-Z", $00
	zmove "Aloraichium-Z", $00
	zmove "Snorlium-Z", $00
	zmove "Eevium-Z", $00
	zmove "Mewium-Z", $00
	zmove "Marshadium-Z", $00
	zunkn "2-1-0-1-2-1", $00
	zunkn "0-1-0-1-2-1", $00
	zmove "Pikashunium-Z", $00
	zunkn "0-3-2-3-0-1", $00
	zunkn "2-1-2-3-0-1", $00
	zunkn "0-1-2-3-0-1", $00
	zunkn "2-3-0-3-0-1", $00
	zunkn "0-3-0-3-0-1", $00
	zunkn "2-1-0-3-0-1", $00
	zunkn "0-1-0-3-0-1", $00
	zunkn "2-3-2-1-0-1", $00
	zunkn "Pikachu 1", $00
	zunkn "Pikachu 2", $00
	zunkn "Pikachu 3", $00
	zunkn "Pikachu 4", $00
	zunkn "Pikachu 5", $00
	zunkn "2-1-0-1-0-1", $00
	zunkn "0-1-0-1-0-1", $00
no_preset:
	fixstr "Custom", $12
	fixstr "(No Preset)", $11
	db $10

patterns:
	db K, 2F, 3F, 2F, 3F, 2F, 3F, 0
	db K, 0F, 3F, 2F, 3F, 2F, 3F, 0
	db K, 2F, 1F, 2F, 3F, 2F, 3F, 0
	db K, 0F, 1F, 2F, 3F, 2F, 3F, 0
	db K, 2F, 3F, 0F, 3F, 2F, 3F, 0
	db K, 0F, 3F, 0F, 3F, 2F, 3F, 0
	db K, 2F, 1F, 0F, 3F, 2F, 3F, 0
	db K, 0F, 1F, 0F, 3F, 2F, 3F, 0
	db K, 2F, 3F, 2F, 1F, 2F, 3F, 0
	db K, 0F, 3F, 2F, 1F, 2F, 3F, 0
	db K, 2F, 1F, 2F, 1F, 2F, 3F, 0
	db K, 0F, 1F, 2F, 1F, 2F, 3F, 0
	db K, 2F, 3F, 0F, 1F, 2F, 3F, 0
	db K, 0F, 3F, 0F, 1F, 2F, 3F, 0
	db K, 2F, 1F, 0F, 1F, 2F, 3F, 0
	db K, 0F, 1F, 0F, 1F, 2F, 3F, 0
	db K, 2F, 3F, 2F, 3F, 0F, 3F, 0
	db K, 0F, 3F, 2F, 3F, 0F, 3F, 0
	db K, 2F, 1F, 2F, 3F, 0F, 3F, 0
	db K, 0F, 1F, 2F, 3F, 0F, 3F, 0
	db K, 2F, 3F, 0F, 3F, 0F, 3F, 0
	db K, 0F, 3F, 0F, 3F, 0F, 3F, 0
	db K, 2F, 1F, 0F, 3F, 0F, 3F, 0
	db K, 0F, 1F, 0F, 3F, 0F, 3F, 0
	db K, 2F, 3F, 2F, 1F, 0F, 3F, 0
	db K, 0F, 3F, 2F, 1F, 0F, 3F, 0
	db K, 2F, 1F, 2F, 1F, 0F, 3F, 0
	db K, 0F, 1F, 2F, 1F, 0F, 3F, 0
	db K, 2F, 3F, 0F, 1F, 0F, 3F, 0
	db K, 0F, 3F, 0F, 1F, 0F, 3F, 0
	db K, 2F, 1F, 0F, 1F, 0F, 3F, 0
	db K, 0F, 1F, 0F, 1F, 0F, 3F, 0
	db K, 2F, 3F, 2F, 3F, 2F, 1F, 0
	db K, 0F, 3F, 2F, 3F, 2F, 1F, 0
	db K, 2F, 1F, 2F, 3F, 2F, 1F, 0
	db K, 0F, 1F, 2F, 3F, 2F, 1F, 0
	db K, 2F, 3F, 0F, 3F, 2F, 1F, 0
	db K, 0F, 3F, 0F, 3F, 2F, 1F, 0
	db K, 2F, 1F, 0F, 3F, 2F, 1F, 0
	db K, 0F, 1F, 0F, 3F, 2F, 1F, 0
	db K, 2F, 3F, 2F, 1F, 2F, 1F, 0
	db K, 0F, 3F, 2F, 1F, 2F, 1F, 0
	db K, 2F, 1F, 2F, 1F, 2F, 1F, 0
	db K, 0F, 1F, 2F, 1F, 2F, 1F, 0
	db K, 2F, 3F, 0F, 1F, 2F, 1F, 0
	db K, 0F, 3F, 0F, 1F, 2F, 1F, 0
	db K, 2F, 1F, 0F, 1F, 2F, 1F, 0
	db K, 0F, 1F, 0F, 1F, 2F, 1F, 0
	db K, 2F, 3F, 2F, 3F, 0F, 1F, 0
	db K, 0F, 3F, 2F, 3F, 0F, 1F, 0
	db K, 2F, 1F, 2F, 3F, 0F, 1F, 0
	db K, 0F, 1F, 2F, 3F, 0F, 1F, 0
	db K, 2F, 3F, 0F, 3F, 0F, 1F, 0
	db K, 0F, 3F, 0F, 3F, 0F, 1F, 0
	db K, 2F, 1F, 0F, 3F, 0F, 1F, 0
	db K, 0F, 1F, 0F, 3F, 0F, 1F, 0
	db K, 2F, 3F, 2F, 1F, 0F, 1F, 0
	db K, 0F, 3F, 2F, 1F, 0F, 1F, 0
	db K, 2F, 1F, 2F, 1F, 0F, 1F, 0
	db K, 0F, 1F, 2F, 1F, 0F, 1F, 0
	db K, 2F, 3F, 0F, 1F, 0F, 1F, 0
	db K, 0F, 3F, 0F, 1F, 0F, 1F, 0
	db K, 2F, 1F, 0F, 1F, 0F, 1F, 0
	db K, 0F, 1F, 0F, 1F, 0F, 1F, 0

SECTION "tiles",VRAM[$8000]
tiles:
	ds size_symbols
	ds size_font

SECTION "oam_dma",HRAM
oam_dma:
	ds end_oam_dma_rom - oam_dma_rom
