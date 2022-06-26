; firmware for breadboard computer
; 8-bit address and data busses

; memory map
; 0xfc:	start address low byte
; 0xfd: start address high byte

	.org	0x00
start:
	ldx	#$FF
1:
	lda	#$AA
	dex
	bne	1b

	ldx	#$FF
2:
	lda	#$55
	dex
	bne	2b

	jmp	start

	.org	0xfa
nmi:
	.word	start
reset:
	.word	start
irq:
	.word	start
