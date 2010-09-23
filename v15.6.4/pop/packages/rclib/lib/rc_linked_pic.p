/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_linked_pic.p
 > Purpose:			Allow a movable object to appear simultaneously
					in several windows.
 > Author:          Aaron Sloman, Jun 13 1997 (see revisions)
 > Documentation: 	HELP * RC_LINKED_PIC
 > Related Files:	HELP * RCLIB
 */

/*

For more test examples see
	HELP * RC_LINKED_PIC

define :class testpic;
    is rc_linked_pic;
	;;; slot rc_pic_lines = [SQUARE {0 0 20}];
	;;; use RSQUARE to make it work upside down also
	slot rc_pic_lines = [WIDTH 2 RSQUARE {-10 10 20}];
	slot rc_mouse_limit = 10;
enddefine;

define :class statpic;
    is rc_linked_static;
	;;; slot rc_pic_lines = [SQUARE {0 0 20}];
	;;; use RSQUARE to make it work upside down also
	slot rc_pic_lines = [WIDTH 4 RSQUARE {-10 10 20}];
	slot rc_mouse_limit = 10;
enddefine;

define newpic(x, y, label, windows) -> pic;

	instance testpic;
		rc_picx = x;
		rc_picy = y;
		rc_pic_strings = [{-4 0 ^label}];
	endinstance -> pic;

	rc_add_containers(pic, windows);

enddefine;

define newstatic(x, y, label, windows) -> pic;

	instance statpic;
		rc_picx = x;
		rc_picy = y;
		rc_pic_strings = [{-4 0 ^label}];
	endinstance -> pic;

	rc_add_containers(pic, windows);

enddefine;

vars
    win1 =
        rc_new_window_object(20, 5, 250, 250, true, 'win1'),
    win2 =
        rc_new_window_object(300, 5, 250, 250, {125 125 1 1}, 'win2'),
    win3 =
        rc_new_window_object(580, 5, 500, 500, {250 250 2.0 -2.0} , 'win3'),

    windows = [^win1 ^win2 ^win3],
;



vars
	p1 = newpic(0, 0, 'p1', windows),
	p2 = newpic(100, 100, 'p2', windows),
	p3 = newpic(-100, -100, 'p3', windows),
;


vars
    s1 = newstatic(0, 100, 'a', [^win1 ^win3]),
    s2 = newstatic(0, -100, 'b', [[^win2 COLOUR 'orange']]),
;
rc_remove_container(p2, win3);
rc_remove_container(p2, win2);
rc_remove_container(p2, win1);

p2.rc_pic_containers =>


isrc_linked_static(s1) =>
rc_add_container(s1, win2);

p2 =>
p2.rc_pic_containers =>
win3 =>
win3 -> rc_current_window_object;
;;; clear the window
rc_start();
;;; Redraw it
rc_redraw_window_object(win3);

rc_add_container(p2, [^win3 XSCALE 4]);
win3.rc_window_contents ==>
p2 =>

;;; add it normally to win1
rc_add_container(p2, win1);
;;; Let it be coloured red and stretched vertically in win2
;;; (remember rc_yscale is positive in win2)
rc_add_container(p2, [^win2 COLOUR 'red' YSCALE 4]);

rc_add_container(s2, [^win3 COLOUR 'blue' XSCALE 4 YSCALE -4]);

applist(windows, rc_kill_window_object);
*/


section;

uses rclib;
uses rc_linepic;
uses rc_window_object;
uses rc_mousepic;

define :mixin rc_linked_static;
	;;; for unmovable linked picture objects
    is rc_keysensitive rc_selectable rc_linepic;

	;;; initially known to no pictures
	slot rc_pic_containers == [];

    ;;; by default these are not draggable
	slot rc_drag_handlers =
		{ ^false ^false ^false};
enddefine;

define :method rc_move_to(pic:rc_linked_static, x, y, draw);
	;;; do nothing. It cannot move
enddefine;

define :mixin rc_linked_pic;
    is rc_keysensitive rc_selectable rc_linepic_movable;
	;;; initially known to no pictures
	slot rc_pic_containers == [];

enddefine;

;;; define a print method, to simplify printing

define lconstant get_title(win);
	;;; win is a win_obj or a list whose front is a win_obj
	rc_window_title(if islist(win) then front(win) else win endif)
enddefine;

define :method print_instance(pic:rc_linked_static);
	lvars win;
	printf('<lstatic %P %P in %P>',
		[%rc_coords(pic), maplist(rc_pic_containers(pic), get_title)%])
enddefine;

define :method print_instance(pic:rc_linked_pic);
	lvars win;
	printf('<lpic %P %P in %P>',
		[%rc_coords(pic), maplist(rc_pic_containers(pic), get_title)%])
enddefine;

define lconstant isinlist(item, windows) -> result;
	;;; Item is a win_obj. windows is a list (from containers of a pic)
	;;; containing both win_objs and lists starting with a win_obj and
	;;; continuing with picture drawing informatino.
	;;; Check if the item is a member of windows, or is the head of a member,
	;;; and if so return the item from windows.
	lvars win;
	for win in windows do
		if win == item
		or islist(win) and front(win) == item
		then win -> result; return()
		endif
	endfor;
	false -> result
enddefine;

define lconstant draw_in_containers(pic, procedure doit, oldx);
	;;; Used to draw pic in its containers, using extra drawing information
	;;; associated with the containers if necessary. If oldx is an integer
	;;; use it to reset the rc_oldx before each drawing.
	;;; The procedure doit is designed to invoke call_next_method in
	;;; whichever method invokes this. It could be any of
	;;; rc_draw_linepic for static of movable linked pics, or
	;;; rc_draw_oldpic
	procedure();
		dlocal %rc_pic_lines(pic) %;

		lvars
			list,
			oldpics = rc_pic_lines(pic);

    	lvars win_obj, list, vec;
		for win_obj in rc_pic_containers(pic) do
			false -> vec;

			if ispair(win_obj) then
				dest(win_obj) -> (win_obj, list);

				if ispair(list) and isvector(front(list)) then
					destpair(list) -> (vec, list);
				endif;
				if ispair(list) then
					list <> copylist(oldpics) -> rc_pic_lines(pic)
        		else
            		false -> list;
				endif;
			endif;

			if rc_widget(win_obj) then
				win_obj -> rc_current_window_object;
            	if oldx then oldx -> rc_oldx(pic) endif;
				procedure();

					dlocal
						rc_xorigin, rc_yorigin, rc_xscale, rc_yscale;
					if vec then
						if datalength(vec) == 4 then
							explode(vec) -> (rc_xorigin, rc_yorigin, rc_xscale, rc_yscale);
						else
							mishap('FOUR ELEMENT VECTOR NEEDED', [^vec]);
						endif
					endif;

					doit(pic);
				endprocedure();
        	endif;
			if list then
				;;; THIS MAY BE UNSAFE??
				;;; sys_grbg_list(rc_pic_lines(pic));
				oldpics -> rc_pic_lines(pic);
			endif;
		endfor;
	endprocedure();
enddefine;

define lconstant RC_draw_linepic(pic, procedure doit, movable);
	;;; Draw pic in all pictures in which it is known.
	;;; This procedure is invoked by the methods for static and movable
	;;; linked pictures. doit is a procedure that invokes call_next_method
	;;; in the context of the appropriate method.

	dlocal rc_current_window_object;

	;;; We need an extra level of procedure call for dlocal, alas
	;;; If redrawing a particular window draw only in that one
	if rc_redrawing_window then
		if rc_widget(rc_current_window_object) then
		  procedure();
			dlocal %rc_pic_lines(pic) %;
			lvars
				list,
				oldpics = rc_pic_lines(pic);

			lvars win_obj = isinlist(rc_current_window_object, rc_pic_containers(pic));
			if islist(win_obj) then
				dest(win_obj) -> (win_obj, list);
				list <> copylist(oldpics) -> rc_pic_lines(pic)
			else false -> list
			endif;
			doit(pic);
			if list then
				;;; THIS MAY BE UNSAFE ???
				sys_grbg_list(rc_pic_lines(pic));
				oldpics -> rc_pic_lines(pic);
			endif;
		  endprocedure();
		endif;
	else
		draw_in_containers(pic, doit, false);
	endif;
	if movable then
		rc_coords(pic) ->(rc_oldx(pic), rc_oldy(pic));
	endif;
enddefine;

define :method rc_draw_linepic(pic:rc_linked_static);

	define lconstant doit(pic);
		call_next_method(pic)
	enddefine;

	RC_draw_linepic(pic, doit, false);
enddefine;

define :method rc_draw_linepic(pic:rc_linked_pic);
	define lconstant doit(pic);
		call_next_method(pic)
	enddefine;
	RC_draw_linepic(pic, doit, true);
enddefine;

define :method rc_draw_oldpic(pic:rc_linked_pic);
	;;; draw it in all pictures in which it is known

	dlocal rc_current_window_object;

	define lconstant doit(pic);
		call_next_method(pic)
	enddefine;

	draw_in_containers(pic, doit, rc_oldx(pic));
	false -> rc_oldx(pic);
enddefine;

define :method rc_undraw_linepic(pic:rc_linked_static);
	;;; Do nothing. It cannot be undrawn

enddefine;

define :method rc_undraw_linepic(pic:rc_linked_pic);
	;;; undraw it in all pictures in which it is known

	lvars oldx = rc_oldx(pic);
	if rc_oldx(pic) then
		rc_draw_oldpic(pic);
		false -> rc_oldx(pic);
	endif;
enddefine;

define rc_redraw_pic_in(pic, win_obj);
	;;; redraw the picture ONLY in the win_obj, e.g. in case the
	;;; background of the window has been repainted

	;;; Note that it is necessary to find how that picture is
	;;; represented in twin_obj
	lconstant one_win = [0];
    lvars
		containers = rc_pic_containers(pic),
		win_info, found = false ;
	;;; find if the list of containers of pic contains special
	;;; information about how to draw pic in win_obj
	for win_info in containers do
		if win_info == win_obj
		or (ispair(win_info) and front(win_info) == win_obj)
		then
			win_info ->> front(one_win) -> found;
			quitloop()
		endif
	endfor;
	unless found then win_obj -> front(one_win) endunless;

    one_win -> rc_pic_containers(pic);
	;;; mark the picture as not drawn
    rc_undrawn(pic);
    rc_draw_linepic(pic);
	;;; reset the containers
    containers -> rc_pic_containers(pic);
	0 -> front(one_win);
enddefine;

define lconstant RC_add_pic_to_containers(pic, windows);
	;;; windows is a list where each element is either a win_obj or
	;;; a list starting with a win_obj followed by a drawing instructions.
	;;; Make each of the windows a container of pic
	lvars item, win_obj;

	for item in windows do

		;;; If it's a list then it's a win_obj plus style
		;;; information
		if islist(item) then hd(item) else item endif -> win_obj;

		unless isinlist(win_obj, rc_pic_containers(pic)) then
			[^item ^^(rc_pic_containers(pic))]
				-> rc_pic_containers(pic);

    		rc_add_pic_to_window(pic, win_obj, true);
		endunless;
	endfor;
	;;; This will draw it everywhere
	rc_draw_linepic(pic);
enddefine;

define :method rc_add_containers(pic:rc_linked_static, windows);
	;;; Add the picture pic to each of the windows, and let
	;;; pic know about the windows
	RC_add_pic_to_containers(pic, windows)
enddefine;

define :method rc_add_containers(pic:rc_linked_pic, windows);
	;;; Add the picture pic to each of the windows, and let
	;;; pic know about the windows
	;;; first undraw it everywhere
	rc_undraw_linepic(pic);
	RC_add_pic_to_containers(pic, windows)
enddefine;

define lconstant RC_add_pic_to_container(pic, item, moving);
	;;; moving is a boolean, true for movable objects
	lvars win_obj;
	
	if islist(item) then hd(item) else item endif -> win_obj;

	unless isinlist(win_obj, rc_pic_containers(pic)) then
		if moving then
			;;; first undraw everywhere in existing containers
			rc_undraw_linepic(pic);
		endif;
		conspair(item, rc_pic_containers(pic)) -> rc_pic_containers(pic);
    	rc_add_pic_to_window(pic, win_obj, true);
		;;; Now (re)draw in all the windows, including the new one
		rc_draw_linepic(pic);
	endunless;
enddefine;

define :method rc_add_container(pic:rc_linked_static, item);
	;;; Item is a win_obj or a list whose first element is a win_obj
	;;; Add the win_obj to the containers of pic, unless it is
	;;; already one of them

	RC_add_pic_to_container(pic, item, false);
enddefine;

define :method rc_add_container(pic:rc_linked_pic, item);
	;;; Item is a win_obj or a list whose first element is a win_obj
	;;; Add the win_obj to the containers of pic, unless it is
	;;; already one of them

	RC_add_pic_to_container(pic, item, true);
enddefine;

define :method rc_remove_container(pic:rc_linked_pic, win_obj);
	;;; This cannot be used with rc_linked_static objects
	;;; remove the win_obj from the containers of pic, unless
	;;; it is not there anyway
	lvars win, windows = rc_pic_containers(pic);
	if isinlist(win_obj, windows) ->> win then
		;;; first undraw everywhere
		rc_undraw_linepic(pic);
		delete(win, windows) -> rc_pic_containers(pic);
		rc_remove_pic_from_window(pic, win_obj);
		;;; now redraw in the remaining windows
		rc_draw_linepic(pic);
	endif;
enddefine;


global vars rc_linked_pic = true;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 25 1997
	Allowed the container of a pic to be associated with a new coordinate
	frame.
--- Aaron Sloman, Jun 24 1997
	Added rc_redraw_pic_in
--- Aaron Sloman, Jun 18 1997
	Changed to allow objects to appear differently in different
	windows, e.g. using XSCALE, etc
--- Aaron Sloman, Jun 16 1997
	Added rc_linked_static, for non movable linked pictures
		and extended the help file

--- Aaron Sloman, Jun 14 1997
	Changed so that for these items drawing occurs only in their
	containers

CONTENTS

 define :class testpic;
 define :class statpic;
 define newpic(x, y, label, windows) -> pic;
 define newstatic(x, y, label, windows) -> pic;
 define :mixin rc_linked_static;
 define :method rc_move_to(pic:rc_linked_static, x, y, draw);
 define :mixin rc_linked_pic;
 define lconstant get_title(win);
 define :method print_instance(pic:rc_linked_static);
 define :method print_instance(pic:rc_linked_pic);
 define lconstant isinlist(item, windows) -> result;
 define lconstant draw_in_containers(pic, procedure doit, oldx);
 define lconstant RC_draw_linepic(pic, procedure doit, movable);
 define :method rc_draw_linepic(pic:rc_linked_static);
 define :method rc_draw_linepic(pic:rc_linked_pic);
 define :method rc_draw_oldpic(pic:rc_linked_pic);
 define :method rc_undraw_linepic(pic:rc_linked_static);
 define :method rc_undraw_linepic(pic:rc_linked_pic);
 define rc_redraw_pic_in(pic, win_obj);
 define lconstant RC_add_pic_to_containers(pic, windows);
 define :method rc_add_containers(pic:rc_linked_static, windows);
 define :method rc_add_containers(pic:rc_linked_pic, windows);
 define lconstant RC_add_pic_to_container(pic, item, moving);
 define :method rc_add_container(pic:rc_linked_static, item);
 define :method rc_add_container(pic:rc_linked_pic, item);
 define :method rc_remove_container(pic:rc_linked_pic, win_obj);

 */
