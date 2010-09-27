/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_coloured_pointlist.p
 > Purpose:         Draw pointlist as open or closed polyline, with specified
					colour and thickness
 > Author:          Aaron Sloman, 21 Feb 1999
 > Documentation:	below for now. See HELP RCLIB
 > Related Files:	LIB rc_draw_pointlies
 */

/*
rc_draw_coloured_pointlist(pointlist, colour, linewidth, boolean);

Draw a polyline linking the points in pointlist. The line will have the
specified colour and linewidth (or if either is false the current
default will be used). If boolean is true the polyline is closed,
otherwise open (the last line not drawn).

;;; TESTS

rc_start();

;;; open polyline
rc_draw_coloured_pointlist([{0 0} {0 100} {100 100} {100 0}], 'green', 1, false);
rc_draw_coloured_pointlist([{-60 -60} {-60 100} {100 100} {100 -60}], 'blue', 5, true);

*/

compile_mode :pop11 +strict;

section;

define rc_draw_coloured_pointlist(pointlist, colour, linewidth, closed);
	dlocal
		%rc_line_width(rc_window)%,
		%rc_foreground(rc_window)%;

	if colour then colour -> rc_foreground(rc_window) endif;
	if linewidth then linewidth -> rc_linewidth endif;

	rc_draw_pointlist(pointlist, closed);
enddefine;

endsection;
