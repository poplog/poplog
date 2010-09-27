/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_filled_triangle.p
 > Purpose:			Draw filled triangle of specified location, colour
 > Author:          Aaron Sloman, Aug  2 2000
 > Documentation:	HELP RCLIB
 > Related Files:
 */
/*
uses rc_window_object

vars win1 =
        rc_new_window_object("right", "top", 300, 300, true, 'win1');
rc_start();

rc_draw_filled_triangle(0,0, 100, 0, 100, 100, 'red');
rc_draw_filled_triangle(0,100, 100, 0, 100, 100, 'blue');
rc_draw_filled_triangle(-100,-100, 100, 0, -100, 100, 'pink');

*/

uses rclib
uses rc_graphic
uses rc_linepic

loadinclude XpwPixmap.ph;

section;

define rc_draw_filled_triangle(x1, y1, x2, y2, x3, y3, colour);
	dlocal
		%rc_foreground(rc_window)%,
		rc_linewidth;
	if colour then colour -> rc_foreground(rc_window) endif;

	lconstant pointvec = initshortvec(6);

	XpwFillPolygon(
		rc_window,
		fill(rc_transxyout(x1, y1), rc_transxyout(x2, y2), rc_transxyout(x3, y3), pointvec),
		 Convex, CoordModeOrigin)

enddefine;

endsection;
