/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_reset_panel.p
 > Purpose:			In conjunction with rc_control_panel, resets the panel frame
 > Author:          Aaron Sloman, Aug  1 1997
 > Documentation:
 > Related Files:
 */

/*
;;; tests

vars vec = rc_window_frame(rc_current_panel);
vec =>
rc_xorigin=>

rc_reset_panel(rc_current_panel);

*/

section;

uses rclib;
uses rc_control_panel


define rc_reset_panel(panel);
	lvars
		oldwin_obj = rc_current_window_object,
		vec = rc_window_frame(panel),
		(, , w,h) = rc_window_location(panel);
	panel -> rc_current_window_object;
	0 ->> rc_xorigin ->>rc_yorigin ->> vec(1) -> vec(2);
	1 ->> rc_xscale ->>rc_yscale ->> vec(3) -> vec(4);
	w ->> rc_xmax -> vec(11);
	h ->> rc_ymax -> vec(12);

	oldwin_obj -> rc_current_window_object;

enddefine;

endsection;
