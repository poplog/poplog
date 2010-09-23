/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > Purpose:         Easy font changes, and related activities
 > File:            $poplocal/local/menu/menus/menu_xvedfonts.p
 > Author:          Aaron Sloman, Oct  1 1998
 > Documentation:	
 > Related Files:   HELP * VED_WINDOW, REF * XVED
 */


section;

uses menu_xved_utils;

define global vars procedure menu_window_changesize(amount);
	;;; also in menu nudge. Should move out
	;;; Vary screensize by amount. XVED only
	lvars amount;
	returnunless(vedusewindows == "x")(vedsetwindow());
	dlocal vedwarpcontext = false;
	vedscreenlength + amount -> xved_value("currentWindow", "numRows");
	false -> wvedwindowchanged
enddefine;

define :menu xvedfonts;
   'XVEDFONTS Menu'
	{cols 2}
	'Menu xvedfonts'
	'Xved font and size options'
	['Font 12x24' 'window font 12x24']
	['Default 12x24' 'window default font 12x24']
	['Font 10x20' 'window font 10x20']
	['Default 10x20' 'window default font 10x20']
	['Font 9x15' 'window font 9x15']
	['Default 9x15' 'window default font 9x15']
	['Font 8x13' 'window font 8x13']
	['Default 8x13' 'window default font 8x13']
	['Font 6x12' 'window font 6x12']
	['Default 6x12' 'window default font 6x12']
	['10 lines' 'window 10']
	['20 lines' 'window 20']
	['30 lines' 'window 30']
	['40 lines' 'window 40']
	['Smaller' [POPNOW menu_window_changesize(-2)]]
	['Bigger' [POPNOW menu_window_changesize(2)]]
	['NudgeUp' [POPNOW menu_xved_nudge("u")]]
	['NudgeDown' [POPNOW menu_xved_nudge("d")]]
	['NudgeLeft' [POPNOW menu_xved_nudge("l")]]
	['NudgeRight' [POPNOW menu_xved_nudge("r")]]
	['NudgeMenu' [MENU nudge]]
	['XVED menu' [MENU xved]]
	['HELP WINDOW' 'menu_doc help ved_window']
	['HELP XVED' 'menu_doc help xved']
	['TEACH XVED' 'menu_doc teach xved']
	['REF XVED' 'menu_doc ref xved']
	['MENUS...' [MENU toplevel]]
enddefine;

endsection;
