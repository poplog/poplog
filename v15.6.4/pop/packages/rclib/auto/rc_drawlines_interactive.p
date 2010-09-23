/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:			$local/rclib/auto/rc_drawlines_interactive.p
 > Purpose:			Interactively draw a collection of connected lines
 > Author:			Aaron Sloman, Mar  8 2003
 > Documentation:	HELP RCLIB
 > Related Files:
 */



/*

HELP RC_DRAWLINES_INTERACTIVE

rc_draw_lines_interactive(win_obj, colour, width, closed) -> points;

This method can be used to draw lines interactively, using the mouse, on
a window object created using rc_new_window_object. When the procedure
is invoked, pop11 suspends activity waiting for mouse events. Each time
you press mouse button 1 on the specified window it selects a new point
and draws a line from the previously selected point (if there was one)
to the selected point. This continues until button 3 is pressed, in
which case the process terminates and a list of points is returned,
where each point is represented by a pair of numbers.


The arguments are as follows

win_obj
	The window, an instance of rc_window_object

colour
	A string, specifying the colour, e.g. 'red' or false, in which case
	the current foreground colour for the window will be used.

width
	An integer specifying the width of the lines to be drawn.
	(0 and 1 are equivalent).
	
closed
	If this is false then an open polygon is drawn. If it is true then
	a closed polygon, i.e. the last point selected is joined up to
	the first point.


EXAMPLES:

;;; create a window
vars win1 = rc_new_window_object("right", "top", 400, 350, true, 'win1');
rc_kill_window_object( win1);

;;; create an open polygon of red lines of width 2
rc_draw_lines_interactive(win1, 'red', 2, false) =>

;;; create a closed polygon of blue lines of width 3
rc_draw_lines_interactive(win1, 'blue', 3, true) =>

;;; create a closed polygon of blue lines of width 3
rc_draw_lines_interactive(win1, 'pink', 6, true) =>

;;; create a closed polygon of lines of width 3
rc_draw_lines_interactive(win1, false, 3, true) =>

;;; create a closed polygon of lines of width 0
rc_draw_lines_interactive(win1, false, 0, true) =>

In the last two cases the default foreground colour of the window
is used, namely black.

;;; kill the window
rc_kill_window_object(win1);
*/


section;

uses rclib
uses rc_linepic
uses rc_mousepic
uses rc_app_mouse


define :method rc_draw_lines_interactive(win_obj:rc_window_object, colour, width, closed) -> points;
	dlocal rc_current_window_object = win_obj;

	;;; make sure the window is button sensitive
	rc_mousepic(win_obj, [button]);

	lvars lastx,lasty;

	define next_point(x,y) -> point;
		conspair(x,y) -> point;

		if isnumber(lastx) then
    		rc_draw_coloured_line(lastx, lasty, x, y, colour, width);
		else
    		rc_draw_blob(x, y, 0, colour);
		endif;

		x -> lastx, y -> lasty
	enddefine;

	false ->> lastx -> lasty;

	;;; draw repeatedly using button 1, and stop with button 3.
	[% rc_app_mouse(next_point, 3) %] -> points;

	if closed then
    	rc_draw_coloured_line(lastx, lasty, destpair(front(points)), colour, width);
	endif;

enddefine;

endsection;
