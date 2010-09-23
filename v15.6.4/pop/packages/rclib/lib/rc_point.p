/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_point.p
 > Purpose:			Define point structure, e.g. for use as line end
 > Author:          Aaron Sloman, 27 Mar 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
;;; Basic Tests. See also HELP RC_POINT

uses rclib
uses rc_window_object;

vars win1 = rc_new_window_object( 600, 20, 300, 250, true, 'win1');
rc_kill_window_object( win1);

rc_mousepic(win1);

vars pt1 = rc_cons_point(0, 0, 6), pt2 = rc_cons_point(100,100,15);

pt1 ,pt2 =>

'red' -> rc_point_colour(pt2);

rc_draw_linepic(pt1);
rc_draw_linepic(pt2);

rc_undraw_linepic(pt2);
'pt2' -> rc_point_string(pt2);
4 -> rc_point_linewidth(pt2);
rc_draw_linepic(pt2);

rc_move_to(pt2, -50, 50, true);

pt2.datalist ==>
rc_undraw_linepic(pt1);
rc_undraw_linepic(pt2);

define CROSS(size);
	;;; procedure to draw a cross at the centre of a "point"
	rc_drawline(-size, 0, size, 0);
	rc_drawline(0, -size, 0, size)
enddefine;

CROSS(10);

vars
	p1 = rc_new_live_point(0, 0, 6, 'a'),
	p2 = rc_new_live_point(0, 50, 'red', 7, 'b'),
	p3 = rc_new_live_point(0, -50, 15, false,
		[COLOUR 'blue' WIDTH 2 [{-5 0} {5 0}] [{0 -5} {0 5}]]),
	p4 = rc_new_live_point(-50, 25, 'blue', 20, false,
		[COLOUR 'blue' WIDTH 2 [^(CROSS(%5%))]]),
;

;;;Move the points around then print them out
p1,p2,p3,p4 =>
p3.datalist ==>

applist([%p1, p2, p3, p4%], rc_kill_point);

vars ang;
for ang from 0 by 5 to 720 do
	rc_move_to(p1, 100*cos(ang), 100*sin(ang), true);
	rc_move_to(p2, 80*cos(2*ang), 80*sin(2*ang), true);
	rc_move_to(p3, 50*cos(3*ang), 50*sin(3*ang), true);
	syssleep(1);
endfor;


[%p1, p2, p3%] ==>

rc_move_to(p3,0,0,true);

rc_kill_point(p1);
rc_kill_point(p2);
rc_kill_point(p3);

applist([%rc_get_mouse_points(win1, 8, identfn, 3)%], rc_undraw_linepic);

rc_get_mouse_points(win1, 8, procedure(p); p endprocedure, 3) =>

vars point_counter = 0;
rc_get_mouse_points(win1, 7,
	procedure(p)->p;
		rc_undraw_linepic(p);
		consstring(`a` + point_counter, 1) -> rc_point_string(p);
		rc_draw_linepic(p);
		(point_counter + 1) mod 26 -> point_counter;
	endprocedure, 3) =>


rc_kill_window_object( win1);
*/

compile_mode :pop11 +strict;

#_INCLUDE '$usepop/pop/lib/include/vm_flags.ph'
section;

uses rclib
uses rc_linepic
uses rc_mousepic
uses rc_app_mouse
global vars
	;;; Sensitive radius for points
	rc_default_point_radius = 5,

	;

define :class rc_point;
	;;; The basic class for points. Each point is drawn by the procedure rc_DRAWPOINT
	;;; defined below. It uses the rc_mouse_limit and rc_point_linewidth slots.

    is rc_selectable rc_linepic_movable;

	slot rc_mouse_limit = rc_default_point_radius;
	slot rc_point_radius = rc_default_point_radius;
	slot rc_point_linewidth = 2;
	slot rc_point_colour = false;
	slot rc_point_string = false;
	;;; To change the appearance of a point alter rc_pic_lines or
	;;; redefine rc_DRAWPOINT.

    ;;; This slot can be given a list, to draw something more complex
    ;;; than a circle with a string label
	slot rc_pic_lines == "rc_DRAWPOINT";
enddefine;

define rc_DRAWPOINT(pic);
	;;; used to draw points.
	dlocal %rc_line_width(rc_window)%;
	dlocal %rc_foreground(rc_window)%;

	rc_point_linewidth(pic) -> rc_line_width(rc_window);

	lvars colour = rc_point_colour(pic);

	if colour then colour -> rc_foreground(rc_window); endif;

	rc_draw_circle(0, 0, rc_point_radius(pic));
	lvars string = rc_point_string(pic);
	if string then
		rc_print_at(-(datalength(string)*6*0.5)/rc_xscale, 3/rc_yscale, string)
	endif;
enddefine;

define :method print_instance(p:rc_point);
	lvars string = rc_point_string(p);
	unless string then nullstring -> string endunless;
    printf('<point %P %P %P>', [%string, rc_coords(p) %])
enddefine;

define rc_cons_point(x,y, radius) -> newpoint;
	instance rc_point;
		rc_picx = x;
		rc_picy = y;
		rc_mouse_limit = radius;
		rc_point_radius = radius;
	endinstance -> newpoint;
enddefine;

define rc_new_live_point(x, y, /*colour*/, radius, string, /*list*/) -> newpoint;
	;;; allow extra list argument to be added to drawing instructions
	;;; allow optional string to specify colour, after x, y,
	lvars list, colour;
	if islist(string) then
		x, y, radius, string -> (x, y, radius, string, list)
	else
		false -> list;
	endif;

	if isstring(y) then
		x, y -> (x, y, colour);
	else
		false -> colour;
	endif;

	rc_cons_point(x, y, radius) -> newpoint;
    ;;; If string is false, nothing will be drawn.
	string -> rc_point_string(newpoint);

	if colour then colour -> rc_point_colour(newpoint) endif;

	lvars pic_lines = recursive_valof(rc_pic_lines(newpoint));
	if islist(list) then
		;;; add the extra drawing instructions
		if islist(pic_lines) then
			[[^rc_pic_lines] ^list]
		else
			;;; it should be a procedure
			[[^(pic_lines(%newpoint%))] ^list]
		endif -> rc_pic_lines(newpoint);
	endif;

	rc_add_pic_to_window(newpoint, rc_current_window_object, true);
	rc_draw_linepic(newpoint)
enddefine;

define rc_kill_point(point);
	rc_undraw_linepic(point);
	rc_remove_pic_from_window(point, rc_current_window_object);
enddefine;


define :method rc_get_mouse_points(win_obj:rc_window_object, radius, pdr, stop_button);
	;;; use mouse clicks to create points at the locations pointed at
	;;; stop_button specifies last point. Each point is created using
	;;; rc_cons_point, and pdr is then applied to it.

	;;; prevent pdr and radius being treated as type 3 lexicals
	dlocal pop_vm_flags = pop_vm_flags || VM_DISCOUNT_LEX_PROC_PUSHES;

	rc_setup_linefunction();

	win_obj -> rc_current_window_object;

	;;; Make sure the window object is mouse sensitive
	rc_mousepic(win_obj);

	rc_app_mouse(
		procedure(x,y);
			pdr(rc_new_live_point(x, y, radius, false))
		endprocedure,
		stop_button)

enddefine;

endsection;

global vars rc_point = true;	;;; for uses

nil -> proglist;

/*
CONTENTS -

 define CROSS(size);
 define :class rc_point;
 define rc_DRAWPOINT(pic);
 define :method print_instance(p:rc_point);
 define rc_cons_point(x,y, radius) -> newpoint;
 define rc_new_live_point(x, y, /*colour*/, radius, string, /*list*/) -> newpoint;
 define rc_kill_point(point);
 define :method rc_get_mouse_points(win_obj:rc_window_object, radius, pdr, stop_button);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 10 1997
	Redefined rc_DRAWPOINT to take a picture object as argument, in accordance
	with change to rc_linepic
	Also made it use rc_line_width, instead of rc_linewidth.
--- Aaron Sloman, Jun 11 1997
	Introduced rc_point_colour slot, and extended rc_new_live_point
	to allow optional string argument.

--- Aaron Sloman, Jun 10 1997
	Fixed handling of non-unity scale values.
	
--- Aaron Sloman, Jun  9 1997
	made it possible to add extra drawing instructions in rc_new_live_point
	Added rc_point_radius
--- Aaron Sloman, Jun  3 1997
	Changed rc_DRAWPOINT to take account of rc_xscale and rc_yscale
--- Aaron Sloman, Apr  9 1997
	Changed structure to use rc_DRAWPOINT
--- Aaron Sloman, Mar 25 1997
 */
