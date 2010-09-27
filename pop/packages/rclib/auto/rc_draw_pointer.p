/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_pointer.p
 > Purpose:			Make a pointer from a sector of a circle
 > Author:          Aaron Sloman, 16 Jun 2000
 > Documentation:   HELP RC_SLIDER, HELP RCLIB, REF XpwFillArc
 > Related Files:	LIB RC_DRAW_BLOB_SECTOR
 */

/*
uses rclib

;;; NB do this first when testing
uses rc_window_object

rc_kill_window_object(win1);
rc_kill_window_object(win2);
rc_kill_window_object(win3);
vars win1 = rc_new_window_object( 650, 20, 350, 350, true, 'win1');
vars win2 = rc_new_window_object( 650, 20, 450, 450, {30 200 -1.5 1.5}, 'win2');
vars win3 = rc_new_window_object( 650, 20, 450, 450, {225 225 -1.5 0.7}, 'win3');

rc_start();
rc_drawline(0,180,0,-180);
rc_drawline(-180,0,180,0);
rc_drawline(20,180,20,-180);
rc_drawline(-20,180,-20,-180);
rc_drawline(-180,20,180,20);
rc_drawline(-180,-20,180,-20);

;;; rc_draw_pointer(xcentre, ycentre, radius, angle, width, colour);
rc_start();
rc_draw_pointer(0, 0, 20, 180, 45, 'blue');
rc_draw_pointer(0, 0, 40, 0, 20, 'red');
rc_draw_pointer(0, 0, 30, 270, 90, 'blue');
rc_draw_pointer(0, 0, 20, 270, 45, 'yellow');
rc_draw_pointer(0, 0, 50, 90, 60, 'blue');
rc_draw_pointer(0, 0, 100, 90, 20, 'pink');

rc_draw_pointer(0, 0, 20, 0, -45, 'red');
rc_draw_pointer(0, 0, 20, -180, -45, 'red');
rc_draw_pointer(0, 0, 20, -270, -45, 'red');
rc_draw_pointer(0, 0, 20, 270, -45, 'pink');

rc_draw_pointer(0, 0, 80, -180, 15, 'yellow');
rc_draw_pointer(0, 0, 80, 180, 15, 'yellow');
rc_draw_pointer(0, -40, 80, 180, 15, 'yellow');
rc_draw_pointer(0, -40, 40, 90, -45, 'pink');
rc_draw_pointer(0, -40, 40, -90, 10, 'pink');
rc_draw_pointer(0, 80, 40, 45, 10, 'pink');
rc_draw_pointer(0, 100, 40, 45, 10, 'pink');

rc_drawline(0,180,0,-180);
rc_drawline(180,0,-180,0);
rc_drawline(-180,100,180,100);
rc_drawline(100,180,100,-180);
rc_drawline(-100,180,-100,-180);
rc_drawline(-180,-100,180,-100);

rc_draw_blob(0,-100,60, 'white');

-rc_xscale -> rc_xscale;
vars x;
for x from 0 by -10 to -360*4 do
	syssleep(4);
	rc_draw_pointer(0, -100, 30, x mod 360 +10, 10, 'white');
	rc_draw_pointer(0, -100, 30, x mod 360, 10, 'red');
	rc_draw_pointer(0, -100, 60, (x*2) mod 360 +20, 5, 'white');
	rc_draw_pointer(0, -100, 60, (x*2) mod 360, 5, 'blue');
endfor;

-rc_yscale -> rc_yscale;

rc_draw_pointer(0, 100, 20, 0, -45, 'red');
rc_draw_pointer(-100, 100, 20, 0, -45, 'blue');
rc_draw_pointer(-100, 100, 20, 0, 45, 'red');
rc_draw_pointer(-100, 100, 50, -180, 45, 'red');
rc_draw_pointer(-100, -100, 50, -180, -15, 'red');
rc_draw_pointer(0, -150, 50, -270, -45, 'red');
rc_draw_pointer(0, -150, 50, 270, -45, 'pink');
rc_draw_pointer(0, -150, 50, 180, -90, 'blue');

1-> rc_xscale;

-1 -> rc_yscale;

rc_draw_pointer(150, -150, 50, -270, -45, 'red');
rc_draw_pointer(150, -150, 50, 270, -45, 'pink');
rc_draw_pointer(150, -150, 50, 180, -90, 'blue');
rc_draw_pointer(0, 0, 50, 180, 10, 'yellow');
rc_draw_pointer(0, 0, 50, 100, 10, 'red');

rc_draw_scaled_blob(0, -100, 80, 'yellow');
rc_draw_circle(0, -100, 40);
vars x;
for x from 0 by 10 to 360 do
	syssleep(20);
	rc_draw_pointer(0, -100, 80, x mod 360 -10, 10, 'white');
	rc_draw_pointer(0, -100, 80, x mod 360, 10, 'red');
endfor;

rc_xscale,rc_yscale =>
-rc_yscale -> rc_yscale;
-rc_xscale -> rc_xscale;


rc_start();
rc_draw_blob(0,-100, 70, 'grey20');
rc_draw_blob_sector(0, -100, 70, 5, -10, 'red');
rc_draw_blob_sector(0, -100, 40, 4, -8, 'blue');
rc_draw_blob_sector(0, -100, 60, 2.5, -5, 'yellow');
rc_draw_blob_sector(0, -100, 70, 185, -10, 'red');
rc_draw_blob_sector(0, -100, 40, 184, -8, 'blue');
rc_draw_blob_sector(0, -100, 60, 182.5, -5, 'yellow');

rc_draw_blob_sector(0, -100, 70, 95, -10, 'red');
rc_draw_blob_sector(0, -100, 40, 94, -8, 'blue');
rc_draw_blob_sector(0, -100, 60, 92.5, -5, 'yellow');

rc_xscale,rc_yscale =>
-rc_yscale -> rc_yscale;
-rc_xscale -> rc_xscale;

*/

section;

uses rclib
uses rc_graphic
uses rc_foreground

define rc_draw_pointer(xcentre, ycentre, radius, angle, width, colour);

	dlocal popradians = false;

	lvars
		newx = xcentre + radius*cos(angle),
		newy = ycentre + radius*sin(angle),
		;

	;;;[^newx ^newy ^angle] =>
	rc_draw_blob_sector(
		newx, newy, radius,
		if rc_xscale > 0 then
			180+(angle - 0.5*width)
		else
			-(angle + 0.5*width)
		endif mod 360,
	 width, colour)


enddefine;

endsection;
