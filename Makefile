
include config/make

POPSRC := pop/src/*.p

all: pop/lib/psv/startup.psv

pop/lib/psv/startup.psv: $(POPSRC)
	pop/com/mkstartup
	INSTALL/LINK_USING_NEWPOP $(POP_LINK_ARGS)

