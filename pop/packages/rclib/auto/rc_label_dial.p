/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_label_dial.p
 > Purpose:			Plant labels at specified points on a circle.
 > Author:          Aaron Sloman, Aug 23 2000
 > Documentation:	HELP RCLIB
 > Related Files:	LIB rc_draw_arc_segments
 */

/*
;;; TESTS
rc_kill_window_object(win1);
rc_kill_window_object(win2);
rc_kill_window_object(win3);
vars win1 = rc_new_window_object( "right", 20, 450, 450, true, 'win1');
vars win2 = rc_new_window_object( "right", 20, 450, 450, {200 200 -1.5 1.5}, 'win2');
vars win3 = rc_new_window_object( "right", 20, 450, 450, {225 225 1.5 0.7}, 'win3');

rc_start();;
rc_label_dial(xcentre, ycentre, radius, start, inc, lim, num, incnum, colour, font);
rc_label_dial(0, 0, 50, 180, -45, 0, 0, 4.5, 'red', '6x13');
rc_label_dial(0, 0, 80, 180, -45, 0, 0, 4.5, 'red', '10x20');

rc_start();;
rc_draw_arc_segments(0, 0, 110, 179, -10, -1, 2, 20, 'green');

rc_label_dial(0, 0, 130, 180, -30, 0, 0, 3, 'red', '10x20');

rc_draw_arc_segments(0, 0, 160, 179, -10, -1, 0.5, 10, 'blue');
rc_label_dial(0, 0, 180, 180, -10, 0, 0, 0.1, 'red', '6x13');

rc_drawline(0,300,0,-300);
rc_draw_arc_segments(0, -50, 110, 89, 10, 270, 2, 5, 'blue');
rc_label_dial(0, -50, 130, 270, -20, 89, 10.0, 1.0, 'red', '6x13');


*/


section;

compile_mode :pop11 +strict;

uses rclib;

uses rc_defaults;

define :rc_defaults;

	;;; default offsets for printing numeric labels
	rc_dial_label_xoffset = -8;	;;; left a bit
	rc_dial_label_yoffset = 5;	;;; down a bit

enddefine;

define rc_label_dial(xcentre, ycentre, radius, start, inc, lim, num, incnum, colour, font);
	dlocal
		pop_pr_places = 2,
		popradians = false,
		%rc_foreground(rc_window)% = colour,
		%rc_font(rc_window)% = font;

	lvars ang;
	for ang from start by inc to lim do
		lvars
			x = xcentre + radius*cos(ang) + rc_dial_label_xoffset/rc_xscale,
			y = ycentre + radius*sin(ang) + rc_dial_label_yoffset/rc_yscale;
			rc_print_at(x, y, num >< nullstring);
			num + incnum -> num;
	endfor;
enddefine;

endsection;
