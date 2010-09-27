/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_freezable.p
 > Purpose:			A movable object which can be frozen
 > Author:          Aaron Sloman, Nov 18 1997 (see revisions)
 > Documentation:
 > Related Files:
 */
/*
uses rc_point
;;; TEST
;;; create a window
rc_kill_window_object( win1);
vars win1 = rc_new_window_object( 600, 20, 400, 350, true, 'win1');

'grey65' -> rc_background(rc_window);

define :class freezable_point; is rc_freezable, rc_point;
enddefine;

define cons_fpoint(x,y, radius, colour) -> newpoint;
	instance freezable_point;
		rc_picx = x;
		rc_picy = y;
		rc_point_colour = colour;
		rc_mouse_limit = radius;
		rc_point_radius = radius;
	endinstance -> newpoint;

	rc_draw_linepic(newpoint);
	rc_mousepic(rc_current_window_object);
	rc_add_pic_to_window(newpoint,rc_current_window_object,true);
enddefine;


vars
	pt1 = cons_fpoint(0, 0, 26, 'red'),
	pt2 = cons_fpoint(100,100,15, 'blue');

pt1.rc_frozen=>

rc_unfreeze(pt1);
rc_unfreeze(pt2);

*/


uses rclib
uses rc_mousepic

section;


define :mixin rc_freezable; is rc_selectable;
	;;; freezable objects start off unfrozen. They can be moved until
	;;; frozen
	slot rc_frozen == false;
enddefine;

define :method rc_move_to(pic:rc_freezable, x, y, mode);
	unless rc_frozen(pic) then
		call_next_method(pic, x, y, mode)
	endunless;
enddefine;

define :method rc_freeze(pic:rc_freezable);
	dlocal Glinefunction;
	;;; Make drawing show true colours
	rc_undraw_linepic(pic);
	GXcopy -> Glinefunction;
	rc_draw_linepic(pic);
	true -> rc_frozen(pic);
enddefine;

define :method rc_unfreeze(pic:rc_freezable);
	false -> rc_frozen(pic);
enddefine;

define :method rc_draw_linepic(pic:rc_freezable);
	if rc_frozen(pic) then
		false -> rc_frozen(pic);
		rc_freeze(pic);
	else
		call_next_method(pic)
	endif;
enddefine;


define :method rc_button_1_up(pic:rc_freezable, x, y, modifiers);

	unless rc_frozen(pic) then
		call_next_method(pic, x, y, modifiers);

	rc_freeze(pic);
	endunless;
enddefine;


endsection;
/*
         CONTENTS - (Use <ENTER> gg to access required sections)

 define :mixin rc_freezable; is rc_selectable;
 define :method rc_move_to(pic:rc_freezable, x, y, mode);
 define :method rc_freeze(pic:rc_freezable);
 define :method rc_unfreeze(pic:rc_freezable);
 define :method rc_button_1_up(pic:rc_freezable, x, y, modifiers);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 24 1998
	Changed so that they can be redrawn once frozen
 */
