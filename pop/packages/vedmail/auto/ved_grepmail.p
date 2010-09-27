/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_grepmail.p
 > Purpose:			Search through mail files for given string
 > Author:          Aaron Sloman, Oct 10 1992 (see revisions)
 > Documentation:	HELP * VED_GETMAIL (eventually)
 > Related Files:	LIB * VED_GREP, * VED_GETMAIL
 */

/*

ENTER grepmail <search string> <pattern>
ENTER grepmail <flags> <search string> <pattern>

The <flags> if given will be strings preceded by "-" intended as
arguments for grep. If <flags> is empty then <flags> defaults to
"-i" so that case is ignored. If you wish to use only EXACT matches
then give the flag "-e".

The search string may consist of several words separated by spaces.
The pattern must consist of at least "*", meaning search through ALL
mail files, or may be something more specific, e.g. "3?" which will
mean search through all mail files numbered 30 through to 39.

Example: to search for a mention of president bush through all mail
files numbered between 10 and 99

	ENTER grepmail president bush ??

Example: To search all mail files for the surname "Read" but not
occurrences of the word "read"

	ENTER grepmail -e Read *

*/

;;; lib ved_grepmail.p                           Sun Apr  5 17:53:30 BST 1992
procedure();

	;;; recompile vedgenshell
	dlocal pop_debugging = true;
	loadlib("vedgenshell");

endprocedure();

uses ved_getmail
section;

define global ved_grepmail();
	lvars grepstring, pattern_suffix, loc, nextloc, flags,
		oldfile = vedcurrentfile, oldediting = vedediting;

	dlocal
		show_output_on_status = false,
		vedediting; 	;;; temporarily made false, below

	;;; Find where the pattern starts. Search back for last space
	locchar_back(`\s`, 9999, vedargument) -> loc;
	unless loc then vederror ('NOT ENOUGH ARGUMENTS') endunless;

	if vedwriteable then
		ved_w1();	;;; precaution against bugs
	endif;

	;;; find the search string for grep
	substring(1, loc - 1, vedargument) -> grepstring;
	;;; and the pattern to append to vedmailfile
	allbutfirst(loc, vedargument) -> pattern_suffix;

	;;; see if there are any flags for grep in grepstring, and separate them
	1 -> loc;
	while subscrs(loc, grepstring) == `-` do
		locchar(`\s`, loc + 1, grepstring) -> nextloc;
		if nextloc then skipchar(`\s`, nextloc + 1, grepstring) -> nextloc endif;
		if nextloc then nextloc -> loc endif;
	endwhile;
	if loc == 1 then
		;;; no flags, default to ignore case
		'-i' -> flags
	else
		;;; remove flags
		substring(1, loc - 1 , grepstring) -> flags;
		allbutfirst(loc - 1, grepstring) -> grepstring ;
		;;; check for exact match required, i.e. not caseless.
		if isstartstring('-e ', flags) then false -> flags endif;
	endif;

	setup_vedmailfile();	;;; make sure vedmailfile is set up
	lvars oldtime = sys_real_time();
	;;; false -> vedediting;
	
	veddo(
		concat_strings(
			{'sh grep '
				^(if flags  then flags, ' ' endif)
				^grepstring ' '
				^vedmailfile  ^pattern_suffix}));

	lvars newtime = sys_real_time() - oldtime;

	if oldfile == vedcurrentfile then
		;;; found nothing
		vedputmessage('Nothing found');
	else
		;;; found something, in new VED buffer.
		;;; Shorten file names
		;;; Get path name till just before mail directory and remove all
		;;; occurrences
		lvars mailpath =
			sys_fname_path(allbutlast(1, sys_fname_path(vedmailfile)));
		;;;veddebug(mailpath);
		;;; delete pathname down to mail directory
		false -> vedediting;
		veddo('sgs&@a'<>mailpath<>'&&');

/*
		;;; Replace colons after file name with space
		dlocal vedstatic = true;
		lblock
				lvars line, loc,
				startloc = datalength(vedmailfile) - datalength(mailpath) + 1;
			for line from 1 to vvedbuffersize do
				if locchar(`:`, startloc, subscrv(line,vedbuffer)) ->> loc then
					vedjumpto(line, loc);
					veddotdelete();
				endif
			endfor
		endlblock;
*/

		vedjumpto(1,1);
		;;; Uncomment for timing purposes
		;;; vedlineabove();vedinsertstring('Time ' >< newtime);
		vedcheck();
		oldediting -> vedediting;
		vedsetonscreen(ved_current_file, false);
		vedputcommand('getit');
		if vedediting then vedrefresh(); endif;
	endif
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 10 1999
	Removed false -> vedediting;
	Made show_output_on_status false
--- Aaron Sloman, Oct 18 1999
	Restored vedrefresh
--- Aaron Sloman, Oct 10 1999
	Added 'Nothing found message'
--- Aaron Sloman, Jul  8 1999
	minor fixes, including preventing problems due to unusual
	sequence of compilation.
--- Aaron Sloman, Oct 16 1995
	Removed unnecessary quotes as ved_grep now does what's needed.
	Enables use of "|" for disjunctive search.

	Fixed to allow -e flag
 */
