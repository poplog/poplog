/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_coloured_line.p
 > Purpose:			Draw coloured line with specified colour and linewidth
 > Author:          Aaron Sloman, 24 Dec 2000
 > Documentation: 	HELP RCLIB
 > Related Files:   LIB rc_draw_lines, rc_graphic/rc_drawline,
 */


/*

rc_draw_coloured_line(x1, y1, x2, y2, colour, linewidth);

Draw line at the location specified with the thickness specified, with
the colour specified.

If either colour or linewidth is false then the current setting is used.

1-> rc_xscale;1->rc_yscale;

rc_start();
rc_xorigin,rc_yorigin=>

rc_draw_coloured_line(0,30,10,'blue',3);
rc_draw_coloured_line(0,0,10,'blue',1);
rc_draw_coloured_line(60,0,20,'red',1);
rc_draw_coloured_line(-60,0,20,'orange',5);


Try changing scales and redoing the above
-0.5 -> rc_yscale; 0.5 -> rc_xscale;

-0.8 -> rc_yscale; 0.5 -> rc_xscale;

-0.8 -> rc_yscale; 1.5 -> rc_xscale;

Restore original scale
-1 -> rc_yscale; 1 -> rc_xscale;

*/

compile_mode :pop11 +strict;
section;

uses rc_graphic;
uses rc_line_width
uses rc_foreground

define rc_draw_coloured_line(x1, y1, x2, y2, colour, linewidth);

	dlocal
		%rc_line_width(rc_window)%,
		%rc_foreground(rc_window)%;

	if colour then colour -> rc_foreground(rc_window) endif;
	if linewidth then linewidth -> rc_linewidth endif;

	rc_drawline(x1, y1, x2, y2);

enddefine;


endsection;
