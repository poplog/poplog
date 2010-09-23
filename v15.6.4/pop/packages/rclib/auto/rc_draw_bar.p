/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_bar.p
 > Purpose:			Draw a line of a given width and colour
 > Author:          Aaron Sloman, Apr 12 1997
 > Documentation:
 > Related Files:
 */

/*

rc_start();
rc_draw_bar(-100,50, 10, 30, 'red');

rc_draw_bar(-100,-50, 80, 130, 'blue');
rc_draw_bar(-110,-50, 2, 150, 'black');
rc_draw_bar(-110,-50, 100, 2, 'black');

*/

compile_mode :pop11 +strict;

section;
uses rc_graphic;

define rc_draw_bar(x, y, height, len, col);
	;;; draw a bar of given height, length and colour starting at
	;;; x, y (middle of left end). Assume height is relative to current
	;;; scale as defined by rc_yscale, similarly x, y, and len.
	;;;
	dlocal
		%rc_line_width(rc_window)% = abs(round(height*rc_yscale)),
		%rc_foreground(rc_window)% = col;

	rc_drawline(x, y, x+len, y);
enddefine;

endsection;
