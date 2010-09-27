/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_shift_window_frame_by.p
 > Purpose:			Shift coordinate frame in a window object
 > Author:          Aaron Sloman, Jul  6 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:
 */

/*
;;; TEST
uses rclib;
uses rc_window_object;

vars win1 = rc_new_window_object("right", "top", 300, 250, true, 'win1');


define :class dragpic;
    ;;; this class inherits from three different "mixins"
    is rc_keysensitive rc_selectable rc_linepic_movable;

	;;; make it easier to move instances
	slot rc_mouse_limit = 50;

enddefine;

define :instance pic1:dragpic;
    ;;; location of the picture's reference frame origin
    rc_picx = 100;
    rc_picy = 50;

    rc_pic_lines =
        [WIDTH 2 COLOUR 'blue'
            [SQUARE {-40 40 80}]
            [CLOSED {-45 20} {45 20} {45 -20} {-45 -20}]
        ];
enddefine;

define :instance pic2:dragpic;
    ;;; location of the picture's reference frame origin
    rc_picx = -100;
    rc_picy = 50;

    rc_pic_lines =
        [WIDTH 2 COLOUR 'red'
            [SQUARE {-40 40 80}]
            [CLOSED {-45 20} {45 20} {45 -20} {-45 -20}]
        ];
enddefine;


win1 -> rc_current_window_object;
rc_draw_linepic(pic1);
rc_draw_linepic(pic2);

rc_add_pic_to_window(pic1, win1, true);
rc_add_pic_to_window(pic2, win1, true);

rc_shift_window_frame_by(10, 10, win1);
rc_shift_window_frame_by(-10, -10, win1);

rc_window_origin(win1) =>
*/

section;

define :method rc_shift_window_frame_by(x, y, win_obj:rc_window_object);

	dlocal rc_current_window_object = win_obj;

	;;; vectors holding the current window coordinate information
	lvars
		vec1 = rc_window_frame(win_obj),
		vec2 = rc_window_origin(win_obj) ;

	;;; remove all objects
	applist(rc_window_contents(win_obj), rc_undraw_linepic);
	;;; shift the origin
	rc_shift_frame_by(x, y);
	;;; redraw all objects
	applist(rc_window_contents(win_obj), rc_draw_linepic);

	;;; make sure the vectors are updated
	fill(rc_get_current_globals(rc_window), vec1) ->;

	fill(rc_xorigin, rc_yorigin, rc_xscale, rc_yscale, vec2) ->;
	
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  8 2000
	Changed to become a method
 */
