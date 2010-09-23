/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rcmenu/menus/menu_utilities.p
 > Purpose:			Sample menu panel with utilities
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

/*

-- Utilities menu

A menu to access several other utilities menus

*/
section;

uses rcmenulib

uses menu_choosefile2


define :menu utilities;
	'Utilities'
	'Menu utilities'
	'Available in'
	'Ved and Xved'
	['XVED...' [MENU xved]]
	['TextBlocks...' [MENU vedblocks]]
	;;; ['NudgeMenu...' [MENU nudge]]
    ['Browser*' menu_choosefile2]
	['ReadMail...' [MENU mail1]]
	['SendMail...' [MENU mail2]]
    ['Usenet(News)...' [MENU news]]
	['Print...' [MENU print]]
	['Control...' [MENU control]]
	['Latex...' [MENU latex]]
	['UNIX...' [MENU unix]]
	['UserMenu...' [MENU user]]
	['Autosave*'
		[ENTER 'autosave 5'
		['Get VED to save all files, e.g. every 5 minutes']]]
	['HELP Autosave' 'help ved_autosave']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 26 1999
	Converted to use rcmenus
 */
