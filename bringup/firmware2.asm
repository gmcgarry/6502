; firmware for breadboard computer

; memory map
; 0xE000: ROM start address
; 0xfffc: start address low byte
; 0xfffd: start address high byte
; 0xffff: ROM end address

	.equ	ROMSTART,	0xE000
	.equ	VTABLE,		0xFFFA

	.base	ROMSTART

	.org	ROMSTART
start:
	sei			; disable interrupt
	cld			; disable bcd
	ldx	#$FF
	txs

	jsr	loop
	jmp	.

loop:
	ldx	#$FF
1:
	lda	#$AA
	dex
	bne	1b
	nop

	ldx	#$FF
2:
	lda	#$55
	dex
	bne	2b

	jmp	loop

	.org	VTABLE
nmi:
	.word	start
reset:
	.word	start
irq:
	.word	start
