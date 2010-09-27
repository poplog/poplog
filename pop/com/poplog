#!/bin/csh
# --- Copyright University of Sussex 1992. All rights reserved. ----------
# File:            C.unix/com/poplog
# Purpose:         Login definitions for POPLOG users
# Author:          John Gibson (see revisions)
# Documentation:
# Related Files:   C.unix/com/popenv, $poplocal/local/com/poplog (if present)


if (-f $usepop/pop/help/message.login && ! -e ~/.hushlogin && $?prompt) then
	cat $usepop/pop/help/message.login
endif

source $usepop/pop/com/popenv

set path = ($popsys $path $popcom)

if (-f $poplocal/local/com/poplog) then
	source $poplocal/local/com/poplog
endif

# --- Revision History ---------------------------------------------------
# --- Adrian Howard, Dec 15 1992 : Added test for prompt being set
# --- Simon Nichols, Oct  5 1990
#       Removed $Xpopbin from $path.
# --- Ian Rogers, Feb 13 1990
#		Added $Xpopbin to $path
# --- John Williams, Feb 23 1989
#       No longer adds "." to $path; tests ~/.hushlogin
