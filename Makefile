.PHONY: \
	all \
	animation \
	bcd \
	clean \
	template

all : animation bcd template

animation :
		$(MAKE) -C animation

bcd :
		$(MAKE) -C bcd

clean :
		$(MAKE) -C animation clean
		$(MAKE) -C bcd clean
		$(MAKE) -C template clean

template :
		$(MAKE) -C template
