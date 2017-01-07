all: phreakium-z.gb

install: phreakium-z.gb
	ems-flasher --format
	ems-flasher --write $<

phreakium-z.o: symbols.bin font.bin

%.o: %.s
	rgbasm -o $@ $<

phreakium-z.gb: phreakium-z.o
	rgblink -o $@ -n $(patsubst %.o,%.sym,$<) $<
	rgbfix -vp0 $@
