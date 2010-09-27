/* --- Copyright University of Sussex 1986.  All rights reserved. ---------
 > File:           $poplocal/local/auto/ved_ccm.p
 > File:           C.unix/lib/ved/ved_ccm.p
 > Purpose:		   Clear Current Message (i.e. delete). Unix only
 > Author:         Aaron Sloman, Nov  8 1986
 > Documentation:  HELP * VED_MAIL
 > Related Files:  LIB *VED_MAIL, *VED_REPLY, *VED_MCM, *VED_MDIR, etc.
 */
section;

;;; N.B. Assumes all unix mail messages start with 'From <name> ....'

uses ved_mcm;

define global ved_ccm;
	;;; Clear current message. Can be retrieved with ved_y
	dlocal vvedmarkprops, ved_search_state, vedediting = false;
	vedmarkpush();
	false -> vvedmarkprops;
	ved_mcm();
	ved_d();
	vedmarkpop();
	;;; If at end, go to beginning of previous message
	if vvedbuffersize > 1 and vedline >= vvedbuffersize then
		ved_check_search('@aFrom ', [back])
	elseunless vedline == 1 then vednextline()
	endif;
	;;; make sure there's a blank line between messages
	if vedline > 1 and vvedlinesize /== 0
	and datalength(vedbuffer(vedline - 1)) /== 0 then
		vedlineabove();
	endif;
	until vvedlinesize /== 0 or vedline > vvedbuffersize do
		vednextline()
	enduntil;
	if isstartstring('From ', vedthisline()) then
		vedskipheaders();
	endif;
	chain(vedrefresh)
enddefine;

endsection;
