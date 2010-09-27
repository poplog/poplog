/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_coloured_circle.p
 > Purpose:			Draw coloured circle with specified colour and linewidth
 > Author:          Aaron Sloman, 21 Feb 1999
 > Documentation: 	Below for now
 > Related Files:   LIB rc_draw_circle, rc_draw_blob, rc_coloured_circles
 */


/*

rc_draw_coloured_circle(xcentre, ycentre, radius, colour, linewidth);

Draw circle at the location specified with the thickness specified, with
the colour specified.

If either colour or linewidth is false then the current setting is used.

If rc_xscale and rc_yscale are different the circles may be elliptical
instead of circular.

1-> rc_xscale;1->rc_yscale;

rc_start();
rc_xorigin,rc_yorigin=>

rc_draw_coloured_circle(0,30,10,'blue',3);
rc_draw_coloured_circle(0,0,10,'blue',1);
rc_draw_coloured_circle(60,0,20,'red',1);
rc_draw_coloured_circle(-60,0,20,'orange',5);


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
uses rc_draw_circle

define rc_draw_coloured_circle(xcentre, ycentre, radius, colour, linewidth);

	dlocal
		%rc_line_width(rc_window)%,
		%rc_foreground(rc_window)%;

	if colour then colour -> rc_foreground(rc_window) endif;
	if linewidth then linewidth -> rc_linewidth endif;

	rc_draw_circle(xcentre, ycentre, radius);

enddefine;


endsection;
