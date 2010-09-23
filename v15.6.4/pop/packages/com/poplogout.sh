#!/bin/bash
# J. Meyer, Nov 1990
# Modified A.Sloman for bash 16 Jul 2009
# poplogout - remove Poplog from environment
# usage: source poplogout

if [ ! ${usepop} ]; then exit 0 ; fi
# no poplog to logout from

# print a brief message
echo "poplogout":  poplog, usepop = $usepop


# BASIC UNSETS: remove variables listed in $usepop/pop/com/popenv
# And others added by A.Sloman

for i  in \
        popcom \
        popsrc \
        popsys \
        popexternlib \
        popautolib \
        popdatalib \
        popliblib \
        poppwmlib \
        popsunlib \
        popvedlib \
        poplocalauto \
        poplocalbin \
        popsavelib \
        popcomppath \
        popsavepath \
        popexlinkbase \
        pop_ved      \
        pop_help     \
        pop_ref      \
        pop_teach    \
        pop_doc      \
        pop_im       \
        pop_eliza    \
        pop_prolog   \
        pop_clisp    \
        pop_pml      \
        pop_xved     \
        pop_xvedpro  \
        pop_xvedlisp \
    ;
do
    ## echo $i
    unset $i
done

## # UNSET PATH: remove $usepop and $poplocal from path
## set npath=
## foreach i ( $path )
## if (("$i" !~ "$usepop"*) && ("$i" !~ "$poplocal"*) ) set npath=($npath $i)
## end
## set path=($npath)
## unset npath
##
## # TESTED UNSETS: unset conditionally set variables
## if ("$poplocal" == "$usepop/pop") unsetenv poplocal
## if ("$popcontrib" == "$usepop/pop/contrib") unsetenv popcontrib
## if ("$poplib" == "$HOME") unsetenv poplib
## if ($?pop_pop11) unsetenv pop_pop11
## # UNSET USEPOP
unset usepop

# DONE
