/* --- Copyright University of Birmingham 2010. All rights reserved. ------
 >  --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/ask_xved.p
 > Purpose:         Allow user's vedinit.p to ask whether to use Xved
 > Author:          Aaron Sloman, Nov 22 1995
 > Documentation:
 > Related Files:
 */


section;

global vars INXVED = false;

define global ask_xved();
	lvars rrr;

	if systranslate('DISPLAY') then
		if vedusewindows = "x" then
			true
		else
			pr('\nUse XVED? (y/n):- \n');
			rawcharin() -> rrr;

			if strmember(rrr, 'yY\r') then
				true
			else false
			endif
		endif
	else
		false
	endif -> INXVED;
	if INXVED then
		useslib("startup");
		"x" -> vedusewindows
	endif
enddefine;

endsection;

/*
-- Revision notes:
-- 27 Feb 2010 Aaron Sloman
	Altered to make sure 'startup' compiled before assigning to
	vedusewindows.
*/
