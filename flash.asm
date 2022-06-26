; 24LC256 w/ 64-byte pages
;
; board pinout:
; GND, D0 (SDA), D1 (SCL), VCC
;
; pinout:
;
;       +--v--+
;   A0 -|1   8|- VCC
;   A1 -|2   7|- WP
;   A2 -|3   6|- SCL
;  VSS -|4   5|- SDA
;       +-----+

.include 'i2c.inc'

STACK	EQU	$FF
ADDRESS	EQU	$50	; 1010 000x

MONITR  EQU	$FFC0
GETC    EQU	$FFC3
PUTC    EQU	$FFC6
PUTS    EQU	$FFC9
KBHIT	EQU	$FFCC
PUTHEX	EQU	$FFCF

	ORG	$FF
TEMP	.BYTE	0

	ORG	$0200
; ------------------------------------------------------------
RESET:
	LDX	#STACK
	TSX
	JMP	MAIN

; ------------------------------------------------------------
MAIN:
	JSR	PUTS
	.asciz	"\r\n24LC512 driver\r\n"

LOOP:
	JSR	PUTS
	.asciz "\r\n"
	JSR	PUTS
	.asciz "# "

	JSR	GETC

1:	CMP	#'N'		; read next byte
	BNE	1f
	LDA	#' '
	JSR	PUTC
	JSR	READNEXT
	JSR	PUTHEX
	JMP	LOOP

1:	CMP	#'D'		; dump all
	BNE	1f
	JSR	DUMPMEM
	JMP	LOOP

1:	CMP	#'W'		; write byte
	BNE	1f
	LDA	#' '
	JSR	PUTC
	JSR	BADDR
	LDA	#' '
	JSR	PUTC
	JSR	BYTE
	JSR	WRITEBYTE
	JSR	LOOP

1:	CMP	#'B'		; block write
	BNE	1f
	LDA	#' '
	JSR	PUTC
	JSR	BADDR
	LDA	#' '
	JSR	PUTC
	JSR	BYTE
	JSR	WRITEBLOCK
	JSR	LOOP

1:	CMP	#'R'		; read byte
	BNE	1f
	LDA	#' '
	JSR	PUTC
	JSR	BADDR
	LDA	#' '
	JSR	PUTC
	JSR	READBYTE
	JSR	PUTHEX
	JSR	LOOP

1:	CMP	#'X'		; exit
	BNE	LOOP

	JMP	MONITR

; ------------------------------------------------------------
ERROR:
	JSR	PUTS
	.asciz "ERROR: missing ACK\r\n"
	JMP	MONITR

XLO	.zero	1
XHI	.zero	1

; ------------------------------------------------------------
DUMPMEM:
	LDA	#$00
	STA	XLO
	STA	XHI

	JSR	i2c_start

	LDA	#(ADDRESS<<1)
	JSR	i2c_write
	BCS	ERROR

	LDA	XHI
	JSR	i2c_write
	BCS	ERROR

	LDA	XLO
	JSR	i2c_write
	BCS	ERROR

	JSR	i2c_start

	LDA	#(ADDRESS<<1)|1
	JSR	i2c_write
	BCS	ERROR
1:
	LDA	XLO
	AND	#$0F
	BNE	2f

	LDA	#'\r'
	JSR	PUTC
	LDA	#'\n'
	JSR	PUTC
	LDA	XHI
	JSR	PUTHEX
	LDA	XLO
	JSR	PUTHEX
	LDA	#':'
	JSR	PUTC
2:
	LDA	#' '
	JSR	PUTC

	JSR	i2c_read
	JSR	i2c_ack

	JSR	PUTHEX

	JSR	KBHIT
	BCS	3f

	INC	XLO
	BNE	1b
	INC	XHI
	BNE	1b
3:
	JSR	i2c_read
	JSR	i2c_nack

	JSR	i2c_stop

	RTS

; ------------------------------------------------------------
; A=data
; XLO/XHI=address
WRITEBYTE:
	PHA

	JSR	i2c_start

	LDA	#(ADDRESS<<1)
	JSR	i2c_write
	BCS	ERROR

	LDA	XHI
	JSR	i2c_write
	BCS	ERROR

	LDA	XLO
	JSR	i2c_write
	BCS	ERROR

	PLA
	JSR	i2c_write
	BCS	ERROR

	JSR	i2c_stop

	RTS

; ------------------------------------------------------------
; A=data
; XHI/XLO=address
; block size = 64
WRITEBLOCK:
	PHA

	JSR	i2c_start

	LDA	#(ADDRESS<<1)
	JSR	i2c_write
	BCS	ERROR

	LDA	XHI
	JSR	i2c_write
	BCS	ERROR

	LDA	XLO
	JSR	i2c_write
	BCS	ERROR

	LDA	XLO
	EOR	#$FF
	SEC
	ADC	#$40
	TAX
	
	PLA
1:
	JSR	i2c_write
	BCS	ERROR
	DEX
	BNE	1b

	JSR	i2c_stop

	RTS

; ------------------------------------------------------------
WAITWRITE:
1:
	LDA	#'X'
	JSR	PUTC

	JSR	i2c_start

	LDA	#(ADDRESS<<1)
	JSR	i2c_write

	JSR	i2c_stop
	BCS	1b

	RTS

; ------------------------------------------------------------
; A=data
READNEXT:
	JSR	i2c_start

	LDA	#(ADDRESS<<1)|1
	JSR	i2c_write
	BCS	ERROR

	JSR	i2c_read
	JSR	i2c_nack
	JSR	i2c_stop

	RTS

; ------------------------------------------------------------
; A=data
; XHI/XLO=address
READBYTE:
	JSR	i2c_start

	LDA	#(ADDRESS<<1)
	JSR	i2c_write
	BCS	ERROR

	LDA	XHI
	JSR	i2c_write
	BCS	ERROR

	LDA	XLO
	JSR	i2c_write
	BCS	ERROR

	JSR	i2c_start

	LDA	#(ADDRESS<<1)|1
	JSR	i2c_write
	BCS	ERROR

	JSR	i2c_read
	JSR	i2c_nack

	JSR	i2c_stop

	RTS

; BUILD ADDRESS
BADDR   JSR	BYTE    ; READ 2 FRAMES
	STA	XHI
	JSR	BYTE
	STA	XLO
	RTS

; INPUT BYTE (TWO FRAMES)
BYTE    JSR	INHEX   ; GET HEX CHAR
	ASL
	ASL
	ASL
	ASL
	STA	TEMP
	JSR	INHEX
	AND	#$0F
	ADD	TEMP
	RTS

; INPUT HEX CHAR
INHEX	JSR	GETC
	CMP	#'9'+1
	BCC	1f
	SBC	#7+1
1:
	SBC	#'0'-1
	RTS

	END
