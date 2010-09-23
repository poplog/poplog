/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_kill_panel.p
 > Purpose:			Kill the current panel
 > Author:          Aaron Sloman, May 20 1999 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	LIB RC_BUTTONS
 */

section;
uses rclib
uses rc_window_object
uses rc_mousepic

define rc_kill_panel();
	lvars
		old_win = rc_current_window_object;
	rc_kill_window_object(rc_active_window_object);

	;;; restore window if necessary
	if rc_islive_window_object(old_win) then
		old_win -> rc_current_window_object
	endif;
enddefine;

;;; Previous name. Should be phased out.
define rc_kill_menu = rc_kill_panel;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 14 2002
	revise the test for restoring
 */
