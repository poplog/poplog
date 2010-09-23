/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_make_current_window.p
 > Purpose:			To enable action buttons to make a window current
 > Author:          Aaron Sloman, Feb 20 2000
 > Documentation:	HELP RCLIB, RC_CONTROL_PANEL, RC_BUTTONS
 > Related Files:	LIB * rc_mousepic
 */



section;
uses rclib
uses rc_mousepic

define rc_make_current_window(win_obj);
	;;; put an action to make win_obj the current window object onto
	;;; the defer list. See LIB * rc_mousepic for details of rc_defer_apply
	rc_defer_apply(
		procedure(win_obj);
			win_obj -> rc_current_window_object
		endprocedure(%win_obj%))
enddefine;


endsection;
