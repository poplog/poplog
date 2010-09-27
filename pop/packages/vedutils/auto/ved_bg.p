/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_bg.p
 > Purpose:			Run a Unix command in the "background"
 > Author:          Aaron Sloman, Apr 27 1995 (see revisions)
 > Documentation: 	HELP * VED_BG
 > Related Files:
 */

section;

uses run_unix_program;

global vars ved_bg_shell = '/bin/csh';

define ved_bg();

	dlocal vedargument;

	if vedargument = vednullstring then
		;;; use unix command on current ved line
		vedthisline() -> vedargument
	endif;

	if vedargument = nullstring then
		vederror('No unix command provided')
	endif;

	lvars shell = systranslate('SHELL');

	unless shell then ved_bg_shell -> shell endunless;

	run_unix_program(shell, ['-ce' ^vedargument], false, false, false, false)
		 -> ->  ->  ->  -> ;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 24 1999
	If no argument given, use current vedline
 */
