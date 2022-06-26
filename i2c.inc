; I2C board @$8000
; (bi-directional)
; SDA, pin 1
; SCL, pin 0
 
PORT	EQU	$8000

SDA	EQU 0
SCL	EQU 1

i2c_init:
	PHA
	LDA	#(1<<SCL)|(1<<SDA)	; SCL/SDA high
	STA	PORT
	PLA
	RTS

; SCL/SDA will both be high
i2c_start:
	PHA
	LDA	#(1<<SCL)|(1<<SDA)	; SCL+SDA high
	STA	PORT
	LDA	#(1<<SCL)		; SDA low
	STA	PORT
	LDA	#$00			; SCL low
	STA	PORT
	PLA
	RTS
 
i2c_stop:
	PHA
	LDA	#$00			; SCL+SDA low
	STA	PORT
	LDA	#(1<<SCL)		; SCL high
	STA	PORT
	LDA	#(1<<SCL)|(1<<SDA)	; SDA high
	STA	PORT
	PLA
	RTS

OBYTE	.BYTE	0

; SCL/SDA will both be low after start
; carry set on error
i2c_write:
	STA	OBYTE
	PHA
	TXA
	PHA

	LDX	#8
	LDA	#$00
1:
	AND	#~(1<<SCL)		; SCL low
	STA	PORT

	LDA	#$00			; setup SDA
	ASL	OBYTE			; shift MSB into C
	ROL				; shift C into LSB		; hardcoded SDA to bit 0
	STA	PORT

	ORA	#(1<<SCL)		; SCL high
	STA	PORT

	; check for clock stretching???

	DEX
	BNE	1b

	AND	#~(1<<SCL)		; SCL low
	STA	PORT

	LDA	#(1<<SDA)		; SDA high
	STA	PORT
	LDA	#(1<<SCL)|(1<<SDA)	; SCL high
	STA	PORT
2:					; wait clock line to rise (clock stretching)
	LDA	PORT
	BIT	#(1<<SCL)
	BEQ	2b

	LDA	PORT			; read ACK
	LSR

	LDA	#(1<<SDA)		; SCL low
	STA	PORT

	PLA
	TAX
	PLA
	RTS

; returns byte in A
i2c_read:
	TXA
	PHA
	
	LDX 	#$08
1:
	LDA	#(1<<SDA)		; SCL low
	STA	PORT

	LDA	#(1<<SCL)|(1<<SDA)	; SCL high
	STA	PORT
2:					; wait clock line to rise (clock stretching)
	LDA	PORT
	BIT	#(1<<SCL)
	BEQ	2b

	LSR				; hardcoded SDA into bit 0
	ROL	OBYTE
	DEX
	BNE	1b

	LDA	#(1<<SDA)		; SCL low
	STA	PORT

	PLA
	TAX

	LDA	OBYTE

	RTS

i2c_ack:
	PHA

	LDA	#00			; SDA low (ACK)
	STA	PORT

	LDA	#(1<<SCL)		; SCL high
	STA	PORT
2:					; wait clock line to rise (clock stretching)
	LDA	PORT
	BIT	#(1<<SCL)
	BEQ	2b

	LDA	#00			; SCL low
	STA	PORT

	PLA
	RTS

i2c_nack:
	PHA

	LDA	#(1<<SDA)		; SDA high
	STA	PORT

	LDA	#(1<<SCL)|(1<<SDA)	; SCL high
	STA	PORT
2:					; wait clock line to rise (clock stretching)
	LDA	PORT
	BIT	#(1<<SCL)
	BEQ	2b

	LDA	#(1<<SDA)		; SCL low
	STA	PORT

	PLA
	RTS
