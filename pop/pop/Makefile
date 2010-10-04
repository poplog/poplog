
include ../../config/make

all: basepop11
.PHONY: all

basepop11: newpop11.map
	./copybasepop11

newpop11.map: newpop11
	# see the different nm commands in pglink
	nm -n newpop11 > newpop11.map

newpop11:
	./pglink $(addprefix -,$(POP_LINK_ARGS))

clean:
	rm -f *.o clisp doc help im pml pop11 prolog ref teach ved newpop11* basepop11*
.PHONY:clean
