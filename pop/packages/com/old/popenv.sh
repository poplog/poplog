# --- Copyright University of Sussex 1991. All rights reserved. ----------
### --- Copyright University of Birmingham 2001. All rights reserved. ------
# File:             $poplocal/local/com/popenv.sh
# Purpose:          set up local Poplog environment for users of sh. ksh or bash
# Author:           John Williams, May  8 1990 (see revisions)
# Extended:         Aaron Sloman, Sep 14 1995, 7 Oct 2001
# Documentation:	REF system
# Related Files:    $popcom/popenv.sh
#					$popsys/popenv.sh
# 					$poplocal/local/com/poplog.sh
#     				$poplocal/local/com/popenv (for csh/tcsh users)

## Override default poplocalbin defined in $popcom/popenv
## It should be in part of the poplog tree not part of the local tree
## This may be unnecessary if symbolic links have been set up right
poplocalbin=$usepop/poplocalbin
export poplocalbin

## Convenient local environment variable
local=$poplocal/local
export local

# Check if local startup.psv has been build
if [ -f $poplocalbin/startup.psv ] ;
then
	pop_pop11="+$poplocalbin/startup.psv"
	export pop_pop11

	# remove any of these not wanted at any particular site
	pop_xved="$pop_pop11 +$poplocalbin/xved.psv"
	pop_prolog="$pop_pop11 +$poplocalbin/prolog.psv"
	pop_xvedpro="$pop_pop11 +$poplocalbin/xvedpro.psv"
	pop_clisp="$pop_pop11 +$poplocalbin/clisp.psv"
	pop_xvedlisp="$pop_pop11 +$poplocalbin/xvedlisp.psv"
	pop_pml="$pop_pop11 +$poplocalbin/pml.psv"
	export pop_prolog pop_pml pop_xved pop_xvedpro  pop_xvedlisp

    pop_ved="$pop_pop11 :sysinitcomp();ved"; export pop_ved
    pop_help="$pop_pop11 :sysinitcomp();help"; export pop_help
    pop_ref="$pop_pop11 :sysinitcomp();ref"; export pop_ref
    pop_teach="$pop_pop11 :sysinitcomp();teach"; export pop_teach
    pop_doc="$pop_pop11 :sysinitcomp();doc"; export pop_doc
    pop_im="$pop_pop11 :sysinitcomp();im"; export pop_im

	# Optional
	pop_eliza="$pop_pop11 +$poplocalbin/eliza.psv"
	export pop_eliza

    # See others defined in $popsys/popenv.sh
fi


# --- Revision History ---------------------------------------------------
# --- Aaron Sloman: 2 Nov 2001
#            Restored some missing bits
#            (Cannot depend on $popsys/popenv)
# --- Aaron Sloman: 7 Oct 2001
#     		Further reorganisation	
# --- Aaron Sloman Sept 1995
#		Updated for current Birmingham setup
# --- Robert John Duncan, May 29 1991
#		Made all pop_X variables relative to pop_pop11
