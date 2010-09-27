/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_square.p
 > Linked to:       $poplocal/local/auto/rc_draw_square.p
 > Purpose:			Draw a square taking account of coordinate frame
 > Author:          Aaron Sloman, Jan  1 1997
 > Documentation:
 > Related Files:
 */

compile_mode :pop11 +strict;

uses rc_graphic

section;

define vars rc_draw_square(x, y, side);
	;;; draw the square with x,y at centre
	rc_draw_rect(x, y, side, side)
enddefine;

endsection;
