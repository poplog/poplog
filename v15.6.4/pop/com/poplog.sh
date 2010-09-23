#!/bin/sh
# --- Copyright University of Sussex 1990. All rights reserved. ----------
# File:            C.unix/com/poplog.sh
# Purpose:         Login definitions for POPLOG users
# Author:          John Gibson (see revisions)
# Documentation:
# Related Files:   C.unix/com/popenv.sh, $poplocal/local/com/poplog.sh

if [ -f $usepop/pop/help/message.login -a ! -f $HOME/.hushlogin ]
then
	cat $usepop/pop/help/message.login
fi

. $usepop/pop/com/popenv.sh

PATH=$popsys\:$PATH\:$popcom
export PATH

if [ -f $poplocal/local/com/poplog.sh ]
then
	. $poplocal/local/com/poplog.sh
fi


# --- Revision History ---------------------------------------------------
# --- Simon Nichols, Oct  5 1990
#		Removed $Xpopbin from $PATH.
# --- Ian Rogers, Feb 14 1990
#		Added $Xpopbin to PATH
# --- John Williams, Feb 23 1989
#       No longer adds ":" to $PATH; tests $HOME/.hushlogin
