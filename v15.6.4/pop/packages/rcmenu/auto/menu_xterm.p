/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/auto/menu_xterm.p
 > Originally:      local/menu/auto/menu_xterm.p
 > Purpose:         Create a new xterm window and run a program
 > Author:          Aaron Sloman, Aug 25 1993
 > 			With suggestions from John Gibson and Roger Evans
 > Documentation:	HELP * VED_MENU
 > Related Files:	LIB * VED_MENU
 */

/*
menu_xterm(name, command);

	The name is false or a string which is a machine name.
	The command is a shell string to be given after the "-e" flag to xterm.

If this command is run with a specified machine name then
an "rsh" process running on that machine is started and xterm is
run there with 'command' as the the command to be run in the xterm
window.

If the name is false, then an xterm window is started on the current
machine and the command run in it.
*/

section;

define global menu_xterm(name, command);
    lvars name, command, display = systranslate('DISPLAY');

    if isstring(name) then

    	if isstartstring(':', display) then
        	sys_host_name() <> display -> display
    	endif;

		[display ^display]=>

		'xterm -e rlogin ' <> name <> ' &'
/*
       	'/usr/ucb/rsh ' <> name <>
		' xterm -d ' <> display <> ' -e ' <> command <> ' &'
*/

	else

		'echo "xterm -e ' <> command <>
		'&" | csh -i > /dev/null'

    endif -> command;

	vedscreencooked();      ;;; set terminal mode normal
	vedscreengraphoff();	;;; in case of error messages
    sysobey(command);		;;; do it
	syssleep(150);			;;; pause before restoring terminal mode
	vedscreenraw();
enddefine;

endsection;

 /*

 ;;; test it. Start a new window with a VED file
 define ved_tved;
     menu_xterm(false, 'teach ' <> vedargument)
 enddefine;

*/
