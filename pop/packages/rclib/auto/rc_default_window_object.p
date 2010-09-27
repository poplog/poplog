/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_default_window_object.p
 > Purpose:			Provide a window which can be interrogated to find
				    font characteristics, etc.
 > Author:          Aaron Sloman, Apr 29 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
;;; TESTING
rc_default_window_object=>
rc_default_window_object.rc_widget=>

rc_default_window_object -> rc_current_window_object;
rc_drawline(0,0,5,5);
rc_window=>
200,200,false, false -> rc_window_location(rc_default_window_object);
rc_show_window(rc_default_window_object);
rc_hide_window(rc_default_window_object);
rc_kill_window_object(rc_current_window_object);
;;; then recompile this
*/


section;

uses rclib
uses rc_window_object
uses rc_window_sync

lvars default_window = false;

define active rc_default_window_object() -> win_obj;
	if default_window then
		default_window -> win_obj
	else
		procedure();
			;;; this stuff is nested to stop dlocal being invoked
			;;; after initial creation of the window
			dlocal
				rc_xorigin, rc_yorigin, rc_xscale, rc_yscale, rc_window,
				rc_current_window_object;
				;;; stop rc_current_window_object being updated
				false -> rc_window;

			;;; create invisible window object;
			rc_new_window_object(-1000, -1000, 5, 5, {0 0 1 1}) -> win_obj;
			rc_window_sync();
			win_obj -> default_window;
			rc_hide_window(win_obj);
			rc_window_sync();
		endprocedure();
	endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 15 1997
	dlocalised more variables when the default window is accessed the
	first time
 */
