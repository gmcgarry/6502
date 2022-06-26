; writes and dumps ZP to ACIA
; RAMless 

; CLOCK = 1843200Hz
;	/16 = 115200 bps

ACIA	EQU	$D800
ACIACS	EQU	ACIA+0
ACIADA	EQU	ACIA+1

ROM	EQU	$E000

	.base	ROM
	.org	ROM
START:
	LDA    #$03    ; RESET CODE
	STA    ACIACS
	NOP
	NOP
	NOP
	LDA    #$15    ; 0,00,101,01: no rx irq, RTS=low no tx irq, /16, N81 NON-INTERRUPT
	STA    ACIACS

	LDY	#$00
	LDX	#$00
LOOP1:
	STY	$0000,X
	INX
	BNE	LOOP1

LOOP2:

1:	; wait for tx empty
	LDA	ACIACS
	LSR    
	LSR    
	BCC     1b
	LDA	$0000,X

1:
	LSR		; OUT HEX LEFT BCD DIGIT
	LSR
	LSR
	LSR
	AND	#$0F	; OUT HEX RIGHT BCD DIGIT
	ADD	#$30
	CMP	#$3A
	BCC	1f
	ADD	#$7
1:
	STA	ACIADA

1:	; wait for tx empty
	LDA	ACIACS
	LSR    
	LSR    
	BCC     1b
	LDA	$000,X

1:
	AND	#$0F     ; OUT HEX RIGHT BCD DIGIT
	ADD	#$30
	CMP	#$3A
	BCC	1f
	ADD	#$7
1:
	STA	ACIADA

1:	; wait for tx empty
	LDA	ACIACS
	LSR    
	LSR    
	BCC     1b

	LDA	#'\r'
	STA	ACIADA

1:	; wait for tx empty
	LDA	ACIACS
	LSR    
	LSR    
	BCC     1b

	LDA	#'\n'
	STA	ACIADA

	INX
	BNE	LOOP2

	INY
	JMP	LOOP1

	.org    $FFFA
nmi:
	.word   START
reset:
	.word   START
irq:
	.word   START

	.end
