

include config/make

POPSRC = pop/src/*.p

# first target is default
all: env pop/lib/psv/startup.psv
.PHONY : all

env:
#	ifndef $(usepop)
#		exec ( . bin/poplog.sh ; $(MAKE) )
#	endif
#.PHONY:env

pop/lib/psv/startup.psv: env pop/pop/basepop11 $(POPSRC)
	pop/com/mkstartup
	INSTALL/LINK_USING_NEWPOP $(POP_LINK_ARGS)

pop/pop/basepop11: env pop/pop/newpop11
	cd pop/pop && $(MAKE) basepop11

pop/pop/newpop11: env
	cd pop/pop && $(MAKE) newpop11
