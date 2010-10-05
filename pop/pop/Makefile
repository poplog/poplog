
include ../../config/make

TPATH := $(PATH)
PATH = $(CURDIR):$(TPATH)
all: basepop11


basepop11: newpop11.map newpop11.stb
	./copybasepop11

# newpop11.map: newpop11
# 	# see the different nm commands in pglink
# 	nm newpop11 > newpop11.map

newpop11.stb:
	touch newpop11.stb

# see also http://www.cs.bham.ac.uk/research/projects/poplog/tools/relinking.linux.poplog
newpop11 newpop11.map: poplink poplink.psv
	./pglink $(POP_LINK_ARGS) -map

newpop.psv: corepop11
	$(popsrc)/mknewpop 

popc poplibr poplink: corepop
	ln -s corepop $@

popc.psv poplibr.psv poplink.psv: corepop
	$(popsrc)/mksyscomp $(basename $@) 

clean:
	rm -f *- *.o clisp doc help im pml pop11 prolog ref teach ved newpop11* basepop11*
	rm -f poplink_cmnd oldpop11* popc poplibr poplink
	rm *.psv

