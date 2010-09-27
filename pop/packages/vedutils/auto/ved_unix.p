/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_unix.p
 > Purpose:         Give a Unix command on VED's command line
 > Author:          Aaron Sloman, Sep 28 1994 (see revisions)
 > Documentation:	HELP * VED_UNIX
 > Related Files:	LIB * VED_BG, LIB * VED_SH, VED_CSH
 */


section;


global vars ved_default_shell = '/bin/csh';


define ved_unix();
	;;; Run the user's shell with the arguments
	lvars shell = systranslate('SHELL');

	unless shell then ved_default_shell -> shell endunless;

	dlocal vedargument;

	;;; E.g. '/bin/csh' 'csh ' >< vedargument
	if vedargument = vednullstring then
		;;; use unix command on current ved line
		vedthisline() -> vedargument
	endif;

	if vedargument = nullstring then
		vederror('No unix command provided')
	endif;

	vedgenshell(shell, sys_fname_nam(shell) sys_>< space sys_>< vedargument)

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 24 1999
	changed so that if there's no argument, it takes its argument
	from the command line
--- Aaron Sloman, Nov 11 1995
	Changed to respect the User's $SHELL variable
 */
