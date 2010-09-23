/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_lastmail.p
 > Purpose:			Alternative to ved_mail for reading mail
 > Author:          Aaron Sloman, Nov 24 1991 (see revisions)
 > Documentation: 	HELP * VED_GETMAIL
 > Related Files:	LIB * VED_NEXTMAIL, * VED_PREVMAIL

 */

uses sysdefs;		;;; used to locate the default mail directory

uses sys_file_exists;

uses ved_getmail;

section;

define ved_lastmail();
	;;; Get last mail file

	lvars dev, outfile, count = 1, lastfile;

	if vedusewindows == "x" then
		dlocal vedediting = true;
	endif;

	vedsetup();

	;;; Get name of next file to use for new mail.
	;;; The form is vedmailfile followed by number.
	setup_vedmailfile();

	vedmailfile sys_>< 1 -> lastfile;
	;;; find which number to append to vedmailfile
	repeat
		vedmailfile sys_>< count -> outfile;
	quitunless(sys_file_exists(outfile));
		outfile -> lastfile;
		count + 1 -> count;
	endrepeat;

	;;; if not in editor, then prepare commands to make index
 	unless vedediting or vedargument = '-' then
 		vedinput(vedskipheaders <> ved_mdir);
 	endunless;

	if vedargument = 'q' then
		vedqget(edit(%lastfile%));
	else
		edit(lastfile);
	endif;

	;;; if already editing, then make index
	if vedediting and vedargument /= '-' then
		vedskipheaders();
		ved_mdir()
	endif;

enddefine;


define global vars syntax lastmail = popvedcommand(%"ved_lastmail"%) enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  4 1997
	Added "-" option to suppress creation of index
--- Aaron Sloman, Mar 22 1992
	added "q" option
 */
