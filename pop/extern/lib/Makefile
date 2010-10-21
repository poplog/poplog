
# 
# mklibpop should be deprecated once this is working
#

include $(usepop)/config/make

# make this 
COMMONSRC=c_callback.c c_sysinit.c pop_poll.c pop_timer.c c_core.c pop_encoding.c pop_stat.c
XSRC=XtPoplog.c

# with X 
# SRCFILES=$(COMMONSRC) $(XSRC)
SRCFILES=$(COMMONSRC)
OBJFILES=$(patsubst %.c,%.$(OBJEXT),$(SRCFILES))

all: libpop.a

clean:
	rm -f *.a *.o *~ *-

# make has all the implicit rules defined for doing this
libpop.a: libpop.a($(OBJFILES))
	$(RANLIB) $@

libXpw.so:
	$(usepop)/pop/com/mkXpw -I/usr/include/X11R6

libXpm.so:
	$(usepop)/pop/com/mkXpm -I/usr/include/X11R6


# src dependancies

# not all src depends on configure, but it doesn't hurt
$(OBJFILES): $(usepop)/config/config.h

c_callback.o: callback.h
c_core.o: c_core.h
c_sysinit.o: callback.h
pop_encoding.o: c_core.h ../unicode/encoding.h
pop_poll.o: c_core.h
pop_timer.o: c_core.h
XtPoplog.o: c_core.h

