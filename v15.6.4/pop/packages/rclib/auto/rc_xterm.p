/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_xterm.p
 > Purpose:			Prompt for a command to run in an xterm window
 > Author:          Aaron Sloman, May  9 1999
 > Documentation:	
 > Related Files:	
 */

/*
;;; test it
rc_xterm(800, 50);
*/


compile_mode :pop11 +strict;

section;

uses rclib;

define rc_xterm(x, y);
	lvars location;
	;;; Ask for an interactive shell command and then run an xterm
	;;; window with that command

	lvars command =
	rc_getinput(x, y, ['Type a Unix command' 'to run under xterm'],'', [],'XTERM?');

	if command = nullstring then
		;;; just run an xterm window
		'echo "xterm &" | csh -i > /dev/null' -> command;
	else
		'echo "xterm -e ' <> command <> '&" | csh -i > /dev/null' -> command;
	endif;

	vedscreencooked();      ;;; set terminal mode normal
	vedscreengraphoff();	;;; in case of error messages
    sysobey(command);		;;; do it
	syssleep(150);			;;; pause before restoring terminal mode
	vedscreenraw();
enddefine;

endsection;
