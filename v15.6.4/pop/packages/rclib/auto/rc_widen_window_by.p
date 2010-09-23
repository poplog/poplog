/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_widen_window_by.p
 > Purpose:			Widen a window
 > Author:          Aaron Sloman, Jun 15 1997 (see revisions)
 > Documentation:   HELP * RCLIB
 > Related Files:	rc_lengthen_window_by, rc_window_object
 */

/*
vars
    win1 = rc_new_window_object(200, 40, 300, 250, true, 'win1'),
    win2 = rc_new_window_object(600, 40, 300, 250, true, 'win2');

win1 -> rc_current_window_object;

rc_drawline(0, 0, 150, 150);
rc_drawline_absolute(20,0,20,150,'blue',5);
rc_drawline_absolute(0,100,200,100,'orange',25);
rc_drawline_absolute(0,50,200,150,'ivory',35);
rc_drawline_absolute(0,50,200,150,'pink',35);

win2 -> rc_current_window_object;
rc_drawline(-100, 100, 150, -125);

rc_widen_window_by(win1, 50, false);
rc_widen_window_by(win1, 50, "background");
rc_widen_window_by(win1, 50, 'blue');
rc_widen_window_by(win1, -50, false);

'pink' -> rc_background(rc_widget(win1));
rc_widen_window_by(win1, 50, false);
rc_widen_window_by(win1, 50, 'blue');
rc_widen_window_by(win1, -50, false);
rc_widen_window_by(win2, 50, false);
rc_widen_window_by(win2, 50, 'pink');
rc_widen_window_by(win2, -50, false);
'yellow' -> rc_background(rc_widget(win2));
win2 -> rc_current_window_object;
rc_drawline(-100, 100, 450, -150);
rc_drawline(400, 0, 0, 50);
rc_drawline_absolute(0,100,200,100,'orange',25);
rc_drawline(400, 0, -100, -50);
rc_widen_window_by(win2, -50, false);

applist([^win1 ^win2], rc_kill_window_object);

*/

section;
uses rclib
uses rc_window_object
uses rc_drawline_absolute

compile_mode :pop11 +strict;

define rc_widen_window_by(win_obj, width, colour);
	checkinteger(width, false, false);

	;;; get current width and height
	lvars (,,w,h) = rc_window_location(win_obj);

	;;; Change the width
	(false, false, w+width, false) -> rc_window_location(win_obj);

	if width > 0 and colour /== "background" then
		;;; will need to be painted after expansion

		procedure();

			;;; Work out colour to use to fill it in.
			unless isboolean(colour) or isinteger(colour)
			then
				check_string(colour);
			endunless;

			dlocal rc_current_window_object = win_obj;

			;;; paint the background for the new part
			rc_drawline_absolute(w+(width div 2), 0, w+(width div 2), h, colour, width);
		endprocedure();
	endif;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 19 2000
	Altered to allow "background" for colour, and false for current foreground,
	to conform to convention for rc_foreground.
--- Aaron Sloman, May 29 1999
	Allowed colour to be an integer
 */
