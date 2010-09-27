/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_filled_rect.p
 > Purpose:			Draw a filled rectangle centred round the specified location
 > Author:          Aaron Sloman, 3 Aug 2000
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RCLIB, LIB rc_graphic
 */

/*

 -1 -> rc_xscale; 1 -> rc_yscale;
 1 -> rc_xscale; 1 -> rc_yscale;
 1 -> rc_xscale; -1 -> rc_yscale;
rc_start();

rc_draw_filled_rect(0,0,60,100,'blue');
rc_draw_filled_rect(0,-100,60,60,'pink');
rc_draw_filled_rect(-100,0,100,100,'yellow');

rc_draw_filled_rect(100,100,60,40,'blue');
rc_draw_filled_rect(0,100,60,40,'pink');
rc_draw_filled_rect(-100,100,60,40,'yellow');


rc_start();

rc_draw_filled_rect(-100,100,200,200,'blue');
rc_draw_filled_rect(-100,-100,120,120,'red');
rc_draw_filled_rect(100,100,160,160,'green');

rc_start();

40 -> rc_xscale;
-40 -> rc_yscale;

rc_draw_filled_rect(-2,2,5,5,'blue');
rc_draw_filled_rect(-3,-3,3,3,'red');
rc_draw_filled_rect(2.8,2.5,4,4,'green');

*/

uses rclib
uses rclib
uses rc_graphic
uses rc_linepic

section;
compile_mode :pop11 +strict;

define rc_draw_filled_rect(x, y, width, height, colour);
	;;; draw rect with top left corner at centre x, y,
	;;; with given width and height

	dlocal
		%rc_foreground(rc_window)%;

	if colour then colour -> rc_foreground(rc_window) endif;

	;;; get absolute values for coordinates, width and height
	rc_transxyout(x, y) -> (x, y);
	round(abs(width * rc_xscale)) -> width;
	round(abs(height * rc_yscale)) -> height;

	XpwFillRectangle(rc_window, x, y, width, height)

enddefine;

endsection;
