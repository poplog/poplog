/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_Rsquare.p
 > Linked to:       $poplocal/local/auto/rc_draw_Rsquare.p
 > Purpose:			Draw a rotatable square taking account of coordinate frame
 > Author:          Aaron Sloman, Jan  1 1997
 > Documentation:
 > Related Files:
 */

compile_mode :pop11 +strict;

uses rc_graphic

section;
	
define vars rc_draw_Rsquare(x, y, side);
	;;; draw the rotatable rectangle  with centre at x,y
	rc_draw_Rrect(x, y, side, side)
enddefine;
	

endsection;
