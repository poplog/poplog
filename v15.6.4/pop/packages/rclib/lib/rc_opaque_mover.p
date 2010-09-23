/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_opaque_mover.p
 > Purpose:			Pictures that can move without using XOR
 > Author:          Aaron Sloman, Jun 18 2000
 > Documentation:
 > Related Files:	LIB RCLIB, rc_linepic
 */

section;

uses rclib
uses rc_linepic
uses rc_defaults

define :rc_defaults;
	rc_opaque_bg_def = false;
enddefine;

define :mixin rc_opaque_movable; is rc_linepic_movable;
	;;; Extend the class to include a record of previous location.

	;;; Background colour to use when undrawing opaque object.
	;;; If false use picture background
	slot rc_opaque_bg = rc_opaque_bg_def ;

enddefine;

define :mixin rc_opaque_rotatable; is rc_opaque_movable rc_rotatable;
	slot rc_axis == 0;
	slot rc_oldaxis == false;
enddefine;

;;; setting this true changes the behaviour of the next method
global vars rc_opaque_undrawing = false;

define :method rc_set_drawing_colour(pic:rc_opaque_movable, colour, window);
	;;; opaque movable objects can ignore the colour given, and either
	;;; use a stored background colour or the picture background or
	;;; run a procedure

	;;; [setting opaque ^rc_opaque_undrawing colour ^colour]=>

	if rc_opaque_undrawing then

		lvars bg = rc_opaque_bg(pic);

		if isstring(bg) then
			bg -> rc_foreground(window)
		elseif isprocedure(bg) then
			bg(pic, colour, window)
		elseunless bg then
			;;; if it's false use current background
			rc_background(window) -> rc_foreground(window)
		else
			mishap('FALSE, STRING or PROCEDURE needed for rc_opaque_bg',
				[^bg ^pic])
		endif
		
	else
		colour -> rc_foreground(window)
	endif;
enddefine;

define :method rc_draw_linepic(pic:rc_opaque_movable);
	;;; The basic method that does the drawing of a picture
	dlocal rc_linefunction = GXcopy;
	rc_draw_lines_normal(
		rc_coords(pic), rc_pic_lines(pic), rc_pic_strings(pic), pic);

	rc_coords(pic) -> (rc_oldx(pic), rc_oldy(pic))
enddefine;

define :method rc_draw_linepic(pic:rc_opaque_rotatable);
	;;; The method that does the drawing for a rotatable object

	dlocal rc_linefunction = GXcopy;

	rc_draw_lines_rotated(
		rc_coords(pic),
		rc_pic_lines(pic),
		rc_pic_strings(pic),
		rc_axis(pic),
		pic);

	rc_coords(pic) -> (rc_oldx(pic), rc_oldy(pic));
	rc_axis(pic) -> rc_oldaxis(pic);
enddefine;
		


define :method rc_draw_oldpic(pic:rc_opaque_movable);
	;;; A method to draw the object at the old location (which will
	;;; obliterate it
	;;; Prevent re-drawing if not already drawn (rc_oldx(pic) is false)
	dlocal rc_opaque_undrawing = true;

	lvars
		oldforeground = rc_foreground(rc_window);

	dlocal
		
		0 %,if dlocal_context fi_< 3 then
				oldforeground -> rc_foreground(rc_window)
			endif%;

	if rc_oldx(pic) then

      ;;; use an embedded procedure to ensure rc_foreground_changeable
	  ;;; reset before above dlocal exit action is triggered
	  procedure();
		dlocal
            rc_foreground_changeable;

		dlocal rc_linefunction = GXcopy;

		rc_set_drawing_colour(pic, false, rc_window);

		;;; don't allow any more changes
		false -> rc_foreground_changeable;

		;;; [undrawing ^rc_opaque_undrawing, fg ^(rc_foreground(rc_window))]=>

		rc_draw_lines_normal(
			rc_oldx(pic), rc_oldy(pic),
			rc_pic_lines(pic), rc_pic_strings(pic), pic)

		endprocedure();		
	endif;

	;;; prevent redrawing
	false -> rc_oldx(pic);
enddefine;

define :method rc_draw_oldpic(pic:rc_opaque_rotatable);
	;;; As above, but for rotatable objects

	lvars
		oldforeground = rc_foreground(rc_window);

	dlocal
		0 %,if dlocal_context fi_< 3 then
				oldforeground -> rc_foreground(rc_window)
			endif%;

	dlocal rc_opaque_undrawing = true;

	if rc_oldx(pic) then

      ;;; use an embedded procedure to ensure rc_foreground_changeable
	  ;;; reset before above dlocal exit action is triggered
	  procedure();
		dlocal
            rc_foreground_changeable;

		dlocal rc_linefunction = GXcopy;

		rc_set_drawing_colour(pic, false, rc_window);

		;;; don't allow any more changes
		false -> rc_foreground_changeable;

		rc_draw_lines_rotated(
			rc_oldx(pic), rc_oldy(pic),
			rc_pic_lines(pic),
			rc_pic_strings(pic),
			rc_oldaxis(pic),
			pic);
	  endprocedure();
	endif;

	;;; prevent redrawing
	false -> rc_oldx(pic);

enddefine;


define :method rc_set_axis(pic:rc_opaque_rotatable, ang, draw);
	;;; Move axis to angle ang
	;;; If the final argument is non false, then draw the picture
	;;; 	moving.
	;;; If it is true obliterate old location. If it is "trail"
	;;;		then leave the old location.
	;;;	If is false don't draw.
	;;; If rc_pause_draw is true, pause after drawing.

	if draw == true then ;;; not "trail"
		rc_undraw_linepic(pic)
	endif;

	;;; Store new angle
	ang -> rc_axis(pic);
	rc_draw_linepic(pic);
	if draw then
		rc_check_pausing();
	endif;
enddefine;


;;; for uses
global vars rc_opaque_mover = true;

endsection;

/*

CONTENTS

 define :rc_defaults;
 define :mixin rc_opaque_movable; is rc_linepic_movable;
 define :mixin rc_opaque_rotatable; is rc_opaque_movable rc_rotatable;
 define :method rc_set_drawing_colour(pic:rc_opaque_movable, colour, window);
 define :method rc_draw_linepic(pic:rc_opaque_movable);
 define :method rc_draw_linepic(pic:rc_opaque_rotatable);
 define :method rc_draw_oldpic(pic:rc_opaque_movable);
 define :method rc_draw_oldpic(pic:rc_opaque_rotatable);
 define :method rc_undraw_linepic(pic:rc_opaque_movable);
 define :method rc_undraw_linepic(pic:rc_opaque_rotatable);

*/
