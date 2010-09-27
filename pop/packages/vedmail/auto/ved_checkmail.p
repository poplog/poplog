/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_checkmail.p
 > Purpose:			Check whether you have any new mail
 > Author:          Aaron Sloman, Feb  6 1992 (see revisions)
 > Documentation:	HELP * VED_CHECKMAIL, HELP * VED_GETMAIL
 > Related Files:	LIB * VED_GETMAIL
 */

/*
HELP VED_CHECKMAIL                                     A.Sloman feb 1992

This utility uses the global variable ved_checkmail_filename if the
user has assigned a string to it, otherwise it uses the value of
the environment variable $MAIL to tell where to look for mail.

The VED command

	ENTER checkmail
		tells you whether you have mail waiting to be read, and turns
		on checking every 60 seconds

	ENTER checkmail 30
		re-sets the checking to occur every 30 seconds

	ENTER checkmail off
		turns off checking

See also
HELP VED_GETMAIL
*/


;;; Makes use of sys_timer

compile_mode:pop11 +strict;

section;

global vars

    ved_checkmail_filename,     ;;; file to be checked

	ved_checkmail_lines , 	;;; number of lines of information to show
;

unless isinteger(ved_checkmail_lines) then
	12 -> ved_checkmail_lines
endunless;

;;; File local global lvars
lvars
	lastlookatmail = false,		;;; time when mail was last looked at
    checkmail_interval = 60,    ;;; default interval =  60 secs
	in_a_read = false,			;;; set true if inside charin
;


define lconstant setup_filename();
	unless isstring(ved_checkmail_filename) then
		;;; This should be done only the first time
	    sysfileok('$MAIL') -> ved_checkmail_filename
	endunless;
	unless lastlookatmail then
		sys_real_time() -> lastlookatmail
	endunless;
enddefine;

define lconstant newmail_waiting();
    lvars bool;

	setup_filename();
    sys_file_exists(ved_checkmail_filename)
    and sysmodtime(ved_checkmail_filename) > lastlookatmail
	and sysfilesize(ved_checkmail_filename) > 0
enddefine;


define global vars vedcheckmail_action();
	;;; Check if there's new mail, and if so print out a summary of
	;;; recent messages (From: and Subject: lines.)
	;;; This is user definable.
	lvars string,
		rep =
			sys_obey_linerep('egrep \'^Subject: |^From: \' '
				sys_>< ved_checkmail_filename sys_>< ' | tail -'
					sys_>< ved_checkmail_lines);

	lconstant message = 'NEW MAIL HAS ARRIVED';

    vedscreenbell();

	lvars was_on_status = ved_on_status;

	;;; Open new temporary file for message summary
	vededit('/tmp/latest_messages', vedhelpdefaults);
	if ved_on_status then vedstatusswitch() endif;
	if vvedbuffersize > 0 then
		false -> vedediting;
		ved_clear();
		true -> vedediting;
		vedrefresh();
	endif;
    vedputmessage(message);
	dlocal vedbreak = false;
	vedinsertstring(message);
	repeat
		rep() -> string;
	quitif(string == termin);
		vedlinebelow();
		vedinsertstring(string);
	endrepeat;
	vedswapfiles();
	if was_on_status and not(ved_on_status) then
		vedstatusswitch()
	endif;
enddefine;


define lconstant vedset_checkmail(set);
	;;; the argument is true for setting the time, otherwise false,
	;;; for turning it off.
	lvars set;

	define lconstant checkmail;
		;;; Interrupt procedure run at intervals

		unless vedprintingdone
        or iscaller(vedrestorescreen)
        or (iscaller(charin) and vedusewindows /== "x")
        or ispair(ved_char_in_stream) or
            sys_input_waiting(popdevraw)
        then

    		if newmail_waiting() then
				if not(vedediting) or vedusewindows = "x" then
			        vedscreenbell();
			        vedputmessage('NEW MAIL HAS ARRIVED');
					if vedusewindows = "x" then
						vedinput
					else
						apply
					endif(vedcheckmail_action);
				else
					vedcheckmail_action()
				endif;
		        sysmodtime(ved_checkmail_filename) + 1 -> lastlookatmail;
				vedsetcursor();
    		endif;
        endunless;
		;;; re-set timer
		vedset_checkmail(true);
	enddefine;

	setup_filename();

	;;; turn off any previous setting;
	false -> sys_timer(checkmail);

	if set then
		round(checkmail_interval * 1e6) -> sys_timer(checkmail)
	endif

enddefine;


;;; Interrogate or set delay time for check_checkmail

define global vars active ved_checkmail_interval;
	checkmail_interval
enddefine;

define updaterof active ved_checkmail_interval;
	-> checkmail_interval;
	vedset_checkmail(true);
enddefine;


define global ved_checkmail;
	;;; For interactive setting of timer, or finding out interval.
	;;; If argument is "off" turns timing off.
	lvars time, mail_exists;

	setup_filename();

	if vedargument = 'off' then
		vedset_checkmail(false);
		vedputmessage('CHECKING TURNED OFF');
		return();
	endif;

	sys_file_exists(ved_checkmail_filename)
	and sysfilesize(ved_checkmail_filename) > 0
		-> mail_exists;

	vedset_checkmail(true);

	if strnumber(vedargument) ->> time then
		;;; reset timer
		time -> ved_checkmail_interval
	elseif vedargument = 'now' then
		if mail_exists then
			vedinput(vedcheckmail_action);
		else
			vedputmessage('NO MAIL')
		endif;
		return();
	else
		vedputmessage('Checking turned on. Interval in seconds: '
			sys_>< ved_checkmail_interval );
		return();
	endif;

	if mail_exists then
			vedinput(vedcheckmail_action);
	else
		vedputmessage( 'NO NEW MAIL' sys_><
			' (Interval is ' sys_><
			ved_checkmail_interval sys_>< ' Seconds.)')
	endif
enddefine;

;;; Initialise things if running interactively
if systrmdev(popdevin) then vedset_checkmail(true) endif;

;;; Ensure that saved images are initialised properly on startup
vedset_checkmail(%true%) <> pop_after_restore -> pop_after_restore;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr  7 1996
	Added ved_checkmail_lines
--- Aaron Sloman, 21 Feb 1995
		Made to avoid examining mail file when started by ENTER checkmail
		Instead do ENTER checkmail now
--- Aaron Sloman, 5th Jan 1993
	modified iscaller(charin) test for xved
--- Aaron Sloman, 4th Jan 1993
	Modified to show information about latest message.
--- Aaron Sloman, Apr 26 1992
	Modified so as not to say there's new mail when the mail file is
	empty. (E.g. in case you've read mail using mail)
 */
