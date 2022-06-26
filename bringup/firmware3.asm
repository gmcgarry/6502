; loops that jump down memory
; lighting up the address bus
; RAMless

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
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+16
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+32
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+64
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+128
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+256
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+512
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+1024
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+2048
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	2f

	.org	ROMSTART+4096
2:
	ldx	#$00
1:
	dex
	bne	1b
	jmp	start

	.org	VTABLE
nmi:
	.word	start
reset:
	.word	start
irq:
	.word	start
