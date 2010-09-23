/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_redraw_this_panel.p
 > Purpose:			Redraw the current window object
 > Author:          Aaron Sloman, 26 Jul 2002
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RC_BUTTONS
 */

section;
uses rclib
uses rc_window_object
uses rc_mousepic

define rc_redraw_this_panel();
	lvars
		old_win = rc_current_window_object;

	rc_redraw_window_object(rc_active_window_object);

	;;; restore window if necessary
	unless old_win == rc_active_window_object then
		old_win -> rc_current_window_object
	endunless;
enddefine;

endsection;
