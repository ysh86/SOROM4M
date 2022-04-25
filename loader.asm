; SOROM4M(MMC1A) Nin1 loader

; PPU
PPUCTRL = $2000
PPUMASK = $2001
PPUADDR = $2006
PPUDATA = $2007

; copy CHR
SRC  = $00
SRCH = $01

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

_init_mmc_ppu:
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
	sta PPUCTRL	; stop PPU

_copy_chr_rom:
	;lda #$0C	; src CHR ROM 0(01100b) @ PRG:16KBx2x6 + CHR:8KBx6
	lda #$0D	; src CHR ROM 2(01101b) @ PRG:16KBx2x6 + CHR:8KBx6
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0

	lda #$00	; src = $8000
	sta <SRC
	lda #$80
	sta <SRCH

	ldy #0
	sty PPUMASK	; turn off rendering
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

_copy_2nd_loader_to_ram0:
	ldx #0
loop1:
	lda loader2nd,x
	sta <0,x
	inx
	bne loop1
	jmp 0		; goto the 2nd loader


	.org $C200
loader2nd:
_prg_rom:
	;lda #$02	; CHR 8KB(0b), PRG switch 32KB(00b), Mirroring V(10b)
	lda #$03	; CHR 8KB(0b), PRG switch 32KB(00b), Mirroring H(11b)
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

	;lda #$00	; PRG ROM 0(00000b) @ PRG:16KBx2x6 + CHR:8KBx6
	lda #$04	; PRG ROM 2(00100b) @ PRG:16KBx2x6 + CHR:8KBx6
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
	lsr A
	sta $FFF0
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
