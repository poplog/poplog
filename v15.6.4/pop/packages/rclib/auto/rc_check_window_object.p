/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:			$local/rclib/auto/rc_check_window_object.p
 > Purpose:			Check rc_current_window_object
 > Author:			Aaron Sloman, Jul 28 2002
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RC_WINDOW_OBJECT
 */

section;

compile_mode :pop11 +strict;


define rc_check_window_object();
	lvars win_obj = rc_current_window_object;

	unless rc_islive_window_object(win_obj) then
		mishap('LIVE rc_current_window_object needed', [^win_obj])
	endunless;

enddefine;

endsection;
