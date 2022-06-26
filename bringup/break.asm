MONITR	EQU	$FFC0
PUTS	EQU	$FFC9

	ORG	$0200
START:
	JSR	PUTS
	.asciz	"\r\nInvoking BRK\r\n"

	BRK

	JSR	PUTS
	.asciz	"\r\nBack from BRK\r\n"

	JMP	MONITR

	END
