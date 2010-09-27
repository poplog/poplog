/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_mergemail.p
 > Purpose:         Merge current mail file with previous one (at end)
 > Author:          Aaron Sloman, Feb  6 1992 (see revisions)
 > Documentation:	HELP * VED_GETMAIL
 > Related Files:	LIB * VED_GETMAIL
 */

;;; LIB VED_MERGEMAIL                                        A.Sloman Nov 1991
;;; See LIB * VED_GETMAIL, HELP * VED_GETMAIL


uses ved_getmail

section;

define lconstant checkmailfile();
	;;; Add prefix for automounted directories.
	lconstant tmp_mnt = '/tmp_mnt';
	unless isstartstring(vedmailfile, vedpathname)
	or isstartstring(tmp_mnt dir_>< vedmailfile, vedpathname)
	then
		vederror('NOT IN MAIL FILE')
	endunless;
enddefine;

define lconstant mergemail(num);
	;;; Veddebug('mergemail ' >< num);

	lvars oldfile = vedcurrentfile, empty = vvedbuffersize == 0;

	if (vedmailfile sys_>< '1') = vedpathname then
		vederror('AT FIRST MAIL FILE')
	endif;

	;;; Next procedure defined in ved_getmail
	setup_vedmailfile();
	checkmailfile();
	unless empty then
		;;; Mark whole file and copy it
		ved_mbe();
		ved_copy();
	endunless;
	;;; Get previous mail file and yank in the copied file
	ved_prevmail();
	if vedonstatus then vedswitchstatus() endif;
	vedendfile();
	unless empty then
		ved_y();
		ved_w1();
		vedputmessage(vedpathname <> ' WRITTEN')
	endunless;
	;;; go back and delete the other file
	vedswapfiles();
	if vedcurrentfile == oldfile then
		veddo('deletefile');
	else
		vederror('SOMETHING WRONG, CHECK ALL FILES')
	endif;

	if num > 1 then
		mergemail(num - 1)
	endif;
enddefine;


define global ved_mergemail();
	lvars arg = strnumber(vedargument);

	dlocal vedargument = nullstring;

	mergemail(if arg then arg else 1 endif)
	
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  9 1996
	Changed to allow an argument
		ENTER mergemail N
		Merges N mail files (stops at mail1).
--- Aaron Sloman, May  8 1992
	Made to write merged file immediately
 */
