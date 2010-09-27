/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_user.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
 -- -- User defined menu

Start this menu by
	ENTER menu user
or selecting UserMenu... from the top level menu

*/

section;
uses menu_xterm.p

define lconstant toggle_clock();
	;;; this must run in the right context
	if vedinvedprocess then
		veddo('clock');
	else
		vedinput(veddo(%'clock'%))
	endif;
enddefine;


;;; This can easily be redefined by users
;;; For more examples of possibly helpful user buttons see
;;; HELP Menubuttons

define :menu user ;
  	'UserMenu'
	{cols 2}
    'Menu user'
	'(To get a copy of this,'
	'select EdUserMenu.'
	'Edit then compile.)'
    [HELP 'menu_doc help ved_menu']
    [Refresh menu_refresh]
	;;; Run top on local machine. To run it remotely use full path name
	;;; e.g. menu_xterm('sun5' '/usr/local/bin/top')
    [TOP [POP11 menu_xterm(false, 'top')]]
    ['Xclock' [POP11 sysobey('xclock &')]]
	;;; The next one does not work in XVed if invoked from a menu
	['VedClock on/off' ^toggle_clock]
	['HELP Clock' 'help ved_clock']
    ['Eliza'
        [POP11 menu_xterm(false,'eliza')]]
	['Xved'
        [POP11 menu_xterm(false,'xved')]]
    ['Prolog'
        [POP11 menu_xterm(false,'prolog')]]
    ['Prolog tutor'
        [POP11 menu_xterm(false,'prolog +logic')]]
	;;; To create saved image for this run $usepop/pop/lib/demo/mkms
    ['Shrdlu'
        [POP11 menu_xterm(false,'pop11 +msblocks')]]
	;;; Start up a local xterm running tcsh (Edit for bash, etc.)
    ['LocalXterm'
        [POP11 menu_xterm(false, 'tcsh')]]
	;;; Get this file into VED and run the editor menu
    ['EditMenu' 'do;showmenu user;menu editor']
	;;; Make a user-owned copy of a system menu
    ['CopyMenu*'
        [ENTER 'copymenu <name>'
         [
			'To copy one of the system menus and make it'
			'your own, put the menu name in place of "<name>"'
			'in the command line below.'
			'Alternatively if you are already examining'
			'a menu file, give no <name>.'
			'Your \'vedmenus\' directory will be created,'
			'if necessary, and the menu copied into it.'
			'You can then edit it and load it'
			'with the "ENTER l1" command.']]]
	;;; Make a user-owned copy of this menu
    ['EdUserMenu' 'copymenu user']
	;;; Compile and rebuild the menu in the current file
    ['Compile' 'l1']
	['HELP menubuttons' 'help menubuttons']
	;;; Go back to top level menu
    ['MENUS...' [MENU toplevel]]
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 18 1999
	Converted for rcmenus
 */
