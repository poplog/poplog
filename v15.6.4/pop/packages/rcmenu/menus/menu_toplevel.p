/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_toplevel.p
 > Purpose:         Top level menu
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:	HELP VED_MENU, HELP RCLIB
 > Related Files:	LIB rcmenulib
 */

/*
-- The top level menu
*/

uses rcmenulib

uses menu_do_scroll


define :menu toplevel;
	'Toplevel'
	menu_toplevel_location
	{cols 1}
	
	 'Toplevel'
	['TUTOR' 'teach quickved']
	['ExitAll' 'qq']
	['TEACH...' [MENU teach]]
	;;; ['TEACH EMAIL' 'teach email']
	;;; next one no longer needed for Xved
	;;; ['WindowSize' ved_setwindow]
	['PageUP' vedprevscreen]
	['PageDown' vednextscreen]
	['HalfUp' [POP11 menu_do_scroll(-1, "vert")]]
	['HalfDown' [POP11 menu_do_scroll(1, "vert")]]
	['GoSection' 'g']
	['ENTER' [POP11 vedenter();vedrefreshstatus()]]
	['Editor(Ved)...' [MENU editor]]
	['XVED...' [MENU xved]]
	['Marking...' [MENU mark]]
	['Compiling...' [MENU compiling]]
	['Move...' [MENU move]]
	['Delete...' [MENU delete]]
	['Mail...' [MENU mail]]
	['Utilities...' [MENU utilities]]
	['UserMenu...' [MENU user]]
	['KeysInfo...' [MENU keys]]
;;;	['TUTORIAL' 'teach ved_menu']
	['UNIX...'	[MENU unix]]
	{blob DismissAll menu_dismiss_all}
enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 22 2000
	Changed to use menu_toplevel_location
--- Aaron Sloman, Sep 17 1999
	Replaced news with unix
	Removed email, and moved TEACH to the top.
--- Aaron Sloman, Aug 19 1999
	Added scrollup and scrolldown options
--- Aaron Sloman, Aug 10 1999
	Altered to use new rclib facilities
--- Aaron Sloman, Oct  1 1998
	Added XVED menu
--- Aaron Sloman, Jan 22 1997
	Added link to key menu
 */
