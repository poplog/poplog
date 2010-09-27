/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_rotate_vector.p
 > Purpose:			Rotate a vector given an angle
 > Author:          Aaron Sloman, Jun 21 2000
 > Documentation:
 > Related Files:
 */

/*

;;; TESTS
rc_rotate_vector(10,0,90)=>
rc_rotate_vector(10,0,45)=>
rc_rotate_vector(10,0,-45)=>
rc_rotate_vector(10,0,270)=>
rc_rotate_vector(10,0,180)=>

rc_rotate_vector(10,10,90)=>
rc_rotate_vector(10,10,45)=>
rc_rotate_vector(10,10,-45)=>

rc_rotate_vector(0,10,90)=>
rc_rotate_vector(0,10,45)=>
rc_rotate_vector(0,10,-45)=>

rc_rotate_vector(-10,10,90)=>
rc_rotate_vector(-10,10,45)=>
rc_rotate_vector(-10,10,-45)=>


*/

section;
compile_mode:pop11 +strict;


define rc_rotate_vector(x, y, ang) -> (x, y);
	;;; Takes two numbers (user co-ordinates) and returns two
	;;; new numbers, corresponding to rotation by ang
	lvars
		x,y
		angcos = cos(ang),
		angsin = sin(ang);

	;;; First rotate about user origin
	x * angcos - y * angsin, x * angsin + y * angcos -> (x, y)
enddefine;


endsection;
