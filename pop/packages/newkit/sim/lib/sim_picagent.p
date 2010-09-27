/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/sim/lib/sim_picagent.p
 > Purpose:			Define classes and utilities for pictorial agents
 > Author:          Aaron Sloman, Feb 24 1999 (see revisions)
 > Documentation:   HELP RCLIB, HELP SIM_PICAGENT, HELP SIM_AGENT
 > Related Files:	LIB * rclib, LIB * SIM_AGENT
 */

/*
See HELP SIM_PICAGENT

This definess variants of the classes sim_object and sim_agent which are
moveable in simulation space and in a 2-D window and mouse sensitive.

CONTENTS

 -- Libraries required
 -- Mapping utilities (between simulation and picture frames)
 -- New class for multi-window objects
 -- The basic object mixin, and rc_ simulation methods
 -- -- Methods for getting and setting rc_ coordinates
 -- -- Methods for getting and setting rc_old coordinates
 -- Derived mixins
 -- -- static and mobile multwin objects
 -- Drawing methods for multiwin objects
 -- Procedures for checking which picture in a window is being acted on
 -- Adding pictures to and removing them from windows

-- Libraries required

*/

compile_mode :pop11 +strict;

section;

;;; Extend search lists
uses objectclass
uses rclib
uses simlib
uses prblib

exload_batch;
	;;; Group external loads together
	uses rc_linepic
	uses rc_window_object
	uses rc_mousepic
endexload_batch;

uses poprulebase
uses sim_agent
uses sim_geom

/*

-- Mapping utilities (between simulation and picture frames)

Make it easy to have a simulated world with a different scale and origin
from the picture scale and origin.

Variables used in determining origin and scale for mapping simulation
coordinates to picture coordinates.
*/

global vars
	;;; default frame values, for use in constructor
	sim_picxorigin_def = 0,
	sim_picyorigin_def = 0,
	sim_picxscale_def = 1,
	sim_picyscale_def = 1,
;

;;; Utility procedures for handling the transformation

;;; Two procedures for transforming between simulation coordinates
;;; and picture coordinates and vice versa (user definable)

define vars procedure sim_transxy_to_pic(x, y, frame) /* -> (x,y) */;
	;;; given x,y in simulation coordinates return picture coordinates.
	;;; User definable. Make it identfn to have no effect
	;;; Must leave numbers on stack in same order
	;;; Warning: needs to be redefined for rotations

	;;; get origin and scale from frame vector
	lvars (x0,y0,xscale,yscale) = (destvector(frame)->);

	if xscale == 1 then
		x
	else x * xscale
	endif + x0 /* -> x */ ;

	if yscale == 1 then
		y
	else y * yscale
	endif + y0 /* -> y */;
enddefine;

define vars procedure sim_transxy_from_pic(x, y, frame) /* ->(x, y) */;
	;;; Gven x,y in picture coordinates, return simulation coordinates
	;;; User definable.
	;;; Must leave numbers on stack in same order
	;;; Warning - this can produce ratios as results
	;;; Warning: needs to be redefined for rotations

	;;; get origin and scale from frame vector
	lvars (x0,y0,xscale,yscale) = (destvector(frame)->);

	;;; deal with most common case first
	if xscale == 1 then
		x - x0
	else (x - x0) / xscale
	endif; /* -> x */

	if yscale == -1 then
		y0 - y
	elseif yscale == 1 then
		y - y0
	elseif yscale = -1.0 then
		y0 - y
	elseif yscale = 1.0 then
		y - y0
	else
		(y - y0) / yscale
	endif; /* -> y */
enddefine;


/*
-- New class for multi-window objects
*/

;;; Define a type of window object which has information about its
;;; transformations stored in a vector sim_picframe(win_obj)
;;; Should this use the current defaults?

define :class sim_picagent_window; is rc_window_object;

	slot sim_picframe =
		consvector(#| sim_picxorigin_def, sim_picyorigin_def,
			sim_picxscale_def, sim_picyscale_def |#);

enddefine;


/*
-- The basic object mixin, and rc_ simulation methods

Top level link between sim_agent and rclib

The top level mixin defines objects which have two sets of coordinates,
one pair for pictures (rc_picx, rc_picy) and one pair for the simulated
2D world (sim_x, sim_y).
*/

define :mixin sim_multiwin;
	;;; The basic mixin linking simulations and drawings
	;;; for linked picture objects
    is rc_keysensitive rc_selectable rc_linepic;

	;;; initially known to contain no pictures
	slot rc_pic_containers == [];

	/*
	;;; see LIB RC_LINEPIC
	;;; These two will be simulated, derived from sim_x, sim_y
    slot rc_picx == 0;
    slot rc_picy == 0;
	*/

	;;; Two sim coordinates for location within a simulation
	slot sim_x == 0;
	slot sim_y == 0;

	;;; Two sim coordinates for old location within a simulation
	slot sim_oldx == false;
	slot sim_oldy == false;
enddefine;

/*
-- -- Methods for getting and setting rc_ coordinates
*/

define :method rc_coords(obj:sim_multiwin) -> (x, y);
    ;;; Return two numbers representing current picture location of obj
    sim_transxy_to_pic(
		sim_x(obj), sim_y(obj),
			sim_picframe(rc_current_window_object)) -> (x,y);
enddefine;

define :method rc_picx(obj:sim_multiwin) -> x;
    sim_transxy_to_pic(
		sim_x(obj), sim_y(obj),
			sim_picframe(rc_current_window_object)) -> (x,);
enddefine;

define :method rc_picy(obj:sim_multiwin) -> y;
    sim_transxy_to_pic(
		sim_x(obj), sim_y(obj),
			sim_picframe(rc_current_window_object)) -> (,y);
enddefine;

;;; The accessor of sim_coords can be applied to movable and unmovable
;;; things
define :method sim_coords(obj:sim_multiwin) -> (x, y);
    ;;; Get two numbers representing current location of obj
    sim_x(obj) -> x; sim_y(obj) -> y;
enddefine;

;;; The updater (defined later) can be applied only to movable ones.
;;; For unmovable ones use sim_set_coords

define sim_set_coords(obj, x, y);
	;;; Without updating screen, set sim_coords to x, y and
	;;; implicitly set picture coords to transformed version

	x -> sim_x(obj); y -> sim_y(obj);

enddefine;

define :method sim_distance(obj1:sim_multiwin, obj2:sim_multiwin) -> num;
    ;;; Compute distance between two sim_multiwin_mobile objects
    ;;; Used to determine whether the agent obj1 can "sense" obj2
    sim_distance_from(sim_coords(obj1), sim_coords(obj2)) -> num;
enddefine;


/*
-- -- Methods for getting and setting rc_old coordinates
*/

define lconstant get_oldxy(obj);

	lvars oldx = sim_oldx(obj), oldy = sim_oldy(obj);
	if oldx and oldy then
		sim_transxy_to_pic(oldx, oldy, sim_picframe(rc_current_window_object))
	else
		false, false
	endif

enddefine;

define lconstant set_oldxy(obj, x, y);
	;;; is this needed?
	if x then
		sim_transxy_from_pic(x, y, sim_picframe(rc_current_window_object))
		-> (sim_oldx(obj), sim_oldy(obj))
	else
		false -> sim_oldx(obj);
	endif

enddefine;


define :method rc_oldx(obj:sim_multiwin) -> x;
	get_oldxy(obj) -> (x,);
enddefine;

define :method rc_oldy(obj:sim_multiwin) -> y;
	get_oldxy(obj) -> (,y);
enddefine;

define :method updaterof rc_oldx(x, obj:sim_multiwin);
	if x then
		sim_transxy_from_pic(x, 0, sim_picframe(rc_current_window_object))
		-> (sim_oldx(obj),)
	else
		false -> sim_oldx(obj);
	endif

enddefine;

define :method updaterof rc_oldy(y, obj:sim_multiwin);
	if y then
		sim_transxy_from_pic(0, y, sim_picframe(rc_current_window_object))
		-> (,sim_oldy(obj))
	else
		false -> sim_oldy(obj);
	endif
enddefine;


/*
-- Derived mixins
*/

define :mixin sim_multiwin_static; is sim_multiwin;
	;;; for unmovable linked picture objects

    ;;; by default these are not draggable
	slot rc_drag_handlers = { ^false ^false ^false};
enddefine;

/*
;;; this should mishap
	define :method rc_move_to(pic:sim_multiwin_static, x, y, draw);
	;;; do nothing. It cannot move
enddefine;
*/

define :mixin sim_multiwin_mobile; is sim_multiwin rc_linepic_movable;

enddefine;

define :method updaterof sim_coords(x, y, obj:sim_multiwin_mobile);
    ;;; Update location in simulation and on the screen
	;;; x -> sim_x(obj); y -> sim_y(obj);
	rc_move_to(
		obj,
			sim_transxy_to_pic(x, y, sim_picframe(rc_current_window_object)), true);

enddefine;

;;; define a print method, to simplify printing

define :method print_instance(pic:sim_multiwin_static);
	lvars win;
	printf('<static %P %P in %P>',
		[%sim_coords(pic), maplist(rc_pic_containers(pic), rc_window_title)%])
enddefine;

define :method print_instance(pic:sim_multiwin_mobile);
	lvars win;
	printf('<mobile %P %P in %P>',
		[%sim_coords(pic), maplist(rc_pic_containers(pic), rc_window_title)%])
enddefine;

/*
-- -- static and mobile multwin objects
*/

;;; Two mixins below that one, linked to sim_multiwin, static and mobile
;;; See HELP RC_LINKED_PIC, LIB RC_LINKED_PIC


;;; Descendants of sim_multiwin_static (objects and agents)
define :mixin sim_immobile; is sim_multiwin_static sim_object;
	;;; objects which can be drawn and selected, but not moved
    ;;; No internal processing mechanisms, by default
    slot sim_rulesystem == [];
	;;; other slots inherited from sim_object
enddefine;

define :mixin sim_immobile_agent; is sim_multiwin_static sim_agent;
	;;; Agents which can be drawn and selected, but not moved
	;;; other slots inherited from sim_agent
enddefine;


;;; Descendants of sim_multiwin_mobile (objects and agents)

define :mixin sim_movable; is sim_multiwin_mobile sim_object;
	;;; other slots inherited from sim_object
enddefine;

define :mixin sim_movable_agent; is sim_multiwin_mobile sim_agent;
	;;; otherwise slots inherited from sim_agent
enddefine;

/*
-- Drawing methods for multiwin objects
*/

define lconstant draw_in_containers(pic, procedure doit);
	;;; Used to draw pic in its containers,
	;;; If old is not false reset rc_old{x,y} before each drawing.
	;;; The procedure doit is designed to invoke call_next_method in
	;;; whichever method invokes this. It could be any of
	;;; rc_draw_linepic for static or movable linked pics, or
	;;; rc_draw_oldpic

    lvars
		old_win = rc_current_window_object,
		win_obj,
		(oldx,oldy) = (sim_oldx(pic),sim_oldy(pic));

	for win_obj in rc_pic_containers(pic) do
		if rc_widget(win_obj) then
			procedure();
				dlocal rc_current_window_object = win_obj;
				(oldx,oldy) -> (sim_oldx(pic),sim_oldy(pic));
            	doit(pic);
			endprocedure();
        endif;
	endfor;
	if old_win then
		old_win -> rc_current_window_object;
	endif;
enddefine;

define lconstant RC_draw_linepic(pic, procedure doit);
	;;; Draw pic in all pictures in which it is known.
	;;; This procedure is invoked by the methods for static and movable
	;;; linked pictures. doit is a procedure that invokes call_next_method
	;;; in the context of the appropriate method.

	;;; If redrawing a particular window draw only in that one
	if rc_redrawing_window then
		;;; invoked by rc_redraw_window_object
		if rc_widget(rc_current_window_object)
		and lmember(rc_current_window_object, rc_pic_containers(pic)) then
			doit(pic);
		endif;
	else
		draw_in_containers(pic, doit);
	endif;
enddefine;

define :method rc_draw_linepic(pic:sim_multiwin_static);

	define lconstant doit(pic);
		call_next_method(pic)
	enddefine;

	RC_draw_linepic(pic, doit);
enddefine;

define :method rc_draw_linepic(pic:sim_multiwin_mobile);
	define lconstant doit(pic);
		call_next_method(pic)
	enddefine;
	RC_draw_linepic(pic, doit);

	sim_coords(pic) ->(sim_oldx(pic), sim_oldy(pic));

enddefine;


define :method rc_draw_oldpic(pic:sim_multiwin_mobile);
	;;; Draw it in all pictures in which it is known. This will
	;;; obliterate in all of them

	define lconstant doit(pic);
		call_next_method(pic)
	enddefine;

	if sim_oldx(pic) then
		draw_in_containers(pic, doit);
	endif;
	;;; no longer drawn.
	false -> sim_oldx(pic);
enddefine;



define :method rc_move_to(obj:sim_multiwin_mobile, x, y, drawmode);
	;;; Move the object on the screen and update simulation coordinates
	;;; First invoke the standard picture-moving method
	;;; (See LIB RC_LINEPIC )

    dlocal
        ;;; suppress other event handlers while doing this
        rc_in_event_handler = true;

	if rc_active_window_object then
		dlocal rc_current_window_object rc_active_window_object;
	endif;

	lvars
		frame = sim_picframe(rc_current_window_object),
		(prevx,prevy) = (sim_oldx(obj),sim_oldy(obj)),
		(oldx,oldy) = sim_coords(obj),
		(newx, newy) = sim_transxy_from_pic(x, y, frame),
		wins = rc_pic_containers(obj);

		unless drawmode == "trail" then
			rc_undraw_linepic(obj);
	    endunless;

		newx, newy -> (sim_x(obj), sim_y(obj));
		if drawmode then
			rc_draw_linepic(obj);
		endif;
enddefine;

define :method sim_move_to(obj:sim_multiwin_mobile, x, y, drawmode);
	;;; This is an alternative to using the updater of
	;;; sim_coords, allowing the drawmode to control rc_move_to
	rc_move_to(obj, sim_transxy_to_pic(x, y, sim_picframe(rc_current_window_object)), drawmode);
	x -> sim_x(obj); y -> sim_y(obj);
enddefine;

/*
-- Procedures for checking which picture in a window is being acted on
*/


define lconstant selected(x, y, picx, picy, piclim, pic) /* -> boole */;
	;;; is the point x,y within piclim of the point picx,picy
	;;; x,y is where the mouse is, picx, picy and object's centre
	;;; piclim its sensitivity limit, either a number or a vector of
	;;; numbers
	if isvector(piclim) then
		lvars (xmin, ymin, xmax, ymax) = explode(piclim);
			if xmin > xmax then xmax,xmin -> (xmin, xmax) endif;
			if ymin > ymax then ymax,ymin -> (ymin, ymax) endif;
			picx + xmin <= x and picy + ymin <= y and
			picx + xmax >= x and picy + ymax >= y
	elseif isprocedure(piclim) then
			piclim(x, y, picx, picy, pic);
	else
		abs(picx - x) <= piclim and abs(picy - y) <= piclim
	endif /* -> boole */
enddefine;


define :method rc_pictures_selected(win_obj:sim_picagent_window, x, y, findone) -> num;
	;;; find pictures for which the point x,y in current rc coordinates
	;;; falls within the selection square of the centre of the picture
	;;; If findone is true, stop after finding the first one. Otherwise
	;;; return all of them. Also return the number found
	;;; This version of the method has to respect the current transformation
	;;; from sim coords to rc coords.
	lvars num = 0, pic, piclist = rc_window_contents(win_obj);

	;;;; win_obj -> rc_current_window_object;

	for pic in piclist do
		if selected(
			x, y,
				sim_transxy_to_pic(sim_coords(pic), sim_picframe(win_obj)),
						rc_mouse_limit(pic),  pic)
	then
			num fi_+ 1 -> num;
			pic;
		returnif(findone)
		endif
	endfor
enddefine;

/*
-- Adding pictures to and removing them from windows
*/

define lconstant RC_add_pic_to_containers(pic, windows);
	;;; windows is a list of window objects.
	;;; Make each of the windows a container of pic

	lvars win_obj, pic_wins = rc_pic_containers(pic);

	for win_obj in windows do
		unless lmember(win_obj, pic_wins) then
			[^^pic_wins ^win_obj] -> pic_wins;
    		rc_add_pic_to_window(pic, win_obj, true);
		endunless;
	endfor;

	pic_wins -> rc_pic_containers(pic);
	;;; This will draw it everywhere

	rc_draw_linepic(pic);
enddefine;

;;; We can use the same name as in rc_linked_pic, for a similar method
define :method rc_add_containers(pic:sim_multiwin, windows);
	;;; Add the picture pic to each of the windows, and let
	;;; pic know about the windows
	RC_add_pic_to_containers(pic, windows)
enddefine;

define :method rc_add_containers(pic:sim_multiwin_mobile, windows);
	;;; Add the picture pic to each of the windows, and let
	;;; pic know about the windows
	;;; first undraw it everywhere
	rc_undraw_linepic(pic);
	RC_add_pic_to_containers(pic, windows)
enddefine;

define lconstant RC_add_pic_to_container(pic, win_obj, moving);
	;;; XXX overkill. Simplify
	;;; moving is a boolean, true for movable objects
	lvars
		oldwins = rc_pic_containers(pic);
	
	unless lmember(win_obj, oldwins) then
		if moving then
			;;; first undraw everywhere in existing containers
			rc_undraw_linepic(pic);
		endif;
		conspair(win_obj, oldwins) -> rc_pic_containers(pic);
    	rc_add_pic_to_window(pic, win_obj, true);
		;;; Now (re)draw in all the windows, including the new one
		rc_draw_linepic(pic);
	endunless;
enddefine;

define :method rc_add_container(pic:sim_multiwin, win_obj);
	;;; Add the win_obj to the containers of pic, unless it is
	;;; already one of them

	RC_add_pic_to_container(pic, win_obj, false);
enddefine;

define :method rc_add_container(pic:sim_multiwin_mobile, item);
	RC_add_pic_to_container(pic, item, true);
enddefine;

define :method rc_remove_container(pic:sim_multiwin_mobile, win_obj);
	;;; This cannot be used with sim_multiwin_static objects
	;;; remove the win_obj from the containers of pic, unless
	;;; it is not there anyway
	lvars windows = rc_pic_containers(pic);
	if lmember(win_obj, windows) then
		;;; first undraw everywhere
		rc_undraw_linepic(pic);
		delete(win_obj, windows) -> rc_pic_containers(pic);
		rc_remove_pic_from_window(pic, win_obj);
		;;; now redraw in the remaining windows
		rc_draw_linepic(pic);
	endif;
enddefine;



global vars sim_picagent = true; 	;;; for uses

endsection;

/*

CONTENTS

 define vars procedure sim_transxy_to_pic(x, y, frame) /* -> (x,y) */;
 define vars procedure sim_transxy_from_pic(x, y, frame) /* ->(x, y) */;
 define :class sim_picagent_window; is rc_window_object;
 define :mixin sim_multiwin;
 define :method rc_coords(obj:sim_multiwin) -> (x, y);
 define :method rc_picx(obj:sim_multiwin) -> x;
 define :method rc_picy(obj:sim_multiwin) -> y;
 define :method sim_coords(obj:sim_multiwin) -> (x, y);
 define sim_set_coords(obj, x, y);
 define :method sim_distance(obj1:sim_multiwin, obj2:sim_multiwin) -> num;
 define lconstant get_oldxy(obj);
 define lconstant set_oldxy(obj, x, y);
 define :method rc_oldx(obj:sim_multiwin) -> x;
 define :method rc_oldy(obj:sim_multiwin) -> y;
 define :method updaterof rc_oldx(x, obj:sim_multiwin);
 define :method updaterof rc_oldy(y, obj:sim_multiwin);
 define :mixin sim_multiwin_static; is sim_multiwin;
 define :mixin sim_multiwin_mobile; is sim_multiwin rc_linepic_movable;
 define :method updaterof sim_coords(x, y, obj:sim_multiwin_mobile);
 define :method print_instance(pic:sim_multiwin_static);
 define :method print_instance(pic:sim_multiwin_mobile);
 define :mixin sim_immobile; is sim_multiwin_static sim_object;
 define :mixin sim_immobile_agent; is sim_multiwin_static sim_agent;
 define :mixin sim_movable; is sim_multiwin_mobile sim_object;
 define :mixin sim_movable_agent; is sim_multiwin_mobile sim_agent;
 define lconstant draw_in_containers(pic, procedure doit);
 define lconstant RC_draw_linepic(pic, procedure doit);
 define :method rc_draw_linepic(pic:sim_multiwin_static);
 define :method rc_draw_linepic(pic:sim_multiwin_mobile);
 define :method rc_draw_oldpic(pic:sim_multiwin_mobile);
 define :method rc_move_to(obj:sim_multiwin_mobile, x, y, drawmode);
 define :method sim_move_to(obj:sim_multiwin_mobile, x, y, drawmode);
 define lconstant selected(x, y, picx, picy, piclim, pic) /* -> boole */;
 define :method rc_pictures_selected(win_obj:sim_picagent_window, x, y, findone) -> num;
 define lconstant RC_add_pic_to_containers(pic, windows);
 define :method rc_add_containers(pic:sim_multiwin, windows);
 define :method rc_add_containers(pic:sim_multiwin_mobile, windows);
 define lconstant RC_add_pic_to_container(pic, win_obj, moving);
 define :method rc_add_container(pic:sim_multiwin, win_obj);
 define :method rc_add_container(pic:sim_multiwin_mobile, item);
 define :method rc_remove_container(pic:sim_multiwin_mobile, win_obj);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul  8 2000
	extended rc_move_to to handle false and "trail" draw_mode argument
--- Aaron Sloman, Mar 16 1999
	used rc_in_event_handler to protect drawing process
--- Aaron Sloman, Feb 28 1999
	Added the facilities of LIB RC_LINKED_PIC
	So that picture objects know which windows contain them
 */
