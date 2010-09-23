/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_foreground.p
 > linked to:       $poplocal/local/auto/rc_foreground.p
 > Purpose:         Get or set foreground of rc_graphic window
 > Author:          Aaron Sloman, Feb 13 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

uses rc_graphic;
/*

rc_start();
rc_foreground(rc_window) =>
5-> rc_linewidth;
rc_draw(30);
rc_turn(60);

'seagreen' -> rc_foreground(rc_window);
false -> rc_foreground(rc_window);
"background" -> rc_foreground(rc_window);
'red' -> rc_foreground(rc_window);
'lightblue' -> rc_foreground(rc_window);
'navyblue' -> rc_foreground(rc_window);
'black' -> rc_foreground(rc_window);

*/
compile_mode :pop11 +strict;
section;

global vars rc_foreground_changeable = true;

;;; cached value of foreground colour and mapping
lvars current_foreground = false, current_window = false,
	procedure colour_mapping = newmapping([], 32, false, false);

define global rc_foreground(window) /* -> colour */;
	rc_check_window(window);

	;;; window(XtN foreground) -> colour;
	;;; return current foreground
	if isinteger(current_foreground) ;;; and xt_islivewindow(current_window)
	and current_window == window
	then
		current_foreground
	else
		window -> current_window;
		XptVal[fast] window(XtN foreground:int) ->> current_foreground;
	endif /* -> colour */;
enddefine;

define updaterof rc_foreground(col, window);
	returnunless(rc_foreground_changeable);
	rc_check_window(window);
	;;;; col -> window(XtN foreground);
	;;; change current foreground
	if  not(col)
		or (isinteger(col) and col == current_foreground
			;;; and xt_islivewindow(current_window)
			and current_window == window)
	then
		;;; do nothing
	else
		if isstring(col) then
			lvars int = colour_mapping(col);
			if isinteger(int) then
				int -> XptVal[fast] window(XtN foreground:int)
			else
				;;; set foreground and save string to int mapping
				col -> window(XtN foreground);
				;;; get and save the string to int mapping for colours
				XptVal[fast] window(XtN foreground:int) ->> int
					-> colour_mapping(col);
			endif;
		elseif isinteger(col) then
			col ->> XptVal[fast] window(XtN foreground:int) -> int;
		elseif col == "background" then
			;;; if it is the word "background", make the background colour to be the foreground colour
			rc_background(window) -> rc_foreground(window);
			return();
		else
			mishap(col, 1, 'String (colour name) needed')
		endif;
		window -> current_window;
		int -> current_foreground;
	endif;
enddefine;



endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 18 2000
	Introduced rc_foreground_changeable

--- Aaron Sloman, Feb 18 2000
	Altered to allow
		"background" -> rc_foreground(win)
	to set the current background colour to be the foreground colour.
		false -> rc_foreground(win)
	leaves the foreground unchanged.

--- Aaron Sloman, Aug  4 1997
	Added check for live window
--- Aaron Sloman, Dec 31 1996
	Updated to cache the mappings from strings to integers
	Optimised and fixed various bugs.
 */
