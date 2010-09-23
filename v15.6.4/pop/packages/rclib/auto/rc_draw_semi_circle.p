/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_semi_circle.p
 > Purpose:         Draw a circular (or elliptical) blob
 > Author:          Aaron Sloman,  17 Jun 2000
 > Documentation:	Below, HELP RCLIB
 > Related Files:	LIB rc_draw_blob_sector, rc_draw_scaled_blob
 */

/*
rc_kill_window_object(win1);
rc_kill_window_object(win2);
rc_kill_window_object(win3);
vars win1 = rc_new_window_object( 650, 20, 350, 350, true, 'win1');
vars win2 = rc_new_window_object( 650, 20, 450, 450, {60 200 -1.5 1.5}, 'win2');
vars win3 = rc_new_window_object( 650, 20, 450, 450, {225 225 2 1.5}, 'win3');

rc_start();
rc_drawline(0,180,0,-180);
rc_drawline(-180,0,180,0);
rc_drawline(20,180,20,-180);
rc_drawline(-20,180,-20,-180);
rc_drawline(-180,20,180,20);
rc_drawline(-180,-20,180,-20);
rc_xorigin,rc_yorigin=>
rc_draw_semi_circle(0,0,20,0,'pink');
rc_draw_semi_circle(0,0,20,90,'blue');
rc_draw_semi_circle(20,0,10,0,'red');
rc_draw_semi_circle(-50,0,30,45, 'red');
rc_draw_semi_circle(-50,60,30,-45, 'yellow');
rc_drawline(-50,180,-50,-180);
rc_drawline(-150,60,150,60);
rc_draw_semi_circle(-50,60,30,135, 'green');

*/


compile_mode :pop11 +strict;
section;

uses rclib
uses rc_graphic;
uses rc_foreground
uses rc_draw_blob_sector

define rc_draw_semi_circle(xcentre, ycentre, radius, orientation, colour);

	rc_draw_blob_sector(xcentre, ycentre, radius, orientation, 180, colour);

enddefine;


endsection;
