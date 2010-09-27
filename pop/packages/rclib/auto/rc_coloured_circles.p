/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_coloured_circles.p
 > Purpose:			Draw nested coloured circles
 > Author:          Aaron Sloman, Aug 14 1998
 > Documentation: 	Below for now
 > Related Files:   LIB rc_draw_circle, rc_draw_blob
 */


/*

HELP RC_COLOURED_CIRCLES

rc_coloured_circles(xcentre, ycentre, radius, thickness, inc, colours);

Draw circles at the location specified with the thickness specified,
starting with the radius specified, and increasing radius by
thickness plus inc each time.

If rc_xscale and rc_yscale are different the circles may be elliptical
instead of circular.

1-> rc_xscale;1->rc_yscale;
rc_start();


vars
	colours1 =
		['red' 'blue' 'yellow' 'green'],
	colours2 =
		['gray0' 'gray10'  'gray20'  'gray30'  'gray40'  'gray50'
	  'gray60'  'gray70'],
;

rc_start();
rc_xorigin,rc_yorigin=>
rc_coloured_circles(0,0,2,2,4,['blue' 'green' 'yellow']);
rc_coloured_circles(0,40,2,2,6,['blue' 'green' 'yellow']);
rc_coloured_circles(0,80,2,5,10,['blue' 'green' 'yellow']);
rc_coloured_circles(-50,-50,5,3,1, colours1);
rc_start();
rc_coloured_circles(-100,-80,15,5,10, colours1);
rc_coloured_circles(-100, 80,10,15,2.5, colours1);
rc_coloured_circles(150,150,10,5,2, colours2);
rc_coloured_circles(150,-150,0,10,0, colours2);


Try changing scales and redoing the above
-0.5 -> rc_yscale; 0.5 -> rc_xscale;

-0.8 -> rc_yscale; 0.5 -> rc_xscale;

-0.8 -> rc_yscale; 1.5 -> rc_xscale;

Restore original scale
-1 -> rc_yscale; 1 -> rc_xscale;

define test_move(x1, y1, x2, y2, n, radius, inc, colours);

	dlocal %rc_line_function(rc_window)% = GXxor;
    lvars x = x1, y = y1,
		xinc = (x2 - x1 + 0.0)/n,
		yinc = (y2 - y1 + 0.0)/n,
		;
	repeat
		if xinc > 0 then quitif(x > x2);
		else quitif(x < x2);
		endif;
		rc_coloured_circles(x, y, radius, 3, inc, colours);
		syssleep(2);
		rc_coloured_circles(x, y, radius, 3, inc, colours);
		x + xinc -> x; y + yinc -> y;
	 endrepeat

enddefine;

rc_start();
test_move(-200,-150, 200, 150, 50, 20, 3, colours1);
test_move(-200,150, 200, -150, 150, 20, 3, colours2);

*/

compile_mode :pop11 +strict;
section;

uses rc_graphic;
uses rc_line_width
uses rc_foreground
uses rc_draw_circle

define rc_coloured_circles(xcentre, ycentre, radius, thickness, inc, colours);
	lvars
		scale = max(abs(rc_xscale),abs(rc_yscale)),
		thickness = round(thickness*scale),
		colour;
	dlocal
		%rc_line_width(rc_window)% = thickness,
		%rc_foreground(rc_window)%;

	for colour in colours do
		colour -> rc_foreground(rc_window);
		rc_draw_circle(xcentre, ycentre, radius);
		radius + thickness + inc -> radius;
	endfor;

enddefine;


endsection;
