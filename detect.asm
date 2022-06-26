; 6502
; 65C02
; R65C02
; WDC65C02
; WDC65C802
; WDC65C816

MONITR	EQU	$FFC0
PUTC	EQU	$FFC6
PUTS	EQU	$FFC9
PUTHEX	EQU	$FFCF
CRLF    EQU     $FFD8

	ORG	$0000	; monitor stomps on this...
ZP	.BYTE	0

	ORG	$0200

START	LDX	#$FF
	TXS
	JSR	CRLF
	JSR	CHECK
	JSR	DETECT
	JSR	CRLF
	JMP	MONITR

DETECT	SED		; Trick with decimal mode used
	LDA	#$99	; set negative flag
	CLC
	ADC	#$01	; add 1 to get new accum value of 0
	BMI	IS6502	; branch if 0 does not clear negative flag: 6502
			; else 65C02 or 65802 if neg flag cleared by decimal-mode arith
	CLC
	XCE		; OK to execute unimplemented C02 opcodes
	BCC	IS65C02	; branch if didn’t do anything:65C02
	XCE		; switch back to emulation mode
	JSR	PUTS
	.ASCIZ	"Found WDC65C802/WDC65C816 CPU\r\n"
	JSR	PROBE
	JMP	DONE
IS65C02	JSR	PUTS
	.ASCIZ	"Found 65C02 CPU\r\n"
	JSR	PROBE
	JMP	DONE
IS6502	JSR	PUTS
	.ASCIZ	"Found 6502\r\n"
DONE	CLD		; binary
	RTS

PROBE	JSR	TPHY
	JSR	TSTZ
	JSR	TSTP
	JSR	TWAI
	JSR	TBBS
	JSR	PUTS
	.ASCIZ	"done\r\n"
	RTS

CHECK	JSR	PUTS		; 1B=6502, 0B=65C02: "
	.ASCIZ	"alternate 6502 check: "
	SED
	SEC
	LDA	#$20
	SBC	#$0F
	CLD
	CMP	#$0B
	BEQ	1f
	JSR	PUTS
	.ASCIZ	"6502"
	JMP	CRLF
1:	JSR	PUTS
	.ASCIZ	"65C02"
	JMP	CRLF

; 65C02, R65C02, WDC65C02, WDC65C802
TSTZ	JSR	PUTS		; 65C02 output is FF,00
	.ASCIZ	"check STZ: "
	LDA	#$FF
	STA	ZP
	STZ	ZP
	LDA	ZP
	BNE	1f
	JSR	PUTS
	.ASCIZ	"YES"
	JMP	CRLF
1:	JSR	PUTS
	.ASCIZ	"NO"
	JMP	CRLF

; R65C02, WDC65C02, WDC65C802
TPHY
	JSR	PUTS
	.ASCIZ	"check PHY: "
	LDA	#$00
	PHA
	LDY	#$FF
	PHY
	PLA
	BEQ	1f	; equal to zero?
	PLA
	JSR	PUTS
	.ASCIZ	"YES"
	JMP	CRLF
1:	JSR	PUTS
	.ASCIZ	"NO"
	JMP	CRLF


; R65C02, WDC65C02, WDC65C802
; 6502 will write A|X to address $0402 ; 8F0204
TBBS:
	JSR	PUTS
	.ASCIZ	"check BBS0: "
	LDA	#$01
	STA	$02
	BBS0	$02,YES
	JMP	NO
YES:	JSR	PUTS
	.ASCIZ	"YES"
	JMP	CRLF
NO:	JSR	PUTS
	.ASCIZ	"NO"
	JMP	CRLF

; WDC65C02, WDC65C802
TSTP	JSR	PUTS	; WDC65C02 will halt, R65C02 wont, 6502 will write to subsequent bytes
	.ASCIZ	"check STP: "
	STP
	JSR	PUTS
	.ASCIZ	"NO"
	JMP	CRLF

; WDC65C02, WDC65C802
TWAI			; WDC65C02 will halt, R65C02 wont: "
	JSR	PUTS
	.ASCIZ	"check WAI: "
	WAI
	JSR	PUTS
	.ASCIZ	"NO"
	JMP	CRLF

	END
