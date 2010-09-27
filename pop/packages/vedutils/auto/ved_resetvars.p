/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/auto/ved_resetvars.p
 > Purpose:			Clear out automatically declared identifiers
 > Author:          Aaron Sloman and Tim Read, Jan 11 1994
 > Documentation:
 > Related Files:
 */


define ved_resetvars();
	;;; cancel all automatically declared variables and reset popwarnings
	applist(popwarnings, syscancel);
	[] -> popwarnings;
	vedputmessage('"popwarnings" has been reset')
enddefine;
