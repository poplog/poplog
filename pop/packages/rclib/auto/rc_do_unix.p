/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_do_unix.p
 > Purpose:			Get a unix command from user, and run it
 > Author:          Aaron Sloman, May  9 1999
 > Documentation:
 > Related Files:	LIB * rc_popup_panel, * ved_csh, * veddo
 */

/*
TEST

rc_do_unix(400,200);

*/


compile_mode :pop11 +strict;

section;

uses rclib
uses rc_getinput;

global
    vars rc_shell = 'csh',     ;;; user assignable

    show_output_on_status,      ;;; used by vedpipein, vedgenshell
	;

define global rc_do_unix(x, y);
	lvars string;

     ;;; Ensure all error messages, one line responses etc. appear in
     ;;; a new VED window. See HELP * PIPEUTILS
	dlocal show_output_on_status = false;

	;;; Prompt for a unix shell command
	rc_getinput(x, y, ['Type a Unix command please'],'',[{width 300}], 'UnixCommand')
		-> string;

	if string then
		;;; Run the command via ved_csh (which runs vedgenshell).
		veddo( rc_shell <> ' ' <> string, true);
	endif;
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 20 1995
	Introduced rc_shell
 */
