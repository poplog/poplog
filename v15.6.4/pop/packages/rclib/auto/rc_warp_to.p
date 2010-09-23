/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_warp_to.p
 > Author:          Aaron Sloman, May  4 1997 (see revisions)
 > Purpose:			Warp mouse pointer to centre of a widget
 > Related Files:	(based on LIB * PUI_POPUPTOOL)
 */


compile_mode :pop11 +strict;


/*
TEST commands

vars mybox=propsheet_new_box('Properties', false, false, [A B  Dismiss]);
XtRealizeWidget(mybox);
propsheet_show(mybox);

rc_warp_to(false, 1,1);
rc_warp_to(false, -100,-100);

repeat 30 times
	rc_warp_to(false, -1,0);
	syssleep(40)
endrepeat;

rc_warp_to(mybox, false,1);
rc_warp_to(mybox, 1,false);
rc_warp_to(mybox, 180,40);

*/

section;

uses xt_display
uses xt_widgetinfo

;;; Copied from system sources

/* Xlib procedures to manage windows */
XptLoadProcedures 'rc_warp'
	lvars XWarpPointer	;;; Warp the pointer to the popup
;

define vars procedure rc_warp_to(widget, x, y);
	;;; Warp mouse pointer to location on widget or win_obj
	;;; If x is false go to middle of width. if y is false go half way down.

	if isrc_window_object(widget) then rc_widget(widget) -> widget endif;

	lvars
		dpy = if widget then XtDisplay(widget) else XptDefaultDisplay endif,
		win = if widget then XtWindow(widget) else 0 endif,
		(,,w,h)= if widget then XptWidgetCoords(widget) else 0,0,0,0 endif;

	unless x then w div 2 -> x endunless;
	unless y then h div 2 -> y endunless;
	exacc (9) raw_XWarpPointer(dpy, 0, win, 0,0,0,0, x, y);
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 28 1999
	Generalised to allow false for the widget. Then it moves pointer relative
	to current location.
 */
