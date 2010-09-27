/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_blob.p
 > Linked to:       $poplocal/local/auto/rc_draw_blob.p
 > Purpose:         Draw a circular (or elliptical) blob
 > Author:          Aaron Sloman,  1 Jan 1997 (see revisions)
 > Documentation:	rc_draw_blob(x,y,radius)
 > Related Files:	LIB * RC_CIRCLE
 */


/*

HELP RC_DRAW_BLOB

rc_draw_blob(xcentre, ycentre, radius, colour);

Draws a circular blob at the location specified with the radius specified.

If rc_xscale and rc_yscale are different the blob may be elliptical
instead of circular.

1-> rc_xscale;1->rc_yscale;
rc_start();

Some examples, to test the code.

define test_length(x,y,len);
	dlocal %rc_line_width(rc_window)% = 0;
	rc_drawline(x-len,y-len,x+len,y-len);
	rc_drawline(x-len,y-len,x-len,y+len);
	rc_drawline(x-len,y+len,x+len,y+len);
	rc_drawline(x+len,y-len,x+len,y+len);
	;;; rc_drawline(x,y-len,x,y+len);
	;;; rc_drawline(x-len,y,x+len,y);
enddefine;

define test_blob(x,y,radius,colour);
	rc_draw_blob(x,y,radius,colour);
	test_length(x,y,radius+2);
enddefine;


rc_kill_window_object(win1);
rc_kill_window_object(win2);
rc_kill_window_object(win3);
vars win1 = rc_new_window_object( 650, 20, 350, 350, true, 'win1');
vars win2 = rc_new_window_object( 650, 20, 450, 450, {30 200 -1.5 1.5}, 'win2');
vars win3 = rc_new_window_object( 650, 20, 450, 450, {225 225 4 -3}, 'win3');
rc_start();
rc_drawline(0,180,0,-180);
rc_drawline(-180,0,180,0);
rc_drawline(10,180,10,-180);
rc_drawline(-10,180,-10,-180);
rc_drawline(-180,10,180,10);
rc_drawline(-180,-10,180,-10);
rc_xorigin,rc_yorigin=>
rc_draw_blob(0,0,10,'green');
test_length(0,30,10);
test_length(-30,0,10);
test_blob(0, 100, 10, 'red');
test_blob(0, -100, 10, 'red');
test_length(0,0,100);
test_blob(0,0,100,'pink');
rc_draw_blob(10,0,4,'blue');
rc_draw_blob(5,10,2,'red');
rc_draw_blob(25,10,2,'blue');
rc_draw_blob(-25,30,4,'blue');
rc_drawline(25,-30,5,-30);
rc_drawline(-45,30,45,30);
rc_drawline(0,180,0,-180);
rc_drawline(-180,0,180,0);
rc_draw_blob(0,-30,10,'black');
rc_draw_blob(25,-30,10,'black');
rc_draw_blob(45,-30,40,'red');
rc_draw_blob(45,-30,4,'blue');
rc_xscale,rc_yscale=>
rc_draw_blob(10,10,2,'blue');
rc_draw_blob(0,5,2,'black');
rc_draw_blob(0,-5,2,'red');
rc_draw_blob(-20,0,10,'blue');
rc_draw_blob(30,0,10,'blue');
rc_draw_blob(30,70,10,'blue');
rc_draw_blob(5,10,2,'red');
rc_draw_blob(15,10,2,'blue');

rc_start();
rc_drawline(0,180,0,-180);
rc_drawline(-180,0,180,0);
rc_xscale,rc_yscale =>
test_blob(0,0,20,'black');
test_blob(0,60,20,'black');
test_length(0,0,20);
rc_draw_blob(-50,0,20,'black');
test_length(-50,0,20);
rc_draw_blob(-50,0,20,'red');
test_length(-50,0,40);

veddo('l1');
rc_start();
rc_drawline(0,180,0,-180);
rc_drawline(-180,0,180,0);
test_length(0,0,40);
rc_draw_blob(0,0,40,'red');

test_length(0,0,10);
test_blob(0,0,5,'black');
test_blob(100,0,30, 'red');
test_blob(170,0,31, 'red');

test_blob(0,100,40, 'green');
test_blob(0,185,41, 'green');

test_blob(-50,-50,50, 'pink');
test_blob(-120,-120,49, 'pink');

test_blob(-120,40,6, 'red');
test_length(-200, -200, 30);
rc_draw_blob(-200,-200,30,'red');
test_blob(-260,-250,30,'red');

test_length(-200, -200, 10);
test_blob(-120,60,7, 'red');

test_blob(-120,85,8, 'red');
test_blob(-120,110,9, 'red');

test_blob(-145,85,10.5, 'red');
test_blob(-145,110,11.5, 'red');

test_blob(80,80,70, 'pink');

test_blob(150,-150,100, 'orange');

Try changing scales and redoing the above
-0.5 -> rc_yscale; 0.5 -> rc_xscale;

-0.8 -> rc_yscale; 0.5 -> rc_xscale;

-0.8 -> rc_yscale; 1.5 -> rc_xscale;

Restore original scale
-1 -> rc_yscale; 1 -> rc_xscale;


test_length(-200,200,400);

define test_move(x1, y1, x2, y2, n, radius, colour);

	dlocal %rc_line_function(rc_window)% = GXxor;
    lvars x = x1, y = y1,
		xinc = (x2 - x1 + 0.0)/n,
		yinc = (y2 - y1 + 0.0)/n,
		;
	repeat
		x + xinc -> x; y + yinc -> y;
		quitif(x > x2);
		test_blob(x, y, radius, colour);
		test_blob(x, y, radius, colour);
	 endrepeat

enddefine;

rc_start();
CIRCLE(0,0,5);
rc_drawline(3,3,10,10);
test_move(-200,-150, 200, 150, 50, 20, 'red');
test_move(-200,150, 200, -150, 50, 20, 'red');

*/

compile_mode :pop11 +strict;
section;

uses rc_graphic;
uses rc_foreground


define rc_draw_blob(xcentre, ycentre, radius, colour);
	lvars
		scale = max(abs(rc_xscale),abs(rc_yscale)),
		radius = round(radius*scale),
		diam = radius+radius;

	dlocal
		;;; %rc_line_width(rc_window)% = radius,
		%rc_foreground(rc_window)% = colour;

	rc_transxyout(xcentre,ycentre) ->(xcentre,ycentre);

	lconstant fullcirc = 360*64;	;;; units are 1/64 degree

	XpwFillArc(rc_window,
		round(xcentre - radius),
		round(ycentre - radius),
		diam,
		diam,
		0,
		fullcirc);

enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 16 2000
	Rewritten to use XpwFillArc instead of XpwDrawArc
 */
