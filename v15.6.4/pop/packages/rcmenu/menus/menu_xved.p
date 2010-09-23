/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/menu/menus/menu_xved.p
 > Purpose:         Menu to help drive an XVED window
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:
 > Related Files:	MENU xvedfonts
 */

/*
-- Menu facilities to drive XVED

For reasons that I don't understand some of these work only in
	[POP11 <action>]
format


*/


section;

uses menu_xved_utils;

define :menu xved;
   'XVED Menu'
	'Menu xved'
	'Xved Options'
	['HELP ThisMenu' 'menu_doc help menu_xved']
	['PasteSelection' menu_clipboard_paste]
	['CopySelection' menu_clipboard_transcribe]
	['CutSelection' [POPNOW menu_clipboard_cut()]]
	['MoveSelection' [POPNOW menu_clipboard_move()]]
	['ClearSelection' menu_clipboard_clear]
	['UNDO???'	menu_clipboard_undo]
	['CompSelection' [POP11 menu_vedinput(menu_clipboard_compile)]]
	['NudgeUp' [POPNOW menu_xved_nudge("u")]]
	['NudgeDown' [POPNOW menu_xved_nudge("d")]]
	['NudgeLeft' [POPNOW menu_xved_nudge("l")]]
	['NudgeRight' [POPNOW menu_xved_nudge("r")]]
	['WindowSize' ved_setwindow]
	['NudgeMenu' [MENU nudge]]
	['XVED fonts' [MENU xvedfonts]]
	['HELP Selection' menu_clipboard_help]
	['HELP XVED' 'menu_doc help xved']
	['TEACH XVED' 'menu_doc teach xved']
	['REF XVED' 'menu_doc ref xved']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct  1 1998
	Added font menu
 */
