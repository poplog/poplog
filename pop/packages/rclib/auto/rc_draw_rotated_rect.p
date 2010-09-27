/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_rotated_rect.p
 > Purpose:         Conveniently draw a rotated rectangle, given angle,length,width
 > Author:          Aaron Sloman, Mar 11 2001
 > Documentation:	HELP rclib
 > Related Files:
 */
/*

rc_start();
;;; rc_draw_rotated_rect(x, y, ang, len, height, colour);
rc_draw_blob(0, 0, 25, 'green');
rc_draw_rotated_rect(0, 0, 0, 50, 5, 'blue');
rc_draw_rotated_rect(0, 0, 45, 50, 5, 'red');
rc_draw_rotated_rect(0, 0, 90, 50, 5, 'pink');
rc_draw_rotated_rect(100, 0, 45, 60, 5, 'blue');
rc_draw_rotated_rect(100, 0, -45, 60, 5, 'red');

rc_draw_rotated_rect(-100, -50, 0, 200, 5, 'blue');
rc_draw_rotated_rect(-100,-50, -45, 200, 5, 'red');

rc_draw_blob(-100,-50, 100, 'green');
for x from 0 by 5 to 360 do
	rc_draw_rotated_rect(-100,-50, x, 200, 5, 'red');
endfor;

*/

section;

compile_mode :pop11+strict;

define rc_draw_rotated_rect(x, y, ang, len, height, colour);
	dlocal
		(rc_xorigin, rc_yorigin) = rc_transxyout(x, y),
		rc_frame_angle = ang,
		rc_transxyout = rc_rotate_coords_rounded,
		;
	rc_draw_filled_centred_rect(0, 0, len, height, colour);
	
enddefine;

endsection;
