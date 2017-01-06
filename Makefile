all: phreakium-z.gb

%.o: %.s
	rgbasm -o $@ $<

phreakium-z.gb: phreakium-z.o
	rgblink -o $@ $<
	rgbfix -vp0 $@
