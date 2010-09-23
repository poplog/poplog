/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_mouse_coords.p
 > Purpose:         Like rc_mouse_draw(true, N) but draws nothing
 > Author:          Aaron Sloman, Jun 27 1996 (see revisions)
 > Documentation:	HELP RC_MOUSE_COORDS
 > Related Files:
 */

/*
rc_destroy();
rc_start();
rc_mouse_coords(1) =>
*/

uses rclib
uses rc_graphic
uses rc_app_mouse

section;

define rc_mouse_coords(stop_button) -> list;
	;;; return a list of points got by clicking with any button
	;;; except stop_button, which indicates termination.
    [% rc_app_mouse(rc_conspoint, stop_button) %] -> list
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, 8 Apr 1997
	Redefined in terms of rc_app_mouse. Now uses rc_app_mouse_xyin

--- Aaron Sloman, Apr  4 1997
	Made it have its own user definable transxyin
*/
