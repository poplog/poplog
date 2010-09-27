


all: pop/lib/psv/startup.psv

pop/lib/psv/startup.psv: pop/src/*.p
	pop/com/mkstartup
	INSTALL/LINK_USING_NEWPOP nox

