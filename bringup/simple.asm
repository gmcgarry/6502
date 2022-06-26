; minibug
PUTSTRI	EQU	$FFC9
MONITR	EQU	$FFC0

	.org	$0200
start:
	JSR	PUTSTRI
	.asciz	"\r\nthis is the message\r\n"
	JMP	MONITR
