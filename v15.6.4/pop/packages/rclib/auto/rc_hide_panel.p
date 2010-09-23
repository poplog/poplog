/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_hide_panel.p
 > Purpose:			Unmap the current panel
 > Author:          Aaron Sloman, May 20 1999 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:   LIB RC_BUTTONS
 */

section;

uses rclib
uses rc_window_object
uses rc_mousepic

;;; Two useful button actions
define rc_hide_panel();
	lvars
		old_win = rc_current_window_object;

	rc_hide_window(rc_active_window_object);

	;;; restore window if necessary
	unless old_win == rc_current_window_object then
		old_win -> rc_current_window_object
	endunless;

enddefine;

;;; Previous name. Should be phased out.
define rc_hide_menu = rc_hide_panel;
enddefine;



endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Oct 10 1999
	Moved out or lib rc_buttons
 */
