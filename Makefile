all: phreakium-z.gb

install: phreakium-z.gb
	ems-flasher --format
	ems-flasher --write $<

%.o: %.s
	rgbasm -o $@ $<

phreakium-z.gb: phreakium-z.o
	rgblink -o $@ $<
	rgbfix -vp0 $@
