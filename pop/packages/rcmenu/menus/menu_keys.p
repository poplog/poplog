/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_keys.p
 > Purpose:			menu panel with information about keys
 > Author:          Aaron Sloman, Aug 25 1999 (see revisions)
 > Documentation:
 > Related Files:
 */


/*
-- Facilities for getting information about keys
*/

uses rcmenulib
uses menu_new_menu

uses menu_do_scroll

uses ved_menu_hkey

section;
sysunprotect("vedinvedprocess");

define lconstant ved_hkeytest();
	dlocal vedusewindows;

    ved_try_do_??('ved_hkey', false);
	vedtopfile();
	vedlineabove();
	vedinsertstring('Interrupt with CTRL C when finished');
	vedendfile();
	vedcheck();
	vedxrefresh();
	ved_menu_hkey();
	repeat
		vedendfile();
		vedcheck();
		vedxrefresh();
		ved_menu_hkey()
	endrepeat;
enddefine;


define lconstant ved_testkeys();
	;;; Put up an information panel
	;;; Repeatedly call ved_hkey, until interrupted.

	lvars oldinterrupt = interrupt;

	lvars box;

	define dlocal interrupt();
		rc_kill_window_object(box);
		vedputmessage('DONE');
		oldinterrupt();
	enddefine;

	define :menu keys_inform;
		'TESTKEYS'
		{right top}
		{cols 1}
		'Move mouse cursor into'
		'temporary VED window'
		'Repeatedly press keys'
		'to get information.'
		'Interrupt with CTRL C'
		'or press FINISH'
		['FINISH' [POPNOW interrupt()]]
	enddefine;


	rc_current_window_object -> box;

	ved_hkeytest();

enddefine;

define :menu keys;
 'Ved Keys'
	'Information'
	'About' 'VED Keys'
	;;; this does not work well, so comment it out
	;;; ['Testkeys' ^ved_testkeys]
	['Test Key' 'menu_hkey']
	['QuitFile' ved_q]
	['PageUp' [POPNOW vedprevscreen()]]
	['PageDown' [POPNOW vednextscreen()]]
	['HalfUp' [POPNOW menu_do_scroll(-1, "vert")]]
	['HalfDown' [POPNOW menu_do_scroll(1, "vert")]]
	['Help Keys' 'help vedncdxtermkeys']  	
	;;; ['Help Sun4Keys' 'help vedsunxtermkeys']
	['HELP vedkeys' 'help vedkeys']
	['HELP DefKey' 'help DK']
	['HELP vedsetkey' 'help vedsetkey']
	['HELP vedset' 'help vedset']
	['HELP VED' 'help ved']
	['HELP EmacsKeys' 'help vedemacs']
	['REF VedComms' 'ref vedcomms']
	['REF Vedprocs' 'ref vedprocs']
	['Editor...' [MENU editor]]
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 17 1999
	made to work with rcmenu stuff
--- Aaron Sloman, Aug 25 1999
	Converted to use RC stuff, and content revised.
 */
