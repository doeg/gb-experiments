ASM = rgbasm
LINK = rgblink
FIX = rgbfix

#Change the following lines
ROM_NAME = bcd-demo

SOURCES = \
	$(wildcard src/*.asm) \
	$(wildcard src/**/*.asm)

FIX_FLAGS = -v -p 0

INCDIR = inc
OBJECTS = $(SOURCES:%.asm=%.o)

all: $(ROM_NAME)

$(ROM_NAME): $(OBJECTS)
	$(LINK) -o $@.gb -n $@.sym $(OBJECTS)
	$(FIX) $(FIX_FLAGS) $@.gb

%.o: %.asm
	$(ASM) -i$(INCDIR)/ -i"../lib/" -o $@ $<

clean:
	rm -f *.gb *.sym $(OBJECTS)
