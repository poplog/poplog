/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/menus/menu_nudge.p
 > Purpose:
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
-- Nudge menu moving or re-sizing an XVED window
*/

section;

uses menu_xved_utils

define global vars procedure menu_window_changesize(amount);
	;;; Vary screensize by amount. XVED only
	lvars amount;
	returnunless(vedusewindows == "x")(vedsetwindow());
	dlocal vedwarpcontext = false;
	vedscreenlength + amount -> xved_value("currentWindow", "numRows");
	false -> wvedwindowchanged
enddefine;

define :menu nudge;
	'X Window nudge menu'
	{-80 20}
	{fg 'yellow'}
	{bg 'brown'}
	{cols 0}
	['Up' [POPNOW menu_xved_nudge("u")]]
	['Down' [POPNOW menu_xved_nudge("d")]]
	['Left' [POPNOW menu_xved_nudge("l")]]
	['Right' [POPNOW menu_xved_nudge("r")]]
	['Smaller' [POPNOW menu_window_changesize(-5)]]
	['Bigger' [POPNOW menu_window_changesize(5)]]
;;;	['HELP' 'help xved']
enddefine;

endsection;
