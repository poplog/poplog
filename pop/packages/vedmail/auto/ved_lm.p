/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/ved_lm.p
 > Purpose:			Go to "last = previous" message in current mail file
 > Author:          Aaron Sloman, Nov 12 1995
 > Documentation:	Below, HELP * VED_GETMAIL
 > Related Files:	LIB * VEDATMAILSTART, * VED_MCM, * VED_MCM
 */

/*
HELP VED_NM and VED_LM                                 A.Sloman Nov 1985

ENTER nm
	Go to next message in Unix mail file.

ENTER lm
	Go to last(previous) message

Tries to skip irrelevant parts of mail headers.

ved_lm.p is a link to ved_nm.p to save duplication

*/
section;

uses vedskipheaders;

define ved_nm;
	lvars line = vedline, found = false;
	fast_for vedline from vedline + 1 to vvedbuffersize + 1 do
		if vedatmailstart() then
			true -> found;
			quitloop();
		elseif vedatend() then
			quitloop()
		endif
	endfast_for;
	if found then
		vedskipheaders()
	else
		vederror('No More Messages')
	endif;
enddefine;


define ved_lm;
	lvars line, found = false, outofmessage = false;
	;;; first go back out of message.

	if vedatend() then true -> outofmessage endif;

	fast_for vedline from vedline - 1 by -1 to 1 do
		quitif(vedline < 1);
		if vedatmailstart() then
			if outofmessage then
				true -> found;
				quitloop();
			else
				true -> outofmessage
			endif
		endif
	endfast_for;
	if found then
		vedskipheaders()
	else
   		vederror('NOPREVIOUS MESSAGE')
	endif;
enddefine;



endsection;
