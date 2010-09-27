/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_rect.p
 > Linked to:       $poplocal/local/auto/rc_draw_rect.p
 > Purpose:			Draw a rectangle taking account of coordinate frame
 > Author:          Aaron Sloman, Jan  1 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

compile_mode :pop11 +strict;

uses rc_graphic

section;

define vars rc_draw_rect(x, y, width, height);
	;;; draw rect with top left corner at centre x, y,
	;;; with given width and height
	round(abs(width * rc_xscale)) -> width;
	round(abs(height * rc_yscale)) -> height;

	;;; first get new x, y coordinates of top left corner(pixel coords)
	rc_transxyout(x, y) -> (x, y);

	XpwDrawRectangle(
		rc_window, x, y, width, height)
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  7 1997
	removed redundant 'abs' and fixed comment
--- Aaron Sloman, Apr 21 1997
	fixed to work with positive rc_yscale.
 */
