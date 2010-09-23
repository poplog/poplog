/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_filled_centred_rect.p
 > Purpose:			Draw a filled rectangle centred round the specified location
 > Author:          Aaron Sloman, 3 Aug 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RCLIB, LIB rc_graphic
 */

/*

1 -> rc_yscale; -1 -> rc_xscale;
-1 -> rc_yscale; 1 -> rc_xscale;
rc_start();

rc_draw_filled_centred_rect(100,100,60,40,'blue');
rc_draw_filled_centred_rect(0,100,60,40,'pink');
rc_draw_filled_centred_rect(-100,100,60,40,'yellow');

rc_draw_filled_centred_rect(0,0,60,100,'blue');
rc_draw_filled_centred_rect(0,-100,60,60,'pink');
rc_draw_filled_centred_rect(-100,0,100,100,'yellow');

rc_start();

rc_draw_filled_centred_rect(-100,100,200,200,'blue');
rc_draw_filled_centred_rect(-100,-100,120,120,'red');
rc_draw_filled_centred_rect(100,100,160,160,'green');

rc_start();

40 -> rc_xscale;
-40 -> rc_yscale;

rc_draw_filled_centred_rect(-2,2,5,5,'blue');
rc_draw_filled_centred_rect(-3,-3,3,3,'red');
rc_draw_filled_centred_rect(2.8,2.5,4,4,'green');

*/

uses rclib
uses rclib
uses rc_graphic
uses rc_linepic

loadinclude XpwPixmap.ph;


section;
compile_mode :pop11 +strict;

define rc_draw_filled_centred_rect(x, y, width, height, colour);
	dlocal
		%rc_foreground(rc_window)%;

	if colour then colour -> rc_foreground(rc_window) endif;
	
	lvars
		halfwidth = width/2.0,
		halfheight = height/2.0,
		xmin = x - halfwidth,
		xmax = x + halfwidth,
		ymin = y - halfheight,
		ymax = y + halfheight;
	;

	lconstant pointvec = initshortvec(8);


	XpwFillPolygon(
		rc_window,
		fill(
			rc_transxyout(xmin, ymin),
			rc_transxyout(xmin, ymax),
			rc_transxyout(xmax, ymax),
			rc_transxyout(xmax, ymin),
			pointvec),
		 Convex, CoordModeOrigin);

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 20 2000
	Changed to use shortvec
 */
