all:	memdump.hex memdump.bin memdump2.hex acia.hex acia2.hex zptest.hex

clean:
	$(RM) *.hex *.s19 *.lst *.bin

.SUFFIXES:	.hex .asm .s19 .bin

.asm.hex:
	pasm-6502 -d1000 -F hex -o $@ $< > $@.lst

.asm.s19:
	pasm-6502 -d1000 -F srec2 -o $@ $< > $@.lst

.asm.bin:
	pasm-6502 -d1000 -F bin -o $@ $< > $@.lst
