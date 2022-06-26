all:	msm6242.s19 speed.s19 detect.s19 mon.hex

clean:
	$(RM) *.hex *.lst *.s19

.SUFFIXES:	.hex .asm .s19 .bin

.asm.bin:
	pasm-6502 -d1000 -F bin -o $@ $< > $@.lst

.asm.hex:
	pasm-6502 -d1000 -F hex -o $@ $< > $@.lst

.asm.s19:
	pasm-6502 -d1000 -F srec2 -o $@ $< > $@.lst
