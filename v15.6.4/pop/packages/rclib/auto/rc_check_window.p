/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_check_window.p
 > Purpose:			Check for live window object or widget
 > Author:          Aaron Sloman, Aug  4 1997 (see revisions)
 > Documentation:
 > Related Files:
 */


section;
compile_mode :pop11 +strict;
uses rclib
;;; uses rc_window_object (not needed now)
uses isrc_window_object;	;;; get temporary version if necessary

define rc_check_window(win);
	lvars widget =
		if isrc_window_object(win) then rc_widget(win) else win endif;

	unless XptIsLiveType(widget, "Widget") then
		mishap('LIVE WINDOW OR WINDOW OBJECT NEEDED',[^win])
	endunless

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  5 1997
	Changed to use temporary version of isrc_window_object and rc_widget
	in case used without rest of RCLIB
 */
