; SOROM4M(MMC1A) Nin1 loader

; PPU
PPUCTRL = $2000
PPUMASK = $2001
PPUADDR = $2006
PPUDATA = $2007

; copy CHR
SRC  = $01
SRCH = $02

	.bank 0
	.bank 1
	.bank 2
	.org $C100	; last bank $C000 + NES headers:16bytes x 16
reset_handler:
	sei
	cld
	ldx #$FF	; stack
	txs
	stx $9FFF	; reset the mapper
	lda #$00
	sta PPUCTRL	; stop PPU
	sta PPUMASK	; turn off rendering

_init_mmc:
	lda #$0F	; CHR 8KB(0b), PRG switch $8000/fix $C000(11b), Mirroring H(11b)
	sta $9FFF
	lsr A
	sta $9FFF
	lsr A
	sta $9FFF
	lsr A
	sta $9FFF
	lsr A
	sta $9FFF

	lda #$00	; PRG 1st(0b), W-RAM(00b), x(0b), CHR bank 0(0b)
	sta $BFFF
	sta $BFFF
	sta $BFFF
	sta $BFFF
	sta $BFFF

_joypad:
	lda #1		; read pad
	sta $4016
	lda #0
	sta $4016
	sta <0		; clear work: PRG 32K bank
	sta <1		; clear work: CHR 16K bank
	sta <2		; clear work: CHR 8K top/bottom
	sta <3		; clear work: V:2, H:3, 2nd SOROM:0
	lda $4016	; 0:A skip
	lda $4016	; 1:B skip
_select:
	lda $4016	; 2:Select
	and #1
	beq _start
	lda #3		; H
	sta <3
_start:
	lda $4016	; 3:Start
	and #1
	beq _up
	lda #1
	sta <0
	sta <2
	lda #2		; V
	sta <3
_up:
	lda $4016	; 4:Up
	and #1
	beq _down
	lda #2
	sta <0
	lsr A
	sta <1
	lsr A
	sta <2
	lda #3		; H
	sta <3
_down:
	lda $4016	; 5:Down
	and #1
	beq _left
	lda #3
	sta <0
	lsr A
	sta <1
	sta <2
	lda #3		; H
	sta <3
_left:
	lda $4016	; 6:Left
	and #1
	beq _right
	lda #4
	sta <0
	lsr A
	sta <1
	lda #0
	sta <2
	lda #2		; V
	sta <3
_right:
	lda $4016	; 7:Right
	and #1
	beq _is_2nd
	lda #5
	sta <0
	lsr A
	sta <1
	lsr A
	sta <2
	lda #2		; V
	sta <3
_is_2nd:
	lda <3		; V:2, H:3, 2nd:0
	beq copy_2nd_loader_to_ram0

_copy_chr_rom:
	lda #$0C	; src CHR ROM 0(01100b) @ PRG:16KBx2x6 + CHR:8KBx2x3
	clc
	adc <1		; CHR 16K bank
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0

	lda #$00	; src = $8000 or $A000
	sta <SRC
	lda <2		; CHR 8K top/bottom
	beq _b
	lda #$20
_b:
	clc
	adc #$80
	sta <SRCH

	ldy #0
	sty PPUADDR	; dst CHR RAM addr
	sty PPUADDR
	ldx #32		; number of 256-byte pages to copy (= 256*32 = 8KB)
loop:
	lda [SRC],y	; copy one page
	sta PPUDATA
	iny
	bne loop
	inc <SRCH	; next page
	dex
	bne loop

copy_2nd_loader_to_ram0:
	ldx #4
loop1:
	lda loader2nd,x
	sta <0,x
	inx
	bne loop1
	jmp 4		; goto the 2nd loader


	.org $C300
loader2nd:
	nop
	nop
	nop
	nop
_prg_rom:
	lda <3		; CHR 8KB(0b), PRG switch 32KB(00b), Mirroring V(10b),H(11b)
	beq _2nd_SOROM
	sta $9FFF
	lsr A
	sta $9FFF
	lsr A
	sta $9FFF
	lsr A
	sta $9FFF
	lsr A
	sta $9FFF

	lda #$00	; PRG 1st(0b), W-RAM(00b), x(0b), CHR bank 0(0b)
	sta $BFFF
	sta $BFFF
	sta $BFFF
	sta $BFFF
	sta $BFFF

	lda <0		; PRG ROM n(0PPP0b) @ PRG:16KBx2x6 + CHR:8KBx6
	asl A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	clc
	bcc _go

_2nd_SOROM:
	lda #$02	; PRG 2st(1b), W-RAM(00b), x(0b), CHR bank 0(0b)
	sta $BFFF
	sta $BFFF
	sta $BFFF
	sta $BFFF
	lsr A
	sta $BFFF

_go
	jmp [$FFFC]


nmi_handler:
	rti
irq_handler:
	rti

	.bank 3
	.org $FFFA
	.dw nmi_handler
	.dw reset_handler
	.dw irq_handler
