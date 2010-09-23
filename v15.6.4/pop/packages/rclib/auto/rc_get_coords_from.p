/* --- Copyright University of Birmingham 2006. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_get_coords_from.p
 > Purpose:			Get a location by clicking with specified mouse button on
					designated window
 > Author:          Aaron Sloman, Dec 14 1999 (see revisions)
 > Documentation:
 > Related Files:	LIB rc_get_coords
		This one has a boolean argument determining whether to warp
 */

/*

vars win1 = rc_new_window_object( 600, 20, 100, 100, true, 'win1');
rc_kill_window_object( win1);

vars p = rc_get_coords_from(win1, conspair, 1, true); p=>

repeat 5 times

	rc_get_coords_from(win1, conspair, 1, false) =>

endrepeat;


*/


compile_mode :pop11 +strict;
#_INCLUDE '$usepop/pop/lib/include/vm_flags.ph'

uses rclib
uses rc_graphic;
uses rc_app_mouse;		;;; uses rc_app_mouse_xyin
uses rc_window_object;

section;

define :method rc_get_coords_from(win:rc_window_object, pdr, button, warping);
	;;; If warping, warp mouse to the window win, and wait.
	;;; When mouse button is pressed call pdr on the current
	;;; 	x,y coordinates, then return


	lvars procedure pdr;

	checkinteger(button, 1,3);


	;;; prevent pdr and radius being treated as type 3 lexicals
	dlocal pop_vm_flags = pop_vm_flags || VM_DISCOUNT_LEX_PROC_PUSHES;

	rc_setup_linefunction();

	;;; this will set rc_window
	win -> rc_current_window_object;


	dlocal rc_sole_active_widget = win;


	;;; Prepare callback, then wait for mouse button to be pressed
	;;; NB individual callbacks cannot leave anything on stack,
	;;; so must create a list
	lvars list = [];

	;;; variable to control exit
	lvars rc_mouse_done = false;

	define lconstant handle_event(widget, item, data);
		;;; Ignore case where data < 0 (button released). Otherwise
		;;; call rc_record_mouse on transformed data
		lvars x, y;

		if (exacc ^int data ->> data) >= 0 and data == button then
			rc_app_mouse_xyin(XptVal[fast] rc_window(XtN mouseX, XtN mouseY)) -> (x, y);
			;;; apply pdr to the point, but save any results to prevent stuff
			;;; left on stack during callback
			list nc_<> [% pdr(x,y) %] -> list;
			true -> rc_mouse_done;
		endif;
	enddefine;


	XtRemoveCallback(rc_window, XtN buttonEvent, handle_event, "button");

	;;; remove doesn't work with this
	;;; XptAddCallback(rc_window, XtN buttonEvent, handle_event, "button", identfn);
	XtAddCallback(rc_window, XtN buttonEvent, handle_event, "button");

	dlocal 0 % ,
		if dlocal_context < 3 then
			[% XtRemoveCallback(rc_window, XtN buttonEvent, handle_event, "button") %] ->
		endif %;


	if warping then
		rc_warp_to(rc_window, false, false);
	endif;
	win -> rc_active_window_object;

	;;; Sleep until exitfrom
	until rc_mouse_done do syshibernate(); enduntil;

	XtRemoveCallback(rc_window, XtN buttonEvent, handle_event, "button");

	explode(list);

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 29 2006
		Derived from rc_get_coords, by adding extra boolean argument
		and assigning win to rc_active_window_object.
 */
