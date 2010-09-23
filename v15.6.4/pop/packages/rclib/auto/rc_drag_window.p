/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_drag_window.p
 > Purpose:			For making a window draggable
 > Author:          Aaron Sloman, May 20 1999 (see revisions)
 > Documentation:   See TEACH RCLIB_DEMO.P/rc_drag_window
 > Related Files:
 */

section;

define :method rc_drag_window(pic:rc_window_object, x, y, modifiers);
	;;; for draggable panels
	lvars container = rc_window_container(pic);
	rc_transxyout(x,y) -> (x,y);
	if container then
		lvars xscale,yscale;
		explode(rc_window_origin(container)) -> ( , ,xscale, yscale);
		x/xscale -> x; y/yscale -> y;
	endif;
	rc_move_by(pic, x, y, true);
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 22 1999
	take account of rc_graphic origin and scale
 */
