;
; Calculate CPU clock using MSM4262B clock
;

REGS	EQU	$D000
CD	EQU	REGS+13	; 30-sec adjust, IRQ, BUSY, HOLD
CE	EQU	REGS+14	; t1, t0, ITRPT/STND, MASK
CF	EQU	REGS+15	; TEST, 24/12, STOP, REST

MONITR	EQU	$FFC0
PUTC	EQU	$FFC6
PUTS	EQU	$FFC9

	ORG	$0080	; MONITOR currently stomps on $0000
BIGNUM	.dword	4
OSTEMP	.byte	1

XHI	EQU	BIGNUM
XLO	EQU	BIGNUM+1

	ORG	$0200
start:
	CLD		; binary mode
	LDX	#$FF
	TXS
main:
	JSR	PUTS
	.asciz	"\r\n"
	JSR	PUTS
	.asciz	"Speed Checker\r\n"

	SEI		; disable interrupts

	LDA	#$00
	STA	CE	; TIMER=1/64 (33% duty cycle), ITRPT/STD=0 (wave output), MASK=0
	STA	CD	; ADJ=0, IRQ=xxx, BUSY=xxx, HOLD=0

	STA	BIGNUM
	STA	BIGNUM+1
	STA	BIGNUM+2
	STA	BIGNUM+3

	LDA	#$04
1:			; wait for wave to go high
	BIT	CD	; 4T
	BEQ	1b	; 2T/3T
1:			; wait for wave to go low
	BIT	CD	; 4T
	BNE	1b	; 2T/3T

	; timing loop 1
1:
	LDA	0	; 3T nop
	NOP		; 2T
	SEC		; 2T
	LDA	#$00	; 2T
	ADC	XLO	; 3T
	STA	XLO	; 3T
	LDA	#$00	; 2T
	ADC	XHI	; 3T
	STA	XHI	; 3T
	LDA	CD	; 4T
	AND	#$04	; 2T
	BEQ	1b	; 2T/3T wait for wave to go high

	; timing loop 2
1:
	LDA	0	; 3T nop
	NOP		; 2T
	SEC		; 2T
	LDA	#$00	; 2T
	ADC	XLO	; 3T
	STA	XLO	; 3T
	LDA	#$00	; 2T
	ADC	XHI	; 3T
	STA	XHI	; 3T
	LDA	CD	; 4T
	AND	#$04	; 2T
	BNE	1b	; 2T/3T wait for wave to go low

	; at this point, X is the number of times round the loop

	; MHz = X * 64 * 32
	; shift is 11 bits left
	; which is 5 bits right

	LDX	#5
	CLC
1:
	LSR	BIGNUM
	ROR	BIGNUM+1
	ROR	BIGNUM+2
	ROR	BIGNUM+3
	DEX
	BNE	1b

	JSR	PUTS
	.asciz	"CPU Speed is "

	LDX	#BIGNUM
	JSR	PRINTDEC

	JSR	PUTS
	.asciz	" Hz\r\n"

	LDA	#$01
	STA	CE	; mask interrupt
	LDA	#$00
	STA	CD	; clear interrupt

	CLI		; enable interrupts

	JMP	MONITR

; print 32-bit number at 0,X
PRINTDEC	ldy	#0	; Digit counter
PRDECDIGIT	lda	#32	; 32-bit divide
		sta	OSTEMP
		lda	#0	; Remainder=0
		clv		; V=0 means div result = 0
PRDECDIV10	cmp	#5	; Calculate OSNUM/10
		bcc	PRDEC10
		sbc	#$85	; Remove digit & set V=1 to show div result > 0
		sec		; Shift 1 into div result
PRDEC10		rol	3,x	; Shift /10 result into OSNUM
		rol	2,x
		rol	1,x
		rol	0,x
		rol	a	; Shift bits of input into acc (input mod 10)
		dec	OSTEMP
		bne	PRDECDIV10 ; Continue 32-bit divide
		ora	#48	; '0'+A
		pha		; Push low digit 0-9 to print
		iny
		bvs	PRDECDIGIT ; If V=1, result of /10 was > 0 & do next digit
PRDECLP2:
		pla		; Pop character left to right
		jsr	PUTC	; Print it
		dey
		bne	PRDECLP2
		rts

	END
