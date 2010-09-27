/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_triangle.p
 > Purpose:			Draw triangle of specified location, colour, thickness
 > Author:          Aaron Sloman, Aug  2 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:
 */
/*
uses rc_window_object

vars win1 =
        rc_new_window_object("right", "middle", 300, 300, true, 'win1');

vars win2 =
        rc_new_window_object("right", "top", 400, 400, {100 100 2 2}, 'win1');


win1 -> rc_current_window_object;
win2 -> rc_current_window_object;
rc_start();
rc_draw_triangle(0,0, 100, 0, 100, 100, 'red', 3);
rc_draw_triangle(0,100, 100, 0, 100, 100, 'blue', 5);
rc_draw_triangle(-40,-50, 100, 0, -40, 50, 'pink', 10);

*/

uses rclib
uses rc_linepic

section;

define rc_draw_triangle(x1, y1, x2, y2, x3, y3, colour, linewidth );
	dlocal
		%rc_foreground(rc_window)%,
		rc_linewidth;
	if colour then colour -> rc_foreground(rc_window) endif;
	if linewidth then linewidth -> rc_linewidth endif;

	
	rc_transxyout(x1, y1) -> (x1, y1);

	lconstant pointvec = initshortvec(8);
	XpwDrawLines(
		rc_window,
		fill(x1, y1, rc_transxyout(x2, y2), rc_transxyout(x3, y3), x1, y1, pointvec),
		 CoordModeOrigin)
	
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 20 2000
	Improved by using XpwDrawLines instead of rc_*drawline
 */
