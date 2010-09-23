/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_getmail.p
 > Purpose:			Alternative to ved_mail for reading mail
 > Author:          Aaron Sloman, Nov 24 1991 (see revisions)
 > Documentation: 	TEACH * EMAIL, HELP * VED_GETMAIL
 > Related Files:	LIB * GETMAIL

 */

uses sysdefs;		;;; used to locate the default mail directory

section;

global vars
	vedmailfile,		;;; Name of mail files, with number suffixes
						;;; defaults to $HOME/mail, belwo
	vedmailbox,			;;; Where incoming mail is kept

	vedmailmax,			;;; Preferred approximate maximum size of mail file.

	vedautosaving, 		;;; defined in LIB ved_autosave
;

unless isinteger(vedmailmax) then
	;;;	60000 -> vedmailmax
	;;; the default is not to merge old and new mail
	0 -> vedmailmax
endunless;

;;; @@@@@@@ N.B. This assignment may need to be changed @@@@@@@

global vars sys_mail_dir;
unless isstring(sys_mail_dir) then
#_IF hd(sys_machine_type) == "alpha"
	'/var/spool/mail/'
#_ELSEIF DEF BERKELEY
	'/usr/spool/mail/'
#_ELSE
	'/var/mail/'
#_ENDIF
	 -> sys_mail_dir
endunless;

lconstant sizevec=initv(1);

define lconstant procedure ved_mail_waiting -> (mailfile, size);
	;;; cribbed from LIB VED_MAIL
	;;; If there's mail waiting, return pathname for the file, or false

	if isstring(vedmailbox) then vedmailbox
	else systranslate('MAIL')
	endif -> mailfile;

	unless mailfile then
		;;; Check system mail file
		sys_mail_dir dir_>< popusername -> mailfile;
	endunless;
	;;; check if it exists, and is non-empty
	unless sys_file_stat(mailfile, sizevec) and (fast_subscrv(1, sizevec) ->> size) > 0
	then
		false -> mailfile
	endunless;
enddefine;



define setup_vedmailfile();
	;;; used in lib ved_prevmail, etc.
	unless isstring(vedmailfile) then
		;;; not defined in user's vedinit.p, so
		'$HOME/mail' -> vedmailfile
	endunless;
	sysfileok(vedmailfile) -> vedmailfile;
enddefine;


define ved_getmail();
	;;; Copy new mail from mailbox to next mail file and read it in.

	dlocal
		;;; turn of autosaving while reading files.
		vedautosaving = false,
		;;; expand error messages
		popsyscall = true;

	lconstant From_string = 'From ';

	lvars
		dev, outfile,
		mailmerged = false,
		count = 1,
		mailbox, mailboxsize,
		newmail_divider = '%%%%%%%%%%%% NEW MAIL ' <> sysdaytime(),
		lastmailfile = false, lastmailsize = 0,
		noindex = vedargument = '-';

	nullstring -> vedargument;

	if vedusewindows == "x" then
		dlocal vedediting = true;
	endif;

	ved_mail_waiting() -> (mailbox, mailboxsize);

	if mailbox then
		vedsetup();
		;;; write all files, as a precaution
		ved_w();

		;;; Get name of next file to use for new mail.
		;;; The form is vedmailfile followed by number.
		setup_vedmailfile();

		;;; find which number to append to vedmailfile
		repeat
			vedmailfile sys_>< count -> outfile;
		quitunless(sys_file_exists(outfile));
			outfile -> lastmailfile;
			count + 1 -> count;
		endrepeat;

		if lastmailfile then
			sysfilesize(lastmailfile) -> lastmailsize;
    	endif;

#_IF DEF BOBCAT
		;;; Users cannot delete their own mailboxes. So
		;;; use slightly risky alternative. Copy it and then
		;;; empty it. NOT SAFE
		sysobey('cp ' <> mailbox <> ' ' <> outfile, `$`);
		sysobey('cp /dev/null ' <> mailbox, `$`);
#_ELSE
		;;; Previous version reinstated empty mail box. Probably no longer needed.
		;;; sysobey('mv ' <> mailbox <> ' ' <> outfile <> ';umask 77;touch ' <> mailbox, `$`);
		sysobey('mv ' <> mailbox <> ' ' <> outfile, `$`);
#_ENDIF

		;;; now check whether to merge the last two files.

		if lastmailfile and pop_status == 0 	;;; success
		and not(vedpresent(lastmailfile))
		and sys_file_exists(outfile)
		and lastmailsize + mailboxsize < vedmailmax
			
		then
			;;; merge new and old files
			vedputmessage('Mergeing new mail with ' <> lastmailfile);


			;;; Give shell command to append "divider" line and new message
			;;; to the last mail file
			;;; First the divider line
			sysobey(
				'(echo ""; echo ""; echo "' <> newmail_divider <> '"; echo "") >> ' <> lastmailfile, `$`);
			;;; Now append the mail file
			sysobey('cat ' <> outfile <> ' >> ' <> lastmailfile, `$`);

			;;; check whether to delete the temporary file
			if sysfilesize(lastmailfile) >= lastmailsize + sysfilesize(outfile) then
				sysobey('rm ' <> outfile, `$`);
				vedputmessage('Old and new mail merged');
				lastmailfile -> outfile;
			else
				vedputmessage('Problem: some mail saved in ' <> lastmailfile);
				syssleep(5);
			endif;
			true -> mailmerged;
		endif;

		;;; Now edit the file, but first write current files, as a precaution
		ved_w();
		edit(outfile);
		if lastmailfile == outfile then
			vedendfile();
            ved_check_search(newmail_divider, [back nowrap]);
			vedcheck();
			vednextline();
			vednextline();
		endif;

		if vedediting then

			;;; Check format of file, unless it's a merged file, or empty
			unless mailmerged or vvedbuffersize == 0
			or isstartstring(From_string, vedbuffer(1))
			then
				vederror('NOT A STANDARD UNIX MAIL FILE. See HELP VED_GETMAIL/prepare')
			endunless;

			unless not(lastmailfile) or lastmailfile == outfile then
				;;; If you are editing a mail file and it is small enough to have the
				;;; new mail file appended, merge the new mail file
				if vedpresent(lastmailfile)
					and lastmailsize + mailboxsize < vedmailmax then
					valof("ved_mergemail")();	;;; use valof to postpone autoloading
					;;; Insert mail divider
					vedlinebelow();
					false -> vedbreak;
					vedinsertstring(newmail_divider);
					vedinsertstring(' (@@@  MAIL FILES MERGED  @@@)');
					true -> vedbreak;
					vedlinebelow();
					;;; to to begining of message
					until vedatend() or vvedlinesize /== 0 do vedchardown() enduntil;
				else
					vedskipheaders();
				endif;
			endunless;
			unless noindex then
				ved_mdir();
				vedputcommand('gm');
				vedputmessage('PUT CURSOR AGAINST DESIRED NUMBER AND TYPE: ENTER gm')
			endunless;
		endif
	else
			vedputmessage('NO NEW MAIL. Use "<ENTER> lastmail" to read previous mail');
	endif;
enddefine;


define global vars syntax getmail = popvedcommand(%"ved_getmail"%) enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 29 2000
		Make sure to write everything before reading in mail file.
--- Aaron Sloman, Nov 28 1998
		Changed so as not to "touch" system mail file
--- Aaron Sloman, Oct 18 1998
		Separated getmail.p file
--- Aaron Sloman, Jan 31 1997
		Fixed to allow "-" flag to disable mdir
--- Aaron Sloman, Jan 19 1997
		Fixed to check last mail file size properly
--- Aaron Sloman, Jan 14 1997
	Introduced vedmailmax and the option to merge old and new
		mail files.
--- Aaron Sloman, Feb 14 1994
	Altered solaris version to be like HP-UX
--- Aaron Sloman, Oct 16 1992
	Revised to cope with problems on HP-UX - could not use "mv"
	to move mail file. Must first "cp" then cp /dev/null to the file.
 */
