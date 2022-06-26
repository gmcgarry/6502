; dumps all memory over ACIA
; runs from ROM
; requires RAM at $100 for STACK

; CLOCK = 1843200Hz
;	/16 = 115200 bps

ACIA	EQU	$D800
ACIACS	EQU	ACIA+0
ACIADA	EQU	ACIA+1

ADDRLO	EQU	$30
ADDRHI	EQU	$31

	.base	$E000
	.org	$E000
START:
	JSR	INIT
	LDY	#$00
	STY	ADDRHI
	STY	ADDRLO
1:
	LDA	ADDRHI
	JSR	PUTHEX
	LDA	ADDRLO
	JSR	PUTHEX
	LDA	#':'
	JSR	PUTC
	LDA	#' '
	JSR	PUTC
	LDA	(ADDRLO),Y
	JSR	PUTHEX
	LDA	#'\r'
	JSR	PUTC
	LDA	#'\n'
	JSR	PUTC
	INC	ADDRLO
	BNE	2f
	INC	ADDRHI
2:
	JMP	1b

INIT:
	LDA	#$03	; RESET CODE
	STA	ACIACS
	NOP
	NOP
	NOP
	LDA	#$15	; 0,00,101,01: no rx irq, RTS=low no tx irq, /16, N81 NON-INTERRUPT
	STA	ACIACS
	RTS

PUTC:
	PHA
1:
	LDA	ACIACS
	LSR	
	LSR	
	BCC	 1b
	PLA	
	STA	ACIADA
	RTS

PUTHEX:
	PHA
	JSR	1f	; OUT LEFT HEX CHAR
	PLA
	JMP	2f	; OUTPUT RIGHT HEX CHAR AND R
1:
	LSR		; OUT HEX LEFT BCD DIGIT
	LSR
	LSR
	LSR
2:
	AND	#$F	 ; OUT HEX RIGHT BCD DIGIT
	ADD	#$30
	CMP	#$3A
	BCC	PUTC
	ADD	#$7
	JMP	PUTC

	.org	$FFFA
nmi:
	.word   START
reset:
	.word   START
irq:
	.word   START

	.end