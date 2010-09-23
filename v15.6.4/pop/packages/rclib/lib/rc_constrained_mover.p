/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_constrained_mover.p
 > Purpose:         Create a mover that is constrained to a line between two points,
 > 					or the inside of a rectangle, or circle, etc.
 > Author:          Aaron Sloman, Jan  9 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
NB STILL UNDER DEVELOPMENT
Testing:

	uses rclib
	uses rc_mousepic;
    vars movewin = rc_new_window_object(600, 40, 400, 300, true, 'movewin');
	rc_mousepic(movewin);
/*
	rc_kill_window_object(movewin);
*/
define :class hor_dragpic;
	is rc_horiz_constrained_mover rc_selectable;
    ;;; default name dragpic1, dragpic2, etc.
    slot pic_name = gensym("horiz");
enddefine;

define :instance hor1:hor_dragpic;
    rc_picx = 100;
    rc_picy = 50;
    rc_pic_lines =
        [WIDTH 2 COLOUR 'black'
            [SQUARE {-25 25 50}]
            [CLOSED {-30 20} {30 20} {30 -20} {-30 -20}]
        ];
    rc_pic_strings =
    [[FONT '9x15bold' COLOUR 'red' {-22 -5 'horiz'}]];
enddefine;

	movewin -> rc_current_window_object;
	rc_draw_linepic(hor1);
    rc_add_pic_to_window(hor1, movewin, true);
	;;; try dragging it
	rc_move_to(hor1, 200,50, true);
	repeat 60 times rc_move_by(hor1, -2,-2, true) endrepeat;
	hor1=>

define :class vert_dragpic;
	is rc_selectable rc_vert_constrained_mover;
    ;;; default name dragpic1, dragpic2, etc.
    slot pic_name = gensym("vert");
enddefine;

define :instance vert1:vert_dragpic;
    rc_picx = 100;
    rc_picy = 50;
    rc_pic_lines =
        [WIDTH 2 COLOUR 'black'
            [SQUARE {-25 25 50}]
            [CLOSED {-30 20} {30 20} {30 -20} {-30 -20}]
        ];
    rc_pic_strings =
    [[FONT '9x15bold' COLOUR 'red' {-22 -5 'vert'}]];
enddefine;

	movewin -> rc_current_window_object;
	rc_draw_linepic(vert1);
    rc_add_pic_to_window(vert1, movewin, true);
	;;; try dragging it
	rc_move_to(vert1, 200,50, true);
	repeat 60 times rc_move_by(vert1, -2,-2, true) endrepeat;
	vert1=>


define :class ptcons_dragpic;
	is rc_selectable rc_point_constrained_mover;
    slot pic_name = gensym("ptcons");
enddefine;


define :instance ptcons1:ptcons_dragpic;
    rc_picx = -90;
    rc_picy = 90;
	rc_pic_end1 = conspair(-90,90);
	rc_pic_end2 = conspair(90,-90);
    rc_pic_lines =
        [WIDTH 2 COLOUR 'black'
            [SQUARE {-25 25 50}]
            [CLOSED {-30 20} {30 20} {30 -20} {-30 -20}]
        ];
    rc_pic_strings =
    [[FONT '9x15bold' COLOUR 'red' {-22 -5 'ptcons'}]];
enddefine;

ptcons1 =>

rc_drawline(-90, 90, 90,-90);

movewin -> rc_current_window_object;
rc_draw_linepic(ptcons1);
rc_add_pic_to_window(ptcons1, movewin, true);
;;; try dragging it
rc_move_to(ptcons1, 0,50, true);

rc_oldx(ptcons1) =>

repeat 60 times rc_move_by(ptcons1, -2,5, true) endrepeat;
false -> rc_line_orientation(ptcons1);
rc_line_orientation(ptcons1) =>
ptcons1=>




*/


uses rclib
uses rc_linepic
uses rc_mousepic

;;; vars procedure arc;	;;; needed for the geometry package
;;; uses geometry	;;; geometry package

section;


;;; compile_mode :pop11 +strict;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;



define :mixin vars rc_constrained_mover; is rc_linepic_movable;
	slot rc_constraint = procedure(p, x, y);
							mishap('No motion constraint defined for', [^p])
						 endprocedure;
	slot rc_keypress_handler = "rc_key_do_nothing";
enddefine;


define :method rc_key_do_nothing(b:rc_constrained_mover, x, y, modifiers, key);
	;;; default event handler
enddefine;

define :mixin rc_horiz_constrained_mover; is rc_constrained_mover;
enddefine;

define :method rc_move_to(pic:rc_horiz_constrained_mover, x, y, mode);
	;;; ignore y, i.e. do not allow picy to change, only picx
	call_next_method(pic, x, rc_picy(pic), mode)
enddefine;

define :mixin rc_vert_constrained_mover; is rc_constrained_mover;
enddefine;

define :method rc_move_to(pic:rc_vert_constrained_mover, x, y, mode);
	;;; ignore x, i.e. do not allow picx to change, only picy
	call_next_method(pic, rc_picx(pic), y, mode)
enddefine;

define :mixin rc_point_constrained_mover; is rc_constrained_mover;
	slot rc_pic_end1; 	;;; a pair of coordinates
	slot rc_pic_end2;	;;; another
	;;; line slot will be given a vector containing cos, sin length
	;;; of vector from end1 to end2
	slot rc_line_orientation = false;
	slot rc_line_length = false;
enddefine;

define lconstant orientation_record(x1, y1, x2, y2) -> vec;
	if x1 = x2 and y1 = y2 then
		mishap('Points too close', [% x1, y1, x2, y2 %])
	endif;

	lvars
		dist = rc_distance(x1, y1, x2, y2),
		linecos = (x2 - x1) /dist, linesin= (y2 - y1)/dist,
		;
	{^linecos ^linesin} -> vec;
enddefine;


define rc_project_point(x, y, x1, y1, linecos, linesin) -> (x,y);
	;;; project point x, y, onto the line through x1, y1, with orientation
	;;; defined by linecos, linesin. This algorithm gives an accurate projection
	;;; ONLY where x, y is already on the line, and in some other special cases,
	;;; e.g. where the line is horizontal or vertical. However, the closer x,y is
	;;; to the line, the more accurate the result. This is probably good enough
	;;; for constraining a point moved by the mouse to lie on the line, e.g.
	;;; finding a slider location.
	lvars dist = rc_distance(x1, y1, x, y);	
	x1+dist*linecos, y1+dist*linesin -> (x,y)
enddefine;

define :method rc_initialise_mover(pic:rc_point_constrained_mover);
	;;; make sure that line orientation and length information have been set up

	lvars end1=rc_pic_end1(pic), end2 =rc_pic_end2(pic);
	orientation_record(explode(end1),explode(end2))
		-> rc_line_orientation(pic);

	rc_distance(explode(end1),explode(end2)) -> rc_line_length(pic);

enddefine;

define :method rc_move_to(pic:rc_point_constrained_mover, x, y, mode);
	;;; force pic to move only between end1 and end2, by projecting
	;;; x,y onto the line between them
	lvars
		end1=rc_pic_end1(pic), end2 =rc_pic_end2(pic),
		line = rc_line_orientation(pic),
		xmin, ymin, xmax, ymax;

	unless line then
		rc_initialise_mover(pic);
		rc_line_orientation(pic) -> line;
	endunless;

	explode(end1) -> (xmin,ymin); explode(end2) -> (xmax,ymax);
	min(xmin,xmax), max(xmin,xmax) -> (xmin,xmax);
	min(ymin,ymax), max(ymin,ymax) -> (ymin,ymax);
	if x > xmax then xmax elseif x < xmin then xmin else x endif -> x;
	if y > ymax then ymax elseif y < ymin then ymin else y endif -> y;

	call_next_method(pic,
		rc_project_point(x, y, explode(end1), explode(line)), mode)
enddefine;

;;; for uses
vars rc_constrained_mover = true;

endsection;

[] -> proglist;

/*
         CONTENTS

 define :class hor_dragpic;
 define :instance hor1:hor_dragpic;
 define :class vert_dragpic;
 define :instance vert1:vert_dragpic;
 define :class ptcons_dragpic;
 define :instance ptcons1:ptcons_dragpic;
 define :mixin rc_constrained_mover; is rc_linepic_movable;
 define :method rc_key_do_nothing(b:rc_constrained_mover, x, y, modifiers, key);
 define :mixin rc_horiz_constrained_mover; is rc_constrained_mover;
 define :method rc_move_to(pic:rc_horiz_constrained_mover, x, y, mode);
 define :mixin rc_vert_constrained_mover; is rc_constrained_mover;
 define :method rc_move_to(pic:rc_vert_constrained_mover, x, y, mode);
 define :mixin rc_point_constrained_mover; is rc_constrained_mover;
 define lconstant orientation_record(x1, y1, x2, y2) -> vec;
 define rc_project_point(x, y, x1, y1, linecos, linesin) -> (x,y);
 define :method rc_initialise_mover(pic:rc_point_constrained_mover);
 define :method rc_move_to(pic:rc_point_constrained_mover, x, y, mode);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Apr  3 1999
	exported rc_project_point, for use in rc_slider.
--- Aaron Sloman, Mar 28 1999
	added method rc_initialise_mover (so that it is no longer necessary to
	use rc_move to to initialise)
--- Aaron Sloman, Jul  1 1997
	Updated table of contents. This is now used in rc_slider.p
--- Aaron Sloman, Jan 22 1997
	Removed dummy class. Not needed anymore
 */
