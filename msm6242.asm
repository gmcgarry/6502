REGS	EQU	$D000
S1	EQU	REGS+0
S10	EQU	REGS+1
MI1	EQU	REGS+2
MI10	EQU	REGS+3
H1	EQU	REGS+4
H10	EQU	REGS+5
D1	EQU	REGS+6
D10	EQU	REGS+7
MO1	EQU	REGS+8
MO10	EQU	REGS+9
Y1	EQU	REGS+10
Y10	EQU	REGS+11
W	EQU	REGS+12
CD	EQU	REGS+13		; 30-sec adjust, IRQ, BUSY, HOLD
CE	EQU	REGS+14		; t1, t0, ITRPT/STND, MASK
CF	EQU	REGS+15		; TEST, 24/12, STOP, REST

; BOLD=1 inhibits the clock during read/write (much be set for less than 1 second)
; IRQ indicates the (inverted) level of the STD.P pin
; MASK=0 enables timing on STD.P; MASK=1 disables STD.P
; timing of STD.P is controlled by t0/t1 divisor: 00 = 1/64 second, 01=1second, 10=1minute, 11=1hour
; ITRPT/STND=1 (interrupt mode), then STD.P remains low until IRQ is reset to 0
; ITRPT/STND=0 (standard-pulse mode), then STD.P remains low until IRQ is reset to 0 (or the t0/t1 timer expires)

MONITR	EQU	$FFC0
GETC	EQU	$FFC3
PUTC	EQU	$FFC6
PUTS	EQU	$FFC9
PUTHEX	EQU	$FFCF

	.section dseg
	ORG $0000
XLO	.RS	1
XHI	.RS	1

	.section cseg
	ORG $0200
start:
	LDX	#$FF
	TXS
main:
	JSR	PUTS
	.asciz	"\r\n"
	JSR	PUTS
	.asciz	"MSM6242B tester\r\n"

	JSR	reset

loop:
	LDA	#'#'
	JSR	PUTC
	LDA	#' '
	JSR	PUTC
	JSR	GETC
	PHA
	JSR	PUTS
	.asciz	"\r\n"
	PLA
1:
	CMP	#'D'		; dump
	BNE	1f
	JSR	dump
	JMP	loop
1:
	CMP	#'R'		; reset
	BNE	1f
	JSR	reset
	JMP	loop
1:
	CMP	#'T'		; time
	BNE	1f
	JSR	time
	JMP	loop
1:
	CMP	#'I'		; interrupt
	BNE	1f
	JSR	interrupt
	JMP	loop
1:
	CMP	#'2'		; 24-hour time
	BNE	1f
	JSR	hour24
	JMP	loop
1:
	CMP	#'*'		; test mode
	BNE	1f
	JSR	testmode
	JMP	loop
1:
	CMP	#'X'		; exit
	BNE	1f
	JMP	MONITR
1:
	JSR	PUTS
	.asciz	"unrecognised command\r\n"
	JMP	loop

interrupt:
	SEI		; disable processor interrupts

	LDA	#isr&$FF	; setup interrupt handler
	STA	$7FFE
	LDA	#isr/256	; setup interrupt handler
	STA	$7FFF

	LDA	#$06	; enable one-second clock interrupts
	STA	CE

	LDA	#$00
	STA	CD	; clear clock interrupt

	CLI		; enable processor interrupts
	RTS

isr:
	PHA
	LDA	CD
	AND	#$04
	BEQ	1f	; not for us

	LDA	#$00
	STA	CD	; clear interrupt

	LDA	#'.'
	JSR	PUTC
1:
	PLA
	RTI

testmode:
	LDA	CF
	AND	#$08
	BNE	1f

	ORA	#$08	; TEST=1
	STA	CF
	JMP	PUTS
	.asciz	"Test-mode on\r\n"
1:
	AND	#$07	; TEST=0
	STA	CF
	JMP	PUTS
	.asciz	"Test-mode off\r\n"


reset:
	LDA	#$00
	STA	CD	; ADJ=0, IRQ=xxx, BUSY=xxx, HOLD=0
	LDA	#$01	; TIMER=1/64, WAVE OUTPUT, MASK=1
	STA	CE
	LDA	#$05	; TEST=0, 24HOUR=1, STOP=0, REST=1
	STA	CF
	LDA	#$04	; TEST=0, 24HOUR=1, STOP=0, REST=0
	STA	CF
	RTS

hour24:
	LDA	CF
	AND	#$04
	BEQ	1f

	ORA	#$01	; REST=1
	STA	CF
	AND	#$0B	; CLEAR 12/24
	STA	CF
	AND	#$0E	; REST=0
	STA	CF
	JMP	PUTS
	.asciz	"Setting 12-hour time\r\n"
1:
	ORA	#$01	; REST=1
	STA	CF
	ORA	#$4	; SET 12/24
	STA	CF
	AND	#$0E	; REST=0
	STA	CF
	JMP	PUTS
	.asciz	"Setting 24-hour time\r\n"

time:
	LDA	H10
	AND	#$3
	JSR	PUTDEC
	LDA	H1
	JSR	PUTDEC
	LDA	#':'
	JSR	PUTC
	LDA	MI10
;	AND	#$7
	JSR	PUTDEC
	LDA	MI1
	JSR	PUTDEC
	LDA	#':'
	JSR	PUTC
	LDA	S10
;	AND	#$7
	JSR	PUTDEC
	LDA	S1
	JSR	PUTDEC

	LDA	#' '
	JSR	PUTC

	LDA	D10
;	AND	#$3
	JSR	PUTDEC
	LDA	D1
	JSR	PUTDEC
	LDA	#'/'
	JSR	PUTC
	LDA	MO10
;	AND	#$01
	JSR	PUTDEC
	LDA	MO1
	JSR	PUTDEC
	LDA	#'/'
	JSR	PUTC
	LDA	Y10
	JSR	PUTDEC
	LDA	Y1
	JSR	PUTDEC

	LDA	#' '
	JSR	PUTC

	LDA	W
	AND	#$07
	LSL
	TAY
LO	EQU WEEKDAY
HI	EQU WEEKDAY+1
	LDA	LO,Y
	STA	XLO
	LDA	HI,Y
	STA	XHI
	LDY	#$00
1:
	LDA	(XLO),Y
	BNE	2f
	JSR	PUTC
	INY
	JMP	1b
2:
	JSR	PUTS
	.asciz	"\r\n"
	RTS

WEEKDAY	.word	SUNS, MONS, TUES, WEDS, THURS, FRIS, SATS, ERRORS
SUNS	.asciz	"Sunday"
MONS	.asciz	"Monday"
TUES	.asciz	"Tuesday"
WEDS	.asciz	"Wednesday"
THURS	.asciz	"Thursday"
FRIS	.asciz	"Friday"
SATS	.asciz	"Saturday"
ERRORS	.asciz	"Badday"

dump:
	LDY	#$00
1:
	TYA
	JSR	PUTHEX
	LDA	#':'
	JSR	PUTC
	LDA	#' '
	JSR	PUTC
	LDA	REGS,Y
	JSR	PUTHEX
	INY
	LDA	#'\r'
	JSR	PUTC
	LDA	#'\n'
	JSR	PUTC
	CPY	#$10
	BCC	1b

	RTS

PUTDEC:
	AND	#$0F
	ADD	#$30
	JMP	PUTC

	END
