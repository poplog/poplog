/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_arc_segments.p
 > Purpose:			Draw small segments (e.g. "ticks") on a circular arc
 > Author:          Aaron Sloman, Aug 22 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB rc_draw_arc_segment
 */

/*
rc_kill_window_object(win1);
rc_kill_window_object(win2);
rc_kill_window_object(win3);
vars win1 = rc_new_window_object( "right", 20, 450, 450, true, 'win1');
vars win2 = rc_new_window_object( "right", 20, 450, 450, {30 200 -1.5 1.5}, 'win2');
vars win3 = rc_new_window_object( "right", 20, 450, 450, {225 225 1.5 0.7}, 'win3');

rc_draw_arc_segments(xcentre, ycentre, radius, start, gap, lim, inc, width, col);
rc_draw_arc_segments(-100, -150, 110, 180, -45, 0, 2, 80, 'green');

rc_draw_arc_segments(-100, -150, 80, 180, -45, 0, 2, 30, 'blue');

rc_draw_arc_segments(0, 0, 50, 180, -45, 0, 2,10, 'blue');
rc_draw_arc_segments(0, 0, 60, 180, -22.5, 0, 2, 10, 'red');
rc_draw_arc_segments(0, 0, 70, 150, -30, 30, 2, 8, 'red');
rc_draw_arc_segments(0, 0, 90, 180, -10, 0, 2, 10, 'brown');
rc_draw_arc_segments(0, 0, 120, 0, 18, 180, 1, 15, 'blue');

*/


section;

compile_mode :pop11 +strict;

uses rclib;

uses rc_graphic

uses rc_draw_arc_segment;

define rc_draw_arc_segments(xcentre, ycentre, radius, start, gap, lim, inc, width, col);
	;;; Draw sequence of segments of angular width inc, and linewidth width,
	;;; at angular locations specified by start, gap, lim

	lvars
		halfwidth = inc*0.5*sign(gap),
		ang;

	inc*sign(gap) -> inc;

	for ang from start - halfwidth by gap to lim - halfwidth do
		rc_draw_arc_segment(xcentre, ycentre, radius, ang, inc, width, col);
	endfor;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 28 2000
	Introduced halfwidth, to simply invocation for users.

 */
