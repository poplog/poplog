/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_unscaled_blob.p
 > Purpose:         Draw a circular blob ignoring scale
 > Author:          Aaron Sloman,   4 Feb 1998
 > Documentation:	rc_draw_unscaled_blob(x,y,radius)
 > Related Files:	LIB * RC_CIRCLE * RC_DRAW_BLOB
 */


/*

rc_draw_unscaled_blob(xcentre, ycentre, radius, colour);

Draws a circular blob at the location specified with the radius specified.

Always draws blob with the specified absolute radius, no matter what
rc_xscale, rc_yscale. Used for control panels.

1-> rc_xscale;1->rc_yscale;
rc_start();

Some examples, to test the code.


rc_start();
rc_xorigin,rc_yorigin=>
rc_draw_unscaled_blob(0,0,2,'blue');
rc_draw_unscaled_blob(5,10,2,'red');
rc_draw_unscaled_blob(25,10,2,'blue');
rc_draw_unscaled_blob(25,30,2,'blue');
rc_drawline(25,-30,5,-30);
rc_draw_unscaled_blob(45,-30,5,'black');
rc_draw_unscaled_blob(45,-30,40,'red');
rc_drawline(45,-10,45,-30);
rc_draw_unscaled_blob(-50,0,20,'black');
rc_draw_unscaled_blob(-50,0,20,'red');

rc_start();
3,-3 -> (rc_xscale,rc_yscale);=>

Try changing scales and redoing the above
-0.5 -> rc_yscale; 0.5 -> rc_xscale;

-0.8 -> rc_yscale; 0.5 -> rc_xscale;

-0.8 -> rc_yscale; 1.5 -> rc_xscale;

Restore original scale
-1 -> rc_yscale; 1 -> rc_xscale;

rc_start();
rc_destroy();
*/

compile_mode :pop11 +strict;
section;

uses rc_graphic;
uses rc_line_width
uses rc_foreground

define lconstant CIRCLE(xcentre, ycentre, radius);

	lconstant fullcirc = 360*64;	;;; units are 1/64 degree

	lvars
		diam = radius;
		round(radius*0.5) -> radius;

	XpwDrawArc(rc_window,
		(xcentre - radius),
		(ycentre - radius),
		diam,
		diam,
		0,
		fullcirc);

enddefine;

define rc_draw_unscaled_blob(xcentre, ycentre, radius, colour);
	dlocal
		%rc_line_width(rc_window)% = radius,
		%rc_foreground(rc_window)% = colour;

	rc_transxyout(xcentre,ycentre) ->(xcentre,ycentre);

	CIRCLE(xcentre, ycentre, radius);

	;;; Now make sure the boundary of the blob is ok
	if radius mod 2 /== 0 then
		0 -> rc_line_width(rc_window);
		CIRCLE(xcentre, ycentre, radius*2);
	endif;

enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 11 1997
	Rewritten to do what's needed. Introduced CIRCLE
--- Aaron Sloman, Jul 25 1997
	Slightly modified so that non even length radius is dealt with
	in a different way.
--- Aaron Sloman, Jul  5 1997
    Stopped rounding radius. Did not work for scaled pictures. Leave
    that to rc_circle.
--- Aaron Sloman, Jan 11 1997
	Made it fill dot at centre
 */
