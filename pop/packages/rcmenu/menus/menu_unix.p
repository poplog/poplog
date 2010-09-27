/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_unix.p
 > Purpose:			Sample menu interface to Unix.
 > Author:          Aaron Sloman, Jul 22 2000 (see revisions)
 > Documentation:	HELP VED_MENU, RCLIB
 > Related Files:	LIB rcmenulib
 */

/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_unix.p
 > Author:          Aaron Sloman, Jan 21 1995
 */

 /*
-- A set of Unix commands
 */
section;
uses rcmenulib
uses ved_menu
uses menu_xterm.p

define :menu unix;
	'Unix Ops'
	{cols 1}
	;;; {font '6x13'}
	;;; {textbg 'brown'}
	;;; {textfg 'white'}
	{width 90}
	'Menu unix' 'See also \nUser Menu'
  	['Who' 'menu_doc sh who']
  	['MachineStatus' 'menu_doc sh w']
  	['LS Files*'
	 	[ENTER 'ls -ld *'
		 	'Get a long listing of files matching pattern\Edit the pattern']]
  	['Newest Files*'
	 	[ENTER 'ls -ltd *'
		 	'Get a long listing of files matching pattern'
		 	'with newest files shown first, oldest last']]
  	['ShellCommand*'
	 	[ENTER 'csh <command>'
		 	'Run an arbitrary C Shell command, and have'
			'The output read into a VED buffer']]

	;;; Re-design this portion?
	if readable('/usr/ucb/ps') then
	  	['MyProcs' 'sh /usr/ucb/ps -ux ']
	else
	  	['MyProcs' 'sh ps -fu $USER']
	endif;;;
	;;; this one may not be relevant to everyone	
    ['LocalXterm'
        [POP11 menu_xterm(false, 'csh')]]
	;;; This is an example: replace Lap and lap with some other
	;;; machine's name
    ['Xterm Lap'
        [POP11 menu_xterm('lap', 'csh')]]
  	['TopProcs' [POP11 menu_xterm(false,'top')]]
  	['DaliClock' [POP11 sysobey('xdaliclock &')]]
  	['XClock' [POP11 sysobey('xclock &')]]
  	['ListMail' [UNIX 'from']]
  	['Csh in Ved' 'imcsh']
  	['Sh in Ved' 'imsh']
  	['HELP pipeutils' 'menu_doc help pipeutils']
  	['MENUS...' [MENU toplevel]]
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 22 2000
	Slightly revised. Still quite arbitrary.
 */
