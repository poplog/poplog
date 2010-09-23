/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_app_mouse.p
 > Purpose:         Apply a procedure to locations selected by mouse
 > Author:          Aaron Sloman, 8 Apr 1997 (see revisions)
 > Documentation:   HELP * RC_APP_MOUSE
 > Related Files:  LIB * RC_MOUSE, * RC_MOUSE_COORDS
 */

/*
rc_destroy();
false ->rc_window;
rc_start();
rc_app_mouse(conspair, 1) =>
*/

compile_mode :pop11 +strict;

uses rc_graphic;

section;

define vars procedure rc_app_mouse_xyin( x, y ) /* -> (x, y) */;
	;;; This is the default procedure for transforming absolute pixel
	;;; coordinates to relative coordinates

	;;; Warning - this can produce ratios as results
	;;; Warning. Must be replaced by rc_rotate_xyin if lib rc_rotate_xy used.

	if rc_xscale == 1 or rc_xscale = 1.0 then
		x - rc_xorigin
	elseif rc_xscale == -1 or rc_xscale = -1.0 then
		rc_xorigin - x
	else
		(x - rc_xorigin) / rc_xscale
	endif; /* -> x */

	if rc_yscale == 1 or rc_yscale = 1.0 then
		y - rc_yorigin
	elseif rc_yscale == -1 or rc_yscale = -1.0 then
		rc_yorigin - y
	else
		(y - rc_yorigin) / rc_yscale
	endif; /* -> y */
enddefine;


define rc_app_mouse(pdr, stop_button);
	;;; Whenever mouse button is pressed call pdr
	;;; if stop_button is raised, then exit
	lvars procedure pdr;

	checkinteger(stop_button, 1,3);


	;;; NB individual callbacks cannot leave anything on stack,
	;;; so must create a list
	lvars list = [];

	;;; variable to control exit
	lvars rc_mouse_done = false;

	define lconstant handle_event(widget, item, data);
		;;; Ignore case where data < 0 (button released). Otherwise
		;;; call rc_record_mouse on transformed data
		lvars x, y;

		if (exacc ^int data ->> data) >= 0 and data /== stop_button then
			rc_app_mouse_xyin(XptVal[fast] rc_window(XtN mouseX, XtN mouseY)) -> (x, y);
			;;; apply pdr to the point, but save any results to prevent stuff
			;;; left on stack during callback
			list nc_<> [% pdr(x,y) %] -> list;
		endif;
		if data == -stop_button then
			true -> rc_mouse_done;
		endif
	enddefine;

	XtRemoveCallback(rc_window, XtN buttonEvent, handle_event, "button");

	;;; remove doesn't work with this
	;;; XptAddCallback(rc_window, XtN buttonEvent, handle_event, "button", identfn);
	XtAddCallback(rc_window, XtN buttonEvent, handle_event, "button");

	dlocal 0 % ,
		if dlocal_context < 3 then
			[% XtRemoveCallback(rc_window, XtN buttonEvent, handle_event, "button") %] ->
		endif %;

	;;; Sleep until exitfrom
	until rc_mouse_done do syshibernate(); enduntil;
	XtRemoveCallback(rc_window, XtN buttonEvent, handle_event, "button");

	explode(list);
	sys_grbg_list(list);
	[] -> list;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr  8 1997
	Changed not to call the procedure when the stop button is invoked
*/
