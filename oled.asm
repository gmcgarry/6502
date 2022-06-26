;
; Demo on OLED display
;   - 0.96 inch OLED (white)
;   - SSD1306 driver chip
;   - 128X64 pixels
;   - I2C interface

STACK		EQU	$FF
OLED_ADDR	EQU	$3C

MONITR  EQU     $FFC0
GETC    EQU     $FFC3
PUTC    EQU     $FFC6
PUTS    EQU     $FFC9
KBHIT   EQU     $FFCC
GETHEX  EQU     $FFD2
PUTHEX  EQU     $FFCF
OUTSP   EQU     $FFD5
CRLF    EQU     $FFD8

	ORG	$0000
XLO	.BYTE	0
XHI	.BYTE	0
FONTP	.WORD	0

	ORG	$0200
; ------------------------------------------------------------ 
RESET:
	LDX	#STACK
	TXS
	JMP	MAIN

; ------------------------------------------------------------ 
ColStart:	.BYTE	0
ColEnd:		.BYTE	0
PageStart:	.BYTE	0
PageEnd:	.BYTE	0

; ------------------------------------------------------------ 
MAIN:
	JSR	PUTS
	.asciz "OLED Test\r\n"

	JSR	oled_init
	JSR	oled_clear

	LDA	#$00
	STA	ColStart
	STA	PageStart

	JSR	PUTS
	.asciz "!?@Aa|\r\n"

	JSR	putstring
	.asciz "!?@Aa|\r\n"

loop:
	JSR	PUTS
	.asciz "on \r"
	JSR	putstring
	.asciz "on \r"
	JSR	Delay

	JSR	PUTS
	.asciz "off\r"
	JSR	putstring
	.asciz "off\r"
	JSR	Delay

	JSR	KBHIT
	BCC	loop

	JMP	MONITR

; ------------------------------------------------------------ 
Delay:
	LDX	#$00
	LDY	#$00
1:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	DEX
	BNE	1b
	DEY
	BNE	1b
	RTS

TEMP	.BYTE	2

; ------------------------------------------------------------ 
oled_init:
	PHA
	TXA
	PHA

	JSR	i2c_init

	JSR	i2c_start
	LDA	#(OLED_ADDR<<1)
	JSR	i2c_write

	LDX	#$00
2:	LDA	#$80
	JSR	i2c_write
	LDA	init_data,X
	JSR	i2c_write
	INX
	CPX	#(init_data_end - init_data)
	BNE	2b

	JSR	i2c_stop

	PLA
	TAX
	PLA
	RTS

init_data:
	.BYTE	$8D	; enable charge-pump regulator
	.BYTE	$14
	.BYTE	$AF	; display on
	.BYTE	$20	; set memory addressing mode to Horizontal Addressing Mode
	.BYTE	$00
	.BYTE	$21	; reset column address
	.BYTE	$00
	.BYTE	$FF
	.BYTE	$22	; reset page address
	.BYTE	$00
	.BYTE	$07
init_data_end:

; ------------------------------------------------------------ 
oled_clear:
	PHA
	TXA
	PHA
	TYA
	PHA

	LDX	#64		; rows
1:
	JSR	i2c_start
	LDA	#(OLED_ADDR<<1)
	JSR	i2c_write

	LDA	#$40		; set start line to 0
	JSR	i2c_write

	LDY	#16		; 16*8 columns
2:
	LDA	#$00
	JSR	i2c_write
	DEY
	BNE	2b

	JSR	i2c_stop

	DEX
	BNE	1b

	PLA
	TAY
	PLA
	TAX
	PLA
	RTS

; ------------------------------------------------------------ 
putstring:
	PLA
        STA     XLO
        PLA
        STA     XHI
3:      LDY     #1
        LDA     (XLO),Y         ; Get the next string character
        INC     XLO             ; update the pointer
        BNE     1f              ; if not, we're pointing to next character
        INC     XHI             ; account for page crossing
1:      ORA     #0              ; Set flags according to contents of Accumulator
        BEQ     2f              ; don't print the final NULL
        JSR     putchar		; write it out
        JMP     3b              ; back around
2:      INC     XLO             ;
        BNE     1f              ;
        INC     XHI             ; account for page crossing
1:      JMP     (XLO)           ; return to byte following final NULL

; ------------------------------------------------------------ 
; A=char
putchar:
	PHA
	STA	TEMP
	TYA
	PHA
	LDA	TEMP

	CMP	#'\r'
	BNE	1f

	LDY	#$00
	STY	ColStart
	JMP	9f
1:
	CMP	#'\n'
	BNE	2f

	CLC
	LDA	PageStart
	ADC	#FONTHEIGHT
	STA	PageStart
	JMP	9f
2:
	LDY	#<Font		; Point to FontTable
	STY	FONTP+0
	LDY	#>Font
	STY	FONTP+1

	SEC
	SBC	#$20		; Table matching (Lookup table = ASCII table - Table Offset Value)
	BEQ	5f

	TAY
3:	CLC			; ptr = Font + W*H*char
	LDA	FONTP+0
	ADC	#(FONTWIDTH*FONTHEIGHT)
	STA	FONTP+0
	LDA	FONTP+1
	ADC	#$00
	STA	FONTP+1
	DEY
	BNE	3b
5:
	LDA	ColStart		; check if ColStart > 128-FONTWIDTH+1
	CMP	#(128-FONTWIDTH+1)
	BCC	6f

	LDA	#$00
	STA	ColStart
	LDA	PageStart
	CLC
	ADC	#FONTHEIGHT
	STA	PageStart
6:
	CLC
	LDA	ColStart
	ADC	#(FONTWIDTH-1)
	STA	ColEnd

	LDA	PageStart
	ADC	#(FONTHEIGHT-1)
	STA	PageEnd

	JSR	SetColumn
	JSR	SetPage

	JSR	i2c_start
	LDA	#(OLED_ADDR<<1)
	JSR	i2c_write

	LDA	#$40
	JSR	i2c_write

	LDY	#$00
7:
	LDA	(FONTP),Y
	JSR	i2c_write
	INY
	CPY	#(FONTWIDTH*FONTHEIGHT)
	BCC	7b

	JSR	i2c_stop

	CLC
	LDA	ColStart
	ADC	#FONTWIDTH
	STA	ColStart
9:
	PLA
	TAY
	PLA
	RTS

; ------------------------------------------------------------ 
SetColumn:
	JSR	i2c_start
	LDA	#(OLED_ADDR<<1)
	JSR	i2c_write

	LDA	#$00		; command stream
	JSR	i2c_write

	LDA	#$21		; set column address range
	JSR	i2c_write

	LDA	ColStart
	JSR	i2c_write

	LDA	ColEnd
	JSR	i2c_write

	JSR	i2c_stop

	RTS

; ------------------------------------------------------------ 
SetPage:
	JSR	i2c_start
	LDA	#(OLED_ADDR<<1)
	JSR	i2c_write

	LDA	#$00		; command stream
	JSR	i2c_write

	LDA	#$22		; set page address range
	JSR	i2c_write

	LDA	PageStart
	JSR	i2c_write

	LDA	PageEnd
	JSR	i2c_write

	JSR	i2c_stop

	RTS

.include "i2c.inc"
.include "font8x16.inc"

	END
