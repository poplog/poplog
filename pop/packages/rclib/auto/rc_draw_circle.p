/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_circle.p
 > Linked to:       $poplocal/local/auto/rc_draw_circle.p
 > Purpose:         Draw a circle (previously rc_circle)
 > Author:          Aaron Sloman, Apr  4 1996 (see revisions)
 > Documentation:	rc_draw_circle(x,y,radius)
 > Related Files:
 */


/*
rc_start();
rc_draw_circle(0,0,100);
rc_draw_circle(100,0,100);
rc_draw_circle(0,100,100);
rc_draw_circle(-50,-50,100);
rc_draw_circle(0,-50,100);
rc_draw_circle(50,-50,100);

-0.5 -> rc_yscale;
0.5 -> rc_xscale;
-1 -> rc_yscale; 1 -> rc_xscale;
and then redo

*/

compile_mode :pop11 +strict;
section;

uses rc_graphic;

define rc_draw_circle(xcentre, ycentre, radius);
	lconstant fullcirc = 360*64;	;;; units are 1/64 degree
	rc_transxyout(xcentre,ycentre) ->(xcentre,ycentre);
	lvars diam = radius+radius;

	XpwDrawArc(rc_window,
		round(xcentre - abs(rc_xscale * radius) ),
		round(ycentre - abs(rc_yscale * radius) ),
		round(abs(diam*rc_xscale)),
		round(abs(diam*rc_yscale)),
		0,
		fullcirc);
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 25 1997
	made rc_circle a synonym for this
--- Aaron Sloman, Apr 21 1997
	Fixed another scaling bug. Did not handle positive yscale properly.
--- Aaron Sloman, Jan  1 1997
	Renamed, from rc_circle
--- Aaron Sloman, Apr 12 1996
    Fixed scaling bug. Switched to use XpwDrawArc directly
 */
