/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/auto/ved_mcm.p
 > Purpose:			Mark Current Message
 > Author:          Aaron Sloman, Nov 13 1995
 > Documentation:	HELP * VED_MCM, * VED_GETMAIL
 > Related Files:
 */

/*
Changed Nov 1995 to use vedatmailstart(), to make recognition
of message start more accurate, without depending on From lines
in message body being indented.
*/


/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 > File:            C.unix/lib/ved/ved_mcm.p
 > Purpose:		   Mark "current" message, in a Unix mail file
 > Author:         Aaron Sloman, Nov  1 1986 (see revisions)
 > Documentation:  See comments below
 > Related Files:  LIB * VED_REPLY  * VED_MDIR  * VED_SEND
 */
compile_mode :pop11 +strict;

;;; Mark Current Message

section;

;;; The following is a separate procedure because it may one day be
;;; useful outside ved_mcm.

define constant vedmailbounds(proc1,proc2);

	;;; Execute proc1 at beginning of message, proc2 at end
	;;; Not totally reliable at finding bounds!

	lvars line, proc1, proc2, found, was_at_top = false;

	;;; Protect ved search state variables
	dlocal ved_search_state;

	dlocal vedpositionstack;

	define lconstant err();
		vedpositionpop();
		vederror('NOT IN MAIL MESSAGE')
	enddefine;

	vedpositionpush();
	1 -> vedcolumn;
	;;; Find text above cursor
	until vedline == 1 or vvedlinesize /== 0 do vedcharup() enduntil;

	if vedline == 1 then
		true -> was_at_top;
		;;; If it's empty, find where text starts in file
		while vvedlinesize == 0 do
			vedchardown();
			if vedatend() then
				err();
			endif;
		endwhile;
	endif;

	;;; Find beginning of message
	repeat
		if vvedlinesize /== 0 and vedatmailstart() then
   			quitloop()
   		elseif vvedlinesize /== 0 and was_at_top then
			;;; found text, but not at mail start
			err();
		elseif vedatstart() then
			err();
		endif;
		vedcharup()
	endrepeat;
	;;; Found beginning of message
	proc1();
	vedline -> line;
	false -> found;
	while ved_try_search('@aFrom ', #_< [nowrap] >_#) ;;; and vedline > line
	then
		if vedatmailstart() then
			true -> found;
			vedcharup();
			quitloop();
		endif
	endwhile;
	unless found then vedendfile() endunless;
	;;; Found end of message
	proc2();
	vedpositionpop();
enddefine;

define vars ved_mcm;
	;;; mark current message
	vedmailbounds(vedmarklo,vedmarkhi);
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman Nov 12 1995
	changed to use vedatmailstart and ved_try_search
--- Jonathan Meyer, Sep 29 1993
		Changed dlocal of vvedsr*ch vars to ved_search_state.
		ved*testsearch -> ved_try_search.
--- Aaron Sloman, Jun 20 1990
	Fixed behaviour on line before beginning of message. Changed to use
	isstartstring
--- Aaron Sloman, Aug 22 1988
	localised more variables in ved_mcm
 */
