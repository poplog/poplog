/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_Rrect.p
 > Linked to:       $poplocal/local/auto/rc_draw_Rrect.p
 > Purpose:			Draw a rotatable rectangle taking account of coordinate frame
 > Author:          Aaron Sloman, Jan  1 1997
 > Documentation:
 > Related Files:
 */

compile_mode :pop11 +strict;

uses rc_graphic

section;

define vars rc_draw_Rrect(x, y, width, height);
	;;; a rotatable rectangle
	lvars xmax = x + width, ymin = y - height;
	rc_drawline(x, y, xmax, y);
	rc_drawline(xmax, y, xmax, ymin);
	rc_drawline(xmax, ymin, x, ymin);
	rc_drawline(x, ymin, x, y);
enddefine;

endsection;
