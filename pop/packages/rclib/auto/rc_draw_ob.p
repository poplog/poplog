/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_ob.p
 > Linked to:       $poplocal/local/auto/rc_draw_ob.p
 > Purpose:         Draw an oblong (rectangle with rounded corners)
 > Author:          Aaron Sloman,  1 Jan 1997 (see revisions)
 > Documentation:	rc_draw_ob(x, y, width, height, radius1, radius2);
 > Related Files:	LIB * RC_GRAPHIC, * RC_LINEPIC
 */

/*
Cannot be called rc_draw_oblong: would class with procedure defined
in LIB * RC_GRAPHIC/rc_draw_oblong

rc_start();

rc_draw_ob(0, 0, 200, 200, 10, 10);

rc_draw_ob(0, 0, 100, 100, 5, 5);
rc_draw_ob(-50, 50, 100, 100, 5, 5);


*/

compile_mode :pop11 +strict;
section;

uses rc_graphic

define vars rc_draw_ob(x, y, width, height, radius1, radius2);
	rc_transxyout(x, y) -> (x, y);
	round(abs(width * rc_xscale)) -> width;
	round(abs(height * rc_yscale)) -> height;

	XpwDrawRoundedRectangle(
		rc_window,
		x,
		y,
		width,
		height,
		round(abs(radius1 * rc_xscale)),
		round(abs(radius2 * rc_yscale)))
enddefine;



endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr 13 1997
	cleaned up and made consistent with documentation
 */
