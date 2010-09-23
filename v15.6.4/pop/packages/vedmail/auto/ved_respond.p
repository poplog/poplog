/* --- Copyright University of Birmingham 2009. All rights reserved. ------
 > File:            $usepop/pop/packages/vedmail/auto/ved_respond.p
 > Purpose:			Reply to message, quoting it indented.
 > Author:          Aaron Sloman, Feb  6 1992 (see revisions)
 > Documentation:	HELP * VED_GETMAIL
 > Related Files:	LIB * ved_Respond.p
 */

/*

-- ENTER respond
-- ENTER Respond
    These two commands are like "ENTER reply" and "ENTER Reply" as
    described in HELP * VED_REPLY, except that they also copy the
    original message into the reply and indent it using ">". This
    makes it easier to prepare a reply with bits of the original message
    quoted.


*/

section;

define lconstant vedrespond(proc);
	;;; prepare a reply followed by quoted and indented copy of
	;;; the message. proc is either ved_reply or ved_Reply
	lvars proc, arg = vedargument, commandstring = 'gsr/@a/> /', dump;
	dlocal vveddump, vedediting, vedargument = nullstring;
	ved_mcm();
	vedmarkfind();
	until vedatend() or vvedlinesize == 0 do vedchardown() enduntil;
	vedmarklo();
	ved_copy();
	vveddump -> dump;
	false -> vedediting;
	proc();
	until vedatend() or vvedlinesize == 0 do vedchardown() enduntil;
	dump -> vveddump;
	ved_y();
	vedchardown();;
	ved_mcm();
	vedmarklo();
	unless arg = nullstring then
		;;; use arg to set 'quotation indicator'
		'gsr/@a/' <> arg <> ' /' -> commandstring
	endunless;
	veddo(commandstring);
	ved_mcm();
	vedpositionpush();
	vedendrange();
	;;; add a line
	vedlinebelow();
	;;; unmark new line
	vedcharup(); vedmarkhi();
	;;; go back
	vedpositionpop();

	;;; move range off From line
	vvedmarklo+1 -> vvedmarklo;
	chain(vedrefresh);
enddefine;

define global ved_respond = vedrespond(%ved_reply%)
enddefine;

define global ved_Respond = vedrespond(%ved_Reply%)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  7 2009
		add unmarked blank line at end of new message, to avoid
		marked range commands affecting next message.
--- Aaron Sloman, Aug  2 2003
	Made to cal ved_mcm at end
--- Aaron Sloman, Jul 11 1992
	Changed to allow vedargument to give indentation sign instead of
	alternative file
 */
