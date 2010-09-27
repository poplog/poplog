/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_blob_sector.p
 > Purpose:			Make a sector of a circle
 > Author:          Aaron Sloman, 17 Jun 2000
 > Documentation:   HELP RC_SLIDER, HELP RCLIB, REF XpwFillArc
 > Related Files:	LIB RC_CONTROL_PANEL, LIB RC_SQUARE_SLIDER
 */

/*
rc_draw_blob_sector(xcentre, ycentre, radius, startangle, incangle, colour);

draws part of a blob in a possibly squashed square of side 2*radius
with top left corner located such that xcentre,ycentre is at the
centre of the square.

The startangle for the sector is measured counter clockwise from east
(3 o clock) when rc_yscale is negative and clockwise when it is
positive.

The incangle is measured in the same direction.

Should startangle be measured from the west if rc_xscale is negative??

	See REF * XpwFillArc, * XpwDrawArc
	MAN * XFillArc, *XDrawArc

*/

/*
uses rclib
uses rc_window_object

uses rc_linepic
rc_kill_window_object(win1);
rc_kill_window_object(win2);
rc_kill_window_object(win3);
vars win1 = rc_new_window_object( 650, 20, 350, 350, true, 'win1');
vars win2 = rc_new_window_object( 650, 20, 450, 450, {30 200 -1.5 1.5}, 'win2');
vars win3 = rc_new_window_object( 650, 20, 450, 450, {225 225 -1.5 2}, 'win3');

rc_start();
rc_drawline(0,180,0,-180);
rc_drawline(-180,0,180,0);
rc_drawline(20,180,20,-180);
rc_drawline(-20,180,-20,-180);
rc_drawline(-180,20,180,20);
rc_drawline(-180,-20,180,-20);

rc_xscale, rc_yscale=>

rc_draw_blob_sector(xcentre, ycentre, radius, startangle, incangle, colour);
rc_draw_blob_sector(0, 0, 20, 180, 45, 'red');
rc_draw_blob_sector(0, 0, 20, 0, -45, 'red');
rc_draw_blob_sector(0, 0, 20, 0, 90, 'blue');
rc_draw_blob_sector(0, 0, 20, 270, 45, 'blue');
rc_draw_blob_sector(0, 0, 35, 0, -235, 'pink');
rc_draw_blob_sector(0, 0, 30, 0, 235, 'blue');

rc_draw_blob_sector(0, 0, 20, 0, -45, 'red');
rc_draw_blob_sector(0, 0, 20, -180, -45, 'red');
rc_draw_blob_sector(0, 0, 20, -270, -45, 'red');
rc_draw_blob_sector(0, 0, 20, -270, 45, 'red');
rc_draw_blob_sector(0, 0, 20, 270, -45, 'yellow');

rc_draw_blob_sector(0, 0, 40, 180, 45, 'pink');
rc_draw_blob_sector(0, 0, 40, 90, -45, 'pink');

rc_draw_blob_sector(0, 40, 40, 90, 360, 'red');
rc_draw_blob_sector(0, -40, 20, 90, 360, 'red');

rc_drawline(0,180,0,-180);
rc_drawline(-180,100,180,100);
rc_drawline(100,180,100,-180);
rc_drawline(-100,180,-100,-180);
rc_drawline(-180,-100,180,-100);
rc_draw_blob_sector(0, 100, 20, 0, -45, 'red');
rc_draw_blob_sector(-100, 100, 20, 0, -45, 'red');
rc_draw_blob_sector(-100, 100, 20, -180, -45, 'red');
rc_draw_blob_sector(-100, -100, 20, -180, -45, 'red');
rc_draw_blob_sector(0, -150, 50, -270, -45, 'red');
rc_draw_blob_sector(0, -150, 50, 270, -45, 'pink');
rc_draw_blob_sector(0, -150, 50, 180, -90, 'blue');

rc_draw_blob_sector(50, 50, 30, -10, 20, 'blue');
rc_xscale,rc_yscale =>
-rc_xscale-> rc_xscale;
-rc_yscale -> rc_yscale;

rc_draw_blob_sector(150, -150, 50, -270, -45, 'red');
rc_draw_blob_sector(150, -150, 50, 270, -45, 'pink');
rc_draw_blob_sector(150, -150, 50, 180, -90, 'blue');

*/

section;

uses rc_graphic;
uses rc_foreground

;;; need this for rc_rotate_coords
uses rc_linepic

define rc_draw_blob_sector(xcentre, ycentre, radius, startangle, incangle, colour);

;;; needs to be quite messy to deal with rotatable objects in rc_linepic

	lvars
		frame_ang = rc_frame_angle,
		diam = radius+radius,
		clock = -sign(rc_yscale);

	dlocal
		%rc_foreground(rc_window)% = colour;
	dlocal rc_frame_angle;
	0 -> rc_frame_angle;

	;;; [unrotated ^xcentre ^ycentre ang ^rc_frame_angle]=>
	;;; [trans %rc_transxyout(xcentre,ycentre)% ] =>
	;;; rc_transxyout(xcentre,ycentre) ->(xcentre,ycentre);
	rc_rotate_coords_rounded(xcentre,ycentre) ->(xcentre,ycentre);

	;;; [rotated ^xcentre ^ycentre ang ^rc_frame_angle]=>

	;;; Angle units are 1/64 degree

	XpwFillArc(rc_window,
		round(xcentre - abs(radius*rc_xscale)),
		round(ycentre - abs(radius*rc_yscale)),
		round(abs(diam*rc_xscale)),
		round(abs(diam*rc_yscale)),
		round((startangle)*64*clock),
		round(incangle*64*clock));

enddefine;

endsection;
