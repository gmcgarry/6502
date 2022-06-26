; prints message to ACIA
; RAMless

; CLOCK = 1843200Hz => 
;	/16 = 115.2k bps

ACIA	EQU	$D800
ACIACS	EQU	ACIA+0
ACIADA	EQU	ACIA+1

XHI	EQU	$30
XLO	EQU	$31

	.base	$E000
	.org	$E000
START:
        LDA    #$03    ; RESET CODE
        STA    ACIACS
        NOP
        NOP
        NOP
        LDA    #$15    ; 0,00,101,01: no rx irq, RTS=low no tx irq, /16, N81 NON-INTERRUPT
        STA    ACIACS
2:
	LDY	#$00
1:
        LDA    ACIACS
        LSR    
        LSR    
        BCC     1b
	LDA	message,Y
	BEQ	2b
	INY
        STA	ACIADA
	JMP	1b

message:
	.asciz	"this is the message!\r\n"

        .org    $FFFA
nmi:
        .word   START
reset:
        .word   START
irq:
        .word   START

	.end
