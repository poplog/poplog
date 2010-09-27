/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/auto/vedatmailstart.p
 > Purpose:			Check whether at beginning of message in mail file
 > Author:          Aaron Sloman, Nov 11 1995 (see revisions)
 > Documentation:	Below for now
 > Related Files:	LIB * VED_MCM *VED_CCM *VED_NM *VED_LM
 */

/*

vedatmailstart()
	Returns true or false depending on whether the current line (vedline)
	is or is not at the beginning of a mail message in a Unix mail file.
	It uses fairly crude tests to distinguish mail messages starting
		From <name> date ...

	from a line within a message starting
		From ...
*/

section;

define lconstant starts_ok(string) /* -> boole */;
	;;; Check that the string starts with a word, then a colon then a space
	;;; If it starts 'Received: ' or 'To: 'then no more testing needed.
	lvars string, n, k;
	locchar(`:`, 1, string) -> n;
	if n and n fi_> 2 then
		if isstartstring('Received: ', string)
		or isstartstring('To: ', string)
		or isstartstring('Original-Received: ', string)
		then 1
		else
			;;; Check that there is no space before the colon in
			;;; this line
			locchar(`\s`, 1, string) -> k;
			if k then
				if k fi_< n then
					false
				else
					true
				endif
			else
				false
			endif
		endif
	else false
	endif /* -> boole */
enddefine;


define vedatmailstart() /* -> boole */;
	lvars s, OK;
	if vedatend() then false
	else
		;;; Check if line starts with From
		fast_subscrv(vedline, vedbuffer) -> s;
		if isstartstring('From ', s) then
			;;; Check next line. (Should do more).
			if (starts_ok(fast_subscrv(vedline fi_+ 1, vedbuffer)) ->> OK) == 1
			then
				true
			elseif OK then
				;;; Not 'Received: ' Check for one more colon case
				starts_ok(fast_subscrv(vedline fi_+ 2, vedbuffer))
			else
				false
			endif
		else
			false
		endif
	endif /* -> boole */
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  9 1999
	Fixed to handle Original-Received: lines
 */
