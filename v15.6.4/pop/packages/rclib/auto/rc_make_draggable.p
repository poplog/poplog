/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_make_draggable.p
 > Purpose:			Make a panel draggable
 > 					This should work for stand-alone and contained panels.
 > Author:          Aaron Sloman, May 21 1999 (see revisions)
 > Documentation:	HELP RCLIB, HELP RC_CONTROL_PANEL, TEACH RCLIB_DEMO.P
 > Related Files:
 */
/*

Some of the mess below is due to the fact that the panel being made
draggable will have its own "rc" coordinate frame, and the x,y coordinates
given to the method will have been converted to the frame. The containing
panel may have a different coordinate frame. So both have to be taken
account of.

*/

section;

uses rclib
uses rc_window_object
uses rc_mousepic

define :method rc_make_draggable(win_obj:rc_window_object, button, xloc, yloc);

	checkinteger(button, 1, 3);

	define rc_drag_window(pic, x, y, modifiers, xloc, yloc);
		lvars xscale,yscale,container = rc_window_container(pic);
		rc_transxyout(x,y) -> (x,y);
		if container then		
			explode(rc_window_origin(container)) -> ( , ,xscale, yscale);
			(x-xloc)/xscale -> x; (y-yloc)/yscale -> y;
		else
			x - xloc -> x; y - yloc -> y;
		endif;
		rc_move_by(pic, x, y, true);
	enddefine;

	rc_drag_window(%xloc, yloc%) -> rc_drag_handlers(win_obj)(button);
	unless lmember("motion", rc_event_types(win_obj)) then
		rc_mousepic(win_obj,[motion])
	endunless;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 25 1999
	Changed to make the draggable object motion sensitive if necessary.
--- Aaron Sloman, May 22 1999
	Changed to take account of coordinate frame of enclosing window.
 */
