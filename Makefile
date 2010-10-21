

include config/make

POPSRC = pop/src/*.p
EXLIB = pop/extern/lib

# first target is default
all: pop/lib/psv/startup.psv

# many build scripts need the environment set
#ifndef $(usepop)
#	$(exec  . bin/poplog.sh ; $(MAKE) )
#endif

pop/lib/psv/startup.psv: pop/pop/basepop11 $(POPSRC)
	pop/com/mkstartup

pop/pop/basepop11: $(EXLIB)/libpop.a
	$(MAKE) -C pop/pop basepop11

$(EXLIB)/libpop.a: $(EXLIB)/*.c $(EXLIB)/*.h config/config.h
	$(MAKE) -C $(EXLIB) all

# see http://www.cs.bham.ac.uk/research/projects/poplog/tools/relinking.linux.poplog
# compare with INSTALL/LINK_USING_NEWPOP
install: pop/lib/psv/startup.psv
	pop/src/newpop $(POP_LINK_ARGS) -norsv

clean:
	$(MAKE) -C pop/pop clean
	$(MAKE) -C pop/extern/lib clean

distclean: clean
	$(MAKE) -C config clean

