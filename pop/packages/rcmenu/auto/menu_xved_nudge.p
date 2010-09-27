/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_xved_nudge.p
 > Purpose:         Nudging an XVED window to move
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
This file includes modified versions of some utilities provided
by Jon Meyer for shifting the XVED window left, right, up or down.
They can be bound to keys if desired. For now they are used only by
the xved menu.

menu_xved_nudge takes a word as input, namely "u", "d", "l", or "r".
*/

section;

;;; A user-settable control variable.
global vars menu_nudge_factor = 25;


section $-xved => menu_xved_nudge;


define constant menu_xved_subnudge(axis, direction);
	lvars axis, procedure direction, had_mouse;

	xvedwarpmouse and xved_window_has_mouse(wvedwindow) == true -> had_mouse;

	direction( xved_value("currentWindow", axis), menu_nudge_factor)
		-> xved_value("currentWindow", axis);

	if had_mouse and xved_window_has_mouse(wvedwindow) /== true then
		xved_x_warp_pointer(wvedwindow, "inside");
	endif
enddefine;

define menu_xved_nudge(dir);
	lvars dir;
	menu_xved_subnudge(
		if dir == "u" then "y", nonop -
		elseif dir == "d" then "y", nonop +
		elseif dir == "l" then "x", nonop -
		elseif dir == "r" then "x", nonop +
		else
			mishap('UNKOWN NUDGE DIRECTION', [^dir])
		endif)
enddefine;

endsection;



endsection;
