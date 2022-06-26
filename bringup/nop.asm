; fill the ROM with NOPs
	.base	0xE000
	.org	0xE000
start:
	.fill	0x2000-8,0xEA

	.org	0xFFF8
	.byte	0xEA
	.byte	0x4C	; jmp abs

	.org	0xFFFA
nmi:
	.word	start
reset:
	.word	start
irq:
	.word	start
