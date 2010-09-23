/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_lengthen_window_by.p
 > Purpose:			Lengthen a window
 > Author:          Aaron Sloman, Jun 15 1997 (see revisions)
 > Documentation:   HELP * RCLIB
 > Related Files:   LIB * rc_widen_window_by, rc_window_object
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
rc_drawline_absolute(0,150,200,200,false,35);

win2 -> rc_current_window_object;
rc_drawline(-100, 100, 150, -125);

rc_lengthen_window_by(win1, 50, false);
rc_lengthen_window_by(win1, 50, "background");
rc_lengthen_window_by(win1, 50, 'blue');
rc_lengthen_window_by(win1, -50, false);
'red' -> rc_foreground(rc_widget(win1));

'pink' -> rc_background(rc_widget(win1));
rc_drawline_absolute(0,150,200,200,true,35);
rc_lengthen_window_by(win1, 50, false);
rc_lengthen_window_by(win1, 50, 'blue');
rc_lengthen_window_by(win1, -50, false);
'yellow' -> rc_background(rc_widget(win2));
rc_lengthen_window_by(win2, 50, 'pink');
rc_lengthen_window_by(win2, 50, false);
rc_lengthen_window_by(win2, -50, 'pink');
win2 -> rc_current_window_object;
rc_drawline(-100, 100, 100, -250);
rc_drawline(100, -200, 0, 50);
rc_drawline_absolute(0,100,200,100,'orange',25);
rc_lengthen_window_by(win2, -50, false);

applist([^win1 ^win2], rc_kill_window_object);

*/

section;
uses rclib
uses rc_window_object
uses rc_drawline_absolute

compile_mode :pop11 +strict;


define rc_lengthen_window_by(win_obj, len, colour);
	checkinteger(len, false, false);

	lvars (,,w,h) = rc_window_location(win_obj);

	;;; change the length
	(false, false, false, h+len) -> rc_window_location(win_obj);

	if len > 0 and colour /== "background" then

		procedure();
			;;; Window expanded. Work out colour to use to fill it in.
			unless isboolean(colour) or isinteger(colour)
			then
				check_string(colour);
			endunless;

			dlocal rc_current_window_object = win_obj;

			;;; paint the background for the new part
			rc_drawline_absolute(0, h+(len div 2), w, h+(len div 2), colour, len);
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
