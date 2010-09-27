/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_mousepic.p
 > Purpose:			Add mouse-based interaction to a window
 > Author:          Aaron Sloman, Apr  2 1996 (see revisions)
 > Documentation:	HELP RC_EVENTS (describes event handling)
					HELP * RCLIB, HELP * RC_MOUSEPIC REF * XT_CALLBACK
 > Related Files:	TEACH * RC_GRAPHIC, HELP * RC_GRAPHIC, LIB * RC_MOUSE
 > 					LIB * RC_BUTTONS
 */



/*
For the main details see HELP RC_EVENTS

More information is in HELP RC_LINEPIC, HELP RCLIB
See TEACH * RC_LINEPIC/rc_mousepic
See TEACH * RCLIB_DEMO.P/rc_mousepic
for tests.


Values for drag events data:
	left 	256
	middle 	512
	right  1024

*/


compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses-now Xpw;

section;
uses objectclass;

uses rclib;
uses ARGS;

exload_batch;
;;; Some stuff copied from LIB * RC_MOUSE

#_IF DEF POPC_COMPILING
#_INCLUDE 'Xpw/popc_declare.ph'
#_ENDIF

include xpt_xgcvalues.ph;

uses rc_graphic, xt_callback;
uses rc_window_object;
uses rc_linepic;

;;; this is needed in the next library
global vars procedure rc_process_event;

uses rc_handle_vedwarpcontext;

/*
define -- Global variables and mixin and class definitions
*/

;;; Specify default buffer for output generated while running event
;;; handlers
global vars
	rc_charout_buffer = './output.p',
	;;; for printing to Ved buffer
	rc_ved_char_consumer = false;

;;; variables set in the event handler
global vars
	rc_active_widget = false, 			;;; the local value of rc_window
	rc_active_window_object= false,		;;; instance of rc_window_object
	rc_active_picture_object = false,	;;; instance of rc_selectable etc.
	rc_prev_active_window_object= false,	;;; previous instance of rc_window_object
	rc_prev_active_picture_object = false,	;;; previous instance of rc_selectable etc.
	rc_selected_window_objects = [],
	rc_selected_picture_objects = [],
	rc_moving_picture_object = false,
	rc_button_1_is_down = false,
	rc_button_2_is_down = false,
	rc_button_3_is_down = false,
	rc_inside_callback = false,
	;

;;; Used to control resize events
global vars
	in_rc_resize_object = false;

	;;; note rc_current_picture_object is set during drawing, in rc_linepic
	;;; also rc_current_window_object is defined in lib rc_window_object


global vars
	;;; Drag events need not be handled if there is already a later
	;;; drag event in the queue. Make rc_fast_drag false to ensure
	;;; that all drag events are handled.
	rc_fast_drag = true,
	;;; similarly move events
	rc_fast_move = true,

	;;; should picture objects that cannot handle an event allow the event
	;;; to drop through to a shadowed object? If so make this true.
	;;; The default is false
	rc_transparent_objects = false,
;

#_IF identprops("rc_linepic_bounds") /== undef

;;; This may be useful for people using rc_mousepic with rc_linepic
define rc_create_mouse_limit(pic);
	;;; Used to create a mouse_limit that depends on the drawing.
	;;; Find the largest distance from the centre of the picture to
	;;; a vertex in its linepic, and call that the rc_mouse_limit
	;;; in a vector and store in the rc_bounds slot;
	;;; NOT ALWAYS SENSIBLE
	lvars
		(xmin, ymin, xmax, ymax) = rc_linepic_bounds(pic, false),
		lim = rc_mouse_limit(pic);

		if isvector(lim) then
			;;; store all the bounds
			fill(xmin, ymin, xmax, ymax, lim) ->;
		elseif isprocedure(lim) then
			printf('rc_mouse_limit procedure being replaced, in ' sys_>< pic)
		else
			;;; Choose the largest absolute value? (Average???)
			max(max(max(abs(xmin), abs(xmax)), abs(ymin)), abs(ymax))
				-> rc_mouse_limit(pic);
		endif
enddefine;

#_ENDIF


define :method vars rc_coords(pic: rc_selectable) /* -> (x, y) */;
	;;; given a picture object return its current coords;
	;;; default version in LIB * rc_linepic /rc_coords
	rc_picx(pic), rc_picy(pic) /* ->(x,y) */
enddefine;

define :method updaterof rc_coords(/*x, y,*/ pic:rc_selectable);
	-> (rc_picx(pic), rc_picy(pic))
enddefine;
	

/*
define -- Utilities and methods concerned with mouse actions
*/

define rc_object_selected(x, y, picx, picy, piclim, pic) /* -> boole */;
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


;;; Next method no longer used by default, as it is replaced by
;;; rc_picture_selected_type.
;;; rc_pictures_selected remains available in case users want it or
;;; want to use find_selected_object, defined below.

define :method rc_pictures_selected(win_obj:rc_window_object, x, y, findone) -> num;
	;;; find pictures for which the point x,y in current rc coordinates
	;;; falls within the selection square of the centre of the picture
	;;; If findone is true, stop after finding the first one. Otherwise
	;;; return all of them. Also return the number found
	lvars num = 0, pic, piclist = rc_window_contents(win_obj);

	;;;; [ALL %x,y,piclist%]=>
	for pic in piclist do
		;;; [%x,y, pic%]=>
		if rc_object_selected(x, y, rc_coords(pic),
			recursive_valof(rc_mouse_limit(pic)),  pic) then
			;;; [selected ^pic]=>
			num fi_+ 1 -> num;
			pic;
		returnif(findone)
		endif
	endfor
enddefine;


define :method rc_picture_selected_type(win_obj:rc_window_object, x, y, type) -> num;
	;;; like rc_pictures_selected, but returns 0 or 1 picture of the
	;;; appropriate type for the handler
	lvars num = 0, pic, piclist = rc_window_contents(win_obj);

	;;; [ALLPICS %x,y,piclist%]=>
	for pic in piclist do
		;;; [%x,y, pic%]=>
		if rc_object_selected(x, y, rc_coords(pic),
				recursive_valof(rc_mouse_limit(pic)),  pic) then
			;;; [selected ^pic]=>
			if type(pic) then
				pic; 1 -> num; return();
			endif;
		endif
	endfor
enddefine;


/*
define -- The core utilities for handling callbacks
*/

;;; These event-lists are used by the event handlers defined below.
;;; Not accessible to users
vars
	Events_list = [],
	Deferred_events_list = [],
	;;; pictures that are being drawn cannot be processed till drawing
	;;; is finished. Put the job on here
	Drawing_defer_list = [];

define rc_defer_apply(proc);
	;;; User procedure for postponing an event
	;;; Put procedure on a list to be handled after all window events have
	;;; settled.

	rc_handle_vedwarpcontext(%false, proc%) -> proc;

	Deferred_events_list nc_<> [^proc] -> Deferred_events_list;
enddefine;

;;; Function for transforming between screen co-ordinates and user
;;; co-ordinates. (Compare rc_transxyout in LIB * RC_GRAPHIC

;;;; ???? needs to be changed for rotatable objects? ????

define :method rc_mousexyin(win_obj:rc_window_object, x, y) /* -> (x, y) */;
	;;; win_obj must be the current window object

	;;; Procedure that takes window pixel coordinates and uses current frame
	;;; to get the coordinates
	;;; Must leave numbers on stack in same order
	;;; Warning - this can produce ratios as results
	;;; Warning. Must be replaced by rc_rotate_xyin if lib rc_rotate_xy used.

	;;; deal with most common case first
	if rc_xscale == 1 or rc_xscale = 1.0 then
		x - rc_xorigin
	else (x - rc_xorigin) / rc_xscale
	endif; /* -> x */

	if rc_yscale == -1 then
		rc_yorigin - y
	elseif rc_yscale == 1 then
		y - rc_yorigin
	elseif rc_yscale = -1.0 then
		rc_yorigin - y
	elseif rc_yscale = 1.0 then
		y - rc_yorigin
	else
		(y - rc_yorigin) / rc_yscale
	endif; /* -> y */
enddefine;


global vars procedure rc_transxyin;

if isundef(rc_transxyin) then
	procedure (x, y) with_props rc_transxyin;
	 	rc_mousexyin(rc_window_object_of(rc_window), x, y)
	endprocedure -> rc_transxyin
endif;

;;; Next procedure no longer used by default, but left for users
;;; The main event handler now uses find_selected_object_type

define find_selected_object(window_obj, x, y) -> obj;
	;;; Does location x, y fall in an object? If so get the first.
	lvars num;
	rc_pictures_selected(window_obj, x, y, true) -> num;

	if num == 1 then
		;;; a picture object was selected
		-> obj
	else
		;;; use the window pane instead
		window_obj -> obj
	endif;
enddefine;

define find_selected_object_type(window_obj, x, y, type) -> obj;
	;;; Does location x, y fall in an object? If so get the first.
	lvars num;
	rc_picture_selected_type(window_obj, x, y, type) -> num;

	if num == 1 then
		;;; a picture object was selected
		-> obj
	else
		;;; use the window pane instead
		window_obj -> obj
	endif;
enddefine;


define vars procedure rc_get_handler(obj, type, button) -> handler;
	;;; Invoked by various sytem callback handlers.
	;;; It gets the handler of the appropriate type from the
	;;; object, usually inherited from the class. If it is a
	;;; mouse button or drag event there will be a vector of
	;;; handlers, one for each button, as defined in the rc_selectable
	;;; mixin, where the vector can contain methods or method-names.
	;;; Otherwise the handler will be one handler, represented by a
	;;; method or its name.
	;;; If the handler is false then no action occurs.

	type(obj) -> handler;	;;; handler or a vector of handlers
	if button then
		;;; it's a vector of handlers
		subscrv(button, handler) -> handler
	endif;
	if isword(handler) then
		valof(handler) -> handler
	endif;
	unless not(handler) or islist(handler) or isprocedure(handler) then
		mishap('No handler found ' sys_>< pdprops(type),
			[^obj ^handler 'button number' ^button])
	endunless;
enddefine;

global vars rc_no_more_handlers = false;

define vars apply_or_unpack(proc, obj, x, y, modifiers, /*key*/);
	;;; For running drag or move or mouse button event handlers, which
	;;; could be a list of handlers, a procedure or a word naming a procedure
	;;; For keypress events see rc_system_keypress_callback below

	lvars key = false;	;;;; optional integer specifying key pressed

	ARGS proc, obj, x, y, modifiers, &OPTIONAL key:isinteger;

	;;; Set this false, so that "aborting" event handlers can make it true.
	dlocal rc_no_more_handlers = false;

	if ispair(proc) then
		;;; it must be a list
		lvars handler;
		for handler in proc do
			returnif(rc_no_more_handlers);
			recursive_valof(handler)(obj, x, y, modifiers, if key then key endif)
		endfor;
	else
		;;; [% proc, obj, x, y, modifiers, %]=>
		proc(obj, x, y, modifiers, if key then key endif)	
	endif;
enddefine;

define vars procedure rc_system_button_down_callback(obj, x, y, modifiers, item, button);
	;;; Get the callback handler, and apply it to the object and coords
	;;; If it is a list, treat it as a list of handlers or their names.

	if button == 1 then
		true -> rc_button_1_is_down
	elseif button == 2 then
		true -> rc_button_2_is_down
	elseif button == 3 then
		true -> rc_button_3_is_down
	endif;

	lvars proc = rc_get_handler( obj, rc_button_down_handlers, button);

	;;; [down ^obj ^x ^y]=>
	if proc then
		apply_or_unpack(proc, obj, x, y, modifiers)	
	endif;
	
enddefine;


define rc_release_mouse_control();
	;;; for releasing control of a selected object
	if rc_active_window_object then
	 	false -> rc_mouse_selected(rc_active_window_object)
	endif;
enddefine;

define vars procedure rc_system_button_up_callback(obj, x, y, modifiers, item, button);
	;;; get the callback handler, and apply it to the object and coords
	lvars proc = rc_get_handler( obj, rc_button_up_handlers, button);
	;;; [up ^obj ^x ^y]=>
	
	if button == 1 then
		false -> rc_button_1_is_down;
	elseif button == 2 then
		false -> rc_button_2_is_down
	elseif button == 3 then
		false -> rc_button_3_is_down
	endif;
	if proc then
		apply_or_unpack(proc, obj, x, y, modifiers)	
	endif;
enddefine;

define vars procedure rc_system_move_callback(obj, x, y, modifiers, item, button);
	;;; Button should always be 0 for move events
	
	lvars event;
	if rc_fast_move and Events_list /== [] then
		;;; see if the next event is a move event and if so abort
		;;; this one. (Should it just prune the move event and continue??)
		if islist(fast_front(Events_list) ->> event) then
			;;; event format (widget, item, data, proc, x, y, modifiers);
			returnif(fast_subscrl(4, event) == rc_system_move_callback)
		endif
	endif;

	;;; get the callback handler, and apply it to the object and coords
	lvars proc = rc_get_handler( obj, rc_move_handler,  false /*i.e. no button*/);
	if proc then
		apply_or_unpack(proc, obj, x, y, modifiers)	
	endif;
	;;; [move ^obj ^x ^y]=>
enddefine;


define vars procedure rc_system_drag_callback(obj, x, y, modifiers, item, button);
	lvars event;
	if rc_fast_drag and Events_list /== [] then
		;;; see if the next event is a drag event and if so abort
		;;; this one.
		if islist(fast_front(Events_list) ->> event) then
			;;; event format (widget, item, data, proc, x, y, modifiers);
			returnif(fast_subscrl(4, event) == rc_system_drag_callback)
			
		endif
	endif;
	;;; get the callback handler, and apply it to the object and coords
	lvars proc = rc_get_handler( obj, rc_drag_handlers, button);
	if proc then
		apply_or_unpack(proc, obj, x, y, modifiers)	
	endif;
	;;; [drag ^obj ^x ^y]=>
enddefine;

define vars procedure rc_system_keypress_callback(obj, x, y, modifiers, data, key);
	;;; key should be the ascii character code, or other code
	;;; down is positive, up negative
	;;; if isrc_keysensitive(obj) then
	;;; get the callback handler, and apply it to the object and coords
	;;; 'continuing keyboard' =>
	lvars proc = rc_get_handler(obj, rc_keypress_handler, false);
	if proc then

		apply_or_unpack(proc, obj, x, y, modifiers, key);

	endif;
enddefine;

define vars procedure rc_system_entry_callback(obj, x, y, modifiers, data, mode);
	;;; Set up by rc_do_mouse_actions, below
	;;; data should be the word "mouse", mode should be 7
	lvars proc = rc_get_handler(obj, rc_entry_handler, false /*i.e. no button*/);
	if proc then
		apply_or_unpack(proc, obj, x, y, modifiers)	
	endif;
	;;; [Entering ^obj at ^x ^y] =>
enddefine;

define vars procedure rc_system_exit_callback(obj, x, y, modifiers, data, mode);
	;;; Set up by rc_do_mouse_actions, below
	;;; data should be the word "mouse", mode should be 8
	lvars proc = rc_get_handler(obj, rc_exit_handler, false /*i.e. no button*/);
	if proc then
		apply_or_unpack(proc, obj, x, y, modifiers)	
	endif;
	;;; [Leaving ^obj at ^x ^y] =>
enddefine;

define :method rc_set_front(pic:rc_selectable);
	;;; make pic front of known picture list, if not already there
	lvars
		win_obj = rc_active_window_object,
		list = rc_window_contents(win_obj);

	setfrontlist(pic, list) -> rc_window_contents(win_obj);
enddefine;

/*
define -- User definable event handlers
*/

define :method rc_button_1_down(pic:rc_selectable, x, y, modifiers);
	;;; Click on an object to make it the selected one, unless the
	;;; shift key is already down and an object has been selected

	if modifiers = 's' and rc_mouse_selected(rc_active_window_object) then
		rc_set_front(rc_mouse_selected(rc_active_window_object));
		rc_move_to(rc_mouse_selected(rc_active_window_object), x, y, true)
	else
		pic -> rc_mouse_selected(rc_active_window_object);

		;;; Make sure it is now on "top" of all the others.
		rc_set_front(pic);
	endif;
enddefine;

define :method rc_button_1_down(pic:rc_window_object, x, y, modifiers);
	;;; Clicking in empty space de-selects, unless the shift key is down
	;;; in which case the selected object moves to the mouse location
	if modifiers = 's' and rc_mouse_selected(rc_active_window_object) then
		rc_set_front(rc_mouse_selected(rc_active_window_object));
		rc_move_to(rc_mouse_selected(rc_active_window_object), x, y, true)
	elseif modifiers = 'c' then
		;;;CTRL and mouse button 1, so make this the current window object

		;;; defer the following
		;;; rc_active_window_object -> rc_current_window_object;
		rc_defer_apply(procedure(win);
				set_global_valof(win, "rc_current_window_object");
			endprocedure(%rc_active_window_object%));
	else
		;;; false -> rc_mouse_selected(rc_active_window_object);
		rc_release_mouse_control();
	endif;
enddefine;

;;; uncomment the print commands for testing

define :method rc_button_2_down(pic:rc_selectable, x, y, modifiers);
	;;; [button 2 down ^x ^y ^modifiers] =>
enddefine;


define :method rc_make_selected(pic:rc_selectable, x, y, modifiers);
	conspair(pic, rc_selected_picture_objects) -> rc_selected_picture_objects
enddefine;

define :method rc_make_unselected(pic:rc_selectable, x, y, modifiers);
	ncdelete(pic, rc_selected_picture_objects, nonop ==, 1) -> rc_selected_picture_objects;
enddefine;

define :method rc_make_selected(pic:rc_window_object, x, y, modifiers);
	conspair(pic, rc_selected_window_objects) -> rc_selected_window_objects
enddefine;

define :method rc_make_unselected(pic:rc_window_object, x, y, modifiers);
	ncdelete(pic, rc_selected_window_objects, nonop ==, 1) -> rc_selected_window_objects;
enddefine;

define rc_kill_selected_window_objects();
	applist(rc_selected_window_objects,rc_kill_window_object);
	[] -> rc_selected_window_objects
enddefine;


define :method rc_button_3_down(pic:rc_selectable, x, y, modifiers);
    if strmember (`s`, modifiers) then
		if fast_lmember(pic, rc_selected_picture_objects) then
			rc_make_unselected(pic, x, y, modifiers);
		else
			rc_make_selected(pic, x, y, modifiers);
		endif;
    endif;
	;;;[button 3 down ^x ^y ^pic] =>
enddefine;

define :method rc_button_3_down(pic:rc_window_object, x, y, modifiers);
    if strmember (`s`, modifiers) then
		if fast_lmember(pic, rc_selected_window_objects) then
			rc_make_unselected(pic, x, y, modifiers);
		else
			rc_make_selected(pic, x, y, modifiers);
		endif;
    endif;
	;;;[button 3 down ^x ^y ^pic] =>
enddefine;


define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
	;;; [button 1 up ^x ^y ^pic] =>
enddefine;

define :method rc_button_2_up(pic:rc_selectable, x, y, modifiers);
	;;; [button 2 up ^x ^y ^pic] =>
enddefine;

define :method rc_button_3_up(pic:rc_selectable, x, y, modifiers);
	;;; [button 3 up ^x ^y ^pic] =>
enddefine;

define :method rc_button_1_drag(pic:rc_window_object, x, y, modifiers);
	;;; No object currently under mouse, i.e. event in window
	if modifiers = 's' or modifiers = nullstring then
		;;; Shift key pressed
		lvars current_selected = rc_mouse_selected(rc_active_window_object);

		if current_selected then
			;;; drag the previously selected object to here
			rc_set_front(current_selected);
			rc_move_to(current_selected, x, y, true)
		else
            ;;; uncomment this for tracing and debugging
			;;; [button 1 drag (empty) ^x ^y modifiers ^modifiers]=>
		endif
	else
        ;;; uncomment this for tracing and debugging
		;;; [button 1 drag (empty) ^x ^y modifiers ^modifiers ]=>
	endif;
enddefine;


define :method rc_button_1_drag(pic:rc_selectable, x, y, modifiers);

	lvars current_selected = rc_mouse_selected(rc_active_window_object);
	if modifiers = nullstring then
    	;;; Make sure it is at the front of the list, otherwise there may
    	;;; be unexpected results if it is dragged over another object.
		if current_selected then
    		;;; An object was already selected keep dragging that one
    		rc_set_front(current_selected);
	    	rc_move_to(current_selected, x, y, true)
		else
			;;; choose this object as the selected one
    		rc_set_front(pic);
			pic -> rc_mouse_selected(rc_active_window_object);
			rc_move_to(pic, x, y, true)
		endif;
	elseif modifiers = 's' then
		;;; Shift key pressed
		if current_selected then
    		;;; An object was already selected keep dragging that one
    		;;; if there is a selected object, you can drag it
			;;; even in an empty space
		else
        	;;; otherwise select this object and start dragging it.
        	pic ->> current_selected -> rc_mouse_selected(rc_active_window_object);
        endif;
		rc_set_front(current_selected);
		rc_move_to(current_selected, x, y, true)
	elseif modifiers = 'c' then
	    ;;; Drag an object without selecting it
	    rc_set_front(pic);
	    rc_move_to(pic, x, y, true)
	else
		;;; [button 1 drag ^pic ^x ^y  modifiers ^modifiers] =>
	endif;
enddefine;

define :method rc_button_2_drag(pic:rc_selectable, x, y, modifiers);
		;;; [button 2 drag ^x ^y ^pic ^modifiers] =>
enddefine;

define :method rc_button_2_drag(pic:rc_window_object, x, y, modifiers);
	;;; [button 2 drag nothing ^x ^y modifiers ^modifiers] =>
enddefine;

define :method rc_button_3_drag(pic:rc_selectable, x, y, modifiers);
	 ;;; [button 3 drag pic ^pic ^x ^y ^modifiers] =>
enddefine;

define :method rc_button_3_drag(pic:rc_window_object, x, y, modifiers);
	 ;;; [button 3 drag nothing ^x ^y modifiers ^modifiers] =>
enddefine;


define :method rc_move_mouse(pic:rc_selectable, x, y, modifiers);
	 ;;; [move mouse ^x ^y  modifiers ^modifiers] =>
enddefine;

define :method rc_mouse_enter(pic:rc_selectable, x, y, modifiers);
	;;; Warning. (a) locations may be inaccurate (b) modifiers may
	;;; be inaccurate;
	;;; [ENTERING ^pic ^x ^y  modifiers ^modifiers] =>
enddefine;

define :method rc_mouse_exit(pic:rc_selectable, x, y, modifiers);
	;;; Warning: locations may be inaccurate
	;;; [LEAVING ^pic ^x ^y  modifiers ^modifiers] =>
enddefine;

define :method rc_handle_keypress(pic:rc_selectable, x, y, modifiers, key);
;;;	[keypress ^x ^y ^modifiers key ^key ] =>
enddefine;

define :method rc_under_mouse_control(pic:rc_selectable) -> bool;
	rc_button_1_is_down and
		rc_active_window_object and
		rc_mouse_selected(rc_active_window_object) == pic -> bool;
enddefine;


/*
define -- The actual event handlers
*/

define constant rc_modifier_codes =
	newproperty(
		[
		[1 's'][257 's'][513 's'][1025 's']
		[4 'c'][260 'c'][516 'c'][1028 'c']
		[5 'cs'][261 'cs'][517 'cs'][1029 'cs']
		[8 'm'][264 'm'][520 'm'][1032 'm']
		[9 'ms'][265 'ms'][521 'ms'][1033 'ms']
		[12 'cm'][268 'cm'][524 'cm'][1036 'cm']
		[13 'cms'][269 'cms'][525 'cms'][1037 'cms']
		]	
		,32,nullstring,"perm");
enddefine;

define rc_reset_context();
	-> (rc_xorigin, rc_yorigin, rc_xscale, rc_yscale,
				rc_xposition, rc_yposition, rc_heading,
	    		rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax);
enddefine;

rc_reset_context -> updater(rc_reset_context);

;;; Thanks to John Gibson for help with the following mechanisms

global vars rc_in_event_handler = false;	;;; Used in rc_window_object

define vars procedure process_defer_list();
	;;; Process events outside context of current active window object
	;;; redefinable by users.
	;;; 'starting process_defer_list'=>
	lvars
		oldcucharout = cucharout,
		oldcucharerr = cucharerr,
		oldprmishap = prmishap;

	unless rc_ved_char_consumer or not(rc_charout_buffer) then
		veddiscout(rc_charout_buffer) -> rc_ved_char_consumer
	endunless;

	define lconstant prmishapinved();
		;;; If errors occur, restore output
		dlocal cucharout = oldcucharout, cucharerr = oldcucharerr;
		oldprmishap();
	enddefine;
	
	dlocal cucharout, cucharerr, prmishap;

	;;; If necessary set up output to go into Ved buffer.
	if rc_charout_buffer
	and (vedinvedprocess or vedediting) then
		rc_ved_char_consumer ->> cucharout -> cucharerr;
		prmishapinved -> prmishap;
	endif;

	;;; [1. Deferred_events_list ^Deferred_events_list]=>
	lvars event;
	until Deferred_events_list == [] do
		;;; [2. Deferred_events_list ^Deferred_events_list]=>
		;;;'Processing deferred events' =>
		sys_grbg_destpair(Deferred_events_list) -> (event, Deferred_events_list);
		
		;;; removed this Feb 2000
		;;; rc_reset_context(explode(rc_window_frame(rc_active_window_object)));

		lvars len = stacklength();

		;;; previously event()

		rc_handle_vedwarpcontext(false, event);

	    lvars
			newlen = stacklength(),
			errstring =
				if newlen > len then 'OBJECTS LEFT ON STACK BY EVENT HANDLER'
				elseif newlen < len then 'OBJECTS REMOVED FROM STACK BY EVENT HANDLER'
				else false
				endif;
		if errstring then mishap(errstring, [^event]) endif;
	enduntil;
enddefine;

define rc_do_deferred_list();
	;;; Process events outside context of current active window object
	external_defer_apply(process_defer_list);
	true -> pop_asts_enabled;
	sys_raise_ast(false);
	XptSetXtWakeup();
	;;;'processed defer-list?' =>
enddefine;


define rc_clear_events();
	rc_sync_display();
	;;; clear all unprocessed events
	sys_grbg_list(Events_list);
	[] -> Events_list;
	sys_grbg_list(Deferred_events_list);
	[] -> Deferred_events_list;
enddefine;

global vars
	;;; This is made true in rc_process_event. Disables event handling while
	;;; processing events
	in_rc_process_event = false;

define vars procedure rc_process_event(event);

	;;; [rc_process event ^event]=>
	dlocal in_rc_process_event;
	;;; return if already handling an event
	lvars cllr;
	if in_rc_process_event
		and (iscaller(rc_process_event, 1) ->> cllr)
		and cllr < 3
	then
		;;; 'Recursing returning'=>
		Events_list nc_<> [^event] -> Events_list;
		return();

	else
		;;; make sure no new events will be handled
		true -> in_rc_process_event;

	endif;


	lvars widget, item, data, procedure proc, x, y, modifiers,
		oldcurrent_win_obj = rc_current_window_object,
		newcurrent_win_obj;
	
	define lconstant restore_current();
		;;; decide whether to restore the saved rc_current_window_object
		;;; don't do so if a new current object has been created
		;;; or the old one has been killed
		if (not(rc_current_window_object ) or rc_current_window_object == newcurrent_win_obj)
		and rc_islive_window_object (oldcurrent_win_obj)
		and oldcurrent_win_obj /== rc_current_window_object
		then
			;;; [Restoring ^oldcurrent_win_obj] =>
			oldcurrent_win_obj -> rc_current_window_object
		endif;
		;;; [Restored ^rc_current_window_object] =>
	enddefine;

	
	dl(event) -> (widget, item, data, proc, x, y, modifiers);
	;;; Note, x and y are in widget coordinates, not RC coordinates
	;;; So they need to be transformed to select relevant picture
	;;; object, and the transformed coordinates are given to the
	;;; handlers of the object to deal with the event.

	;;; widget may have been killed
	returnunless(xt_islivewindow(widget));

	lvars win_obj = rc_window_object_of(widget);

	;;; [Widget ^widget Win ^win_obj] =>

	;;; object may have been killed recently
	returnunless(win_obj);

	;;; Remember which window object it was, and
	;;; make it current. This will also set up proper coordinate frame
	;;; for running the procedure in the window in which the event occurred.
	win_obj -> newcurrent_win_obj;

	unless win_obj == rc_current_window_object then
		win_obj -> rc_current_window_object
	endunless;

	;;; find which modifier keys are down, represented as a string,
	;;; possibly empty
	rc_modifier_codes(modifiers) -> modifiers;

	;;; save current window frame information
	lvars
		(oldxorigin, oldyorigin, oldxscale, oldyscale,
		oldxposition, oldyposition, oldheading,
    	oldclipping, oldxmin, oldymin, oldxmax, oldymax)
		= (rc_xorigin, rc_yorigin, rc_xscale, rc_yscale,
		rc_xposition, rc_yposition, rc_heading,
    	rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax);

	;;; on exit, restore the original window settings
	;;; e.g. which might have been used by a drawing procedure
	;;;	before the event happened in another window.
	;;; exit action, not performed if control temporarily transferred
	;;; to ved process (dlocal_context >= 3)
	dlocal
		0% , if dlocal_context < 3 then
				(rc_reset_context(
					oldxorigin, oldyorigin, oldxscale, oldyscale,
					oldxposition, oldyposition, oldheading,
	    			oldclipping, oldxmin, oldymin, oldxmax, oldymax);
					restore_current());
			 endif%;

	;;; Set the context for the current window
	rc_reset_context(explode(rc_window_frame(win_obj)));
	;;; ['RC context reset' %rc_xorigin, rc_yorigin, rc_xscale, rc_yscale%]=>

	;;; get transformed RC coordinates for the event
	rc_mousexyin(win_obj, x, y) -> (x, y);

	;;; If necessary find the picture object in the window, otherwise
	;;; let the window itself be the selected object
	lvars obj =
		if proc == rc_system_entry_callback
			or proc == rc_system_exit_callback
		then
			;;; We don't get X entry or exit events for picture objects.
			win_obj
		else
			;;; for other event types, find whether the event is in the
			;;; sensitive region of a picture object of the right type
		
			find_selected_object_type(
				win_obj, x, y,
					if not(rc_transparent_objects) then
						;;; recognize any type of object.
						;;; identfn never returns false.
						;;; See HELP RC_EVENTS
						identfn
					elseif proc == rc_system_keypress_callback then
						isrc_keysensitive
					else isrc_selectable
					endif)
		endif;

	;;; obj could now be the window, or a picture object in the window
	;;; 'selected' ^obj] =>


	returnunless(xt_islivewindow(widget));
	;;; [IN rc_process_event [widget ^widget] [rc_window ^rc_window]] ==>
	;;; Set globals for use by event handlers, etc.
	widget ->> rc_active_widget -> rc_window;

	unless win_obj == rc_active_window_object then
		if proc == rc_system_button_down_callback then
			;;; not sure this is useful?
			rc_active_window_object -> rc_prev_active_window_object;
			win_obj -> rc_active_window_object;
		endif;
	endunless;

	if obj == win_obj then
		;;; It's the window, not a picture object that must handle
		;;; the event.
	elseif is_current_picture_object(obj) then
		;;; 'Drawing defer' =>
		;;; this object is currently being (re-)drawn, and so it
		;;; cannot be processed. Put it back on the drawing event list.
		rc_handle_vedwarpcontext(%false, event%) -> event;
		Drawing_defer_list nc_<> [%event%] -> Drawing_defer_list ;
		return();
	else
		unless obj == rc_active_picture_object then
			if proc == rc_system_button_down_callback then
				rc_active_picture_object -> rc_prev_active_picture_object;
				obj -> rc_active_picture_object;
			endif;
		endunless;
		;;; Don't yet set up coordinate frame for selected object
		;;; as this could cause problems, e.g. if object is to be moved
		;;; relative to external frame. Let the object's methods do it.
	endif;

	;;; Event record no longer needed
	;;; 'Clearing event' =>
	sys_grbg_list(event);

	;;; Call proc (the real handler) on transformed data, and check for
	;;; stack errors.
	lvars len = stacklength();

	;;; proc(obj, x, y, modifiers, item, data);
	lvars callr = iscaller(rc_handle_vedwarpcontext, 1);
	unless callr and callr < 3 then
		returnunless(xt_islivewindow(widget));
		;;; run with Xved warping turned off.
		rc_handle_vedwarpcontext(obj, x, y, modifiers, item, data, win_obj, proc);
	endunless;

	unless stacklength() == len then
		mishap('HANDLER PROCEDURE ALTERED STACK',
			[%widget, proc, obj, x, y, modifiers, item, data%])
	endunless;


	;;; restore_current() will run on exit
enddefine;

define rc_process_in_queue(event);
	;;;dlocal rc_in_event_handler = false;
	rc_process_event(event);
enddefine;

define vars procedure rc_process_event_queue();
	;;; widget is window, item is "button" or "move", data will be
	;;; the button number, < 0 if released. proc is the handler
	;;; procedure to be invoked, usually a method.

	;;; action to postpone events during processing of these
	;;; events
	dlocal
		rc_in_event_handler, vedwarpcontext = false;

	if rc_in_event_handler then
		;;; 'in event handler' =>
		;;; Already handling an event. Stop.
		;;; Th events on the queue will be processed later
		;;; as the handler already active works through the Events list.
		;;; Just in case try again a twentieth of a second later
		5e4 -> sys_timer(rc_process_event_queue);
		return();
	else
		true -> rc_in_event_handler
	endif;

	 ;;;'entering event handler' =>

	lvars
		oldcucharout = cucharout,
		oldcucharerr = cucharerr,
		oldprmishap = prmishap;

	unless rc_ved_char_consumer or not(rc_charout_buffer) then
		veddiscout(rc_charout_buffer) -> rc_ved_char_consumer
	endunless;
;;; 	define lconstant rc_ved_char_consumer(char);
;;; 		;;; if editing, then send output to a VED window
;;; 		vededit(rc_charout_buffer);
;;; 		dlocal vedbreak = true;
;;; 		unless vedline >= vvedbuffersize then vedendfile() endunless;
;;; 		vedcharinsert(char)
;;; 	enddefine;

	
	define lconstant prmishapinved();
		;;; If errors occur, restore output
		dlocal cucharout = oldcucharout, cucharerr = oldcucharerr;
		oldprmishap();
	enddefine;

	dlocal cucharout, cucharerr, prmishap;

	if rc_charout_buffer
		and (vedinvedprocess or vedediting) then

		rc_ved_char_consumer ->> cucharout -> cucharerr;
		prmishapinved -> prmishap;

	endif;

	until Events_list == [] do
		;;; [event ^event list ^Events_list]=>
		lvars event;
		sys_grbg_destpair(Events_list) -> (event, Events_list);
		rc_process_in_queue(event);
		;;; ['queue done' events ^Events_list]=>
	enduntil;

	rc_sync_display();	

	;;; now process deferred events, outside of the context used for the
	;;; current active window object
	;;; 'doing deferred '=>
	chain(rc_do_deferred_list);
enddefine;

define vars handle_drawing_deferred();
	;;; invoke this after drawing a movable object.
	;;; use a counter to prevent loops
	lvars x = 0;
	until Drawing_defer_list == [] and Events_list == []
	or x == 30	;;; is this safe?? Can it lose events??
	do
		;;; Save Drawing_defer_list and quickly make it empty in case
		;;; new events add to it.
		lvars list = Drawing_defer_list;
		[] -> Drawing_defer_list;
		;;; Deal with drawing events
		list nc_<> Events_list -> Events_list;
		rc_process_event_queue();
		x fi_+ 1 -> x;
	enduntil
enddefine;

;;; Two methods to invoke the above, so as to handle any events
;;; deferred while a picture object was being drawn.

define :method rc_draw_linepic(pic:rc_selectable);

	call_next_method(pic);

enddefine;

define :method rc_undraw_linepic(pic:rc_selectable);

	call_next_method(pic);

enddefine;

define :method rc_move_to(pic:rc_selectable, x, y, mode);
	dlocal rc_moving_picture_object;
	if pic == rc_moving_picture_object then
		;;; already moving
		return();
	endif;
	pic -> rc_moving_picture_object;
	call_next_method(pic, x, y, mode);
	unless Drawing_defer_list == [] then
		handle_drawing_deferred();
	endunless;
enddefine;

define vars procedure rc_external_defer_apply();
	;;; User definable version of rc_external_defer_apply
	
	external_defer_apply()
enddefine;


;;; if this is assigned a widget then only that widget's events will
;;; be handled
vars rc_sole_active_widget = false;

define rc_is_contained_window(w, container) -> boole;

	if w == container then true
	elseif not(w) then false
	else
		lvars win_obj = rc_window_object_of(w);
		if win_obj then
			lvars win_container = rc_window_container(win_obj);
			rc_is_contained_window(rc_widget(win_container), container)
		else
			false
		endif
	endif -> boole

enddefine;

define vars rc_really_handle_event(w, item, data, proc);
    ;;; This procedure is invoked when the event occurs. It builds a
    ;;; record of the event and if necessary puts it onto the end of
    ;;; Events_list to be handled properly later. The record is a list
    ;;; containing w, item, data, proc, the x location and the y location,
    ;;; and the modifier string.

	lvars
		oldcucharout = cucharout,
		oldcucharerr = cucharerr,
		oldprmishap = prmishap;


	unless rc_ved_char_consumer or not(rc_charout_buffer) then
		veddiscout(rc_charout_buffer) -> rc_ved_char_consumer
	endunless;

	define lconstant prmishapinved();
		;;; If errors occur, restore output
		dlocal cucharout = oldcucharout, cucharerr = oldcucharerr;
		dlocal prmishap = oldprmishap;
		vedinterrupt();
	enddefine;
	
	dlocal cucharout, cucharerr, prmishap;

	;;; If necessary set up output to go into Ved buffer.
	if rc_charout_buffer
		and (vedinvedprocess or vedediting  or vedusewindows == "x") then
		rc_ved_char_consumer ->> cucharout -> cucharerr;
		prmishapinved -> prmishap;
	endif;

	;;; w is window, item is "button" or "move", data will be
	;;; the button number, < 0 if released. proc is the procedure
	;;; that will eventually handle the event, e.g. button or move
	;;; or keypress handler
	;;; [handling ^proc]=>

	;;; For debugging
	;;; [%XptWidgetCoords(w)%] =>
	;;; [%w=rc_window, rc_xorigin, rc_yorigin %]=>
	;;;[handling ^w ^(rc_window_title(rc_window_object_of(w))) ^item ^proc]=>

	;;; Some panels may wish to grab total control: you can't do anything
	;;; outside that panel. Exit handler if that is attempted.
	returnif(rc_sole_active_widget and not(rc_is_contained_window(w,rc_sole_active_widget)));

	;;; Check that widget is still live. It may have been killed by some action
	;;; being completed while this was being invoked.

	returnunless(XptIsLiveType(w, "Widget"));

	;;; [handling ^w ^(rc_window_title(rc_window_object_of(w))) ^item ^proc]=>
	lvars event;
	conslist(
		#| w, item, data, proc,
			XptVal w(XtN mouseX, XtN mouseY, XtN modifiers) |# ) -> event;

	if iscaller(rc_really_handle_event,1) == 1 or rc_in_event_handler then
		;;; 'postponing' =>
		;;; [iscaller % iscaller(rc_really_handle_event, 1) % handerl ^rc_in_event_handler]=>

		Events_list nc_<> (conspair(event,[])) -> Events_list;
		;;; 'returning '><rc_in_event_handler=>
    	;;; 'returning '>< iscaller(rc_really_handle_event, 1)=>
		;;; syscallers() ==>
		return();

    elseif ispair(Events_list) then
		;;; 'doing queue'=>
		;;; first process events already in queue.
		Events_list nc_<> (conspair(event,[])) -> Events_list;
		rc_process_event_queue();
	else
		;;; 'do now'=>
		;;; [queue ^Events_list]==>
		;;; Nothing in the queue.
		;;; Process the event
		rc_process_event(event);
		;;; 'processed event '=>
		;;; [queue ^Events_list]==>
		;;; Then deal with any new events in the queue
		rc_process_event_queue();
		;;; 'processed queue'=>
	endif;

enddefine;

define vars rc_handle_event(w, item, data, proc);
	lvars
		oldcucharout = cucharout,
		oldcucharerr = cucharerr,
		oldprmishap = prmishap;

	unless rc_ved_char_consumer or not(rc_charout_buffer) then
		veddiscout(rc_charout_buffer) -> rc_ved_char_consumer
	endunless;

	define lconstant prmishapinved();
		;;; If errors occur, restore output
		dlocal cucharout = oldcucharout, cucharerr = oldcucharerr;
		oldprmishap();
	enddefine;
	
	dlocal cucharout, cucharerr, prmishap;

	;;; If necessary set up output to go into Ved buffer.
	if rc_charout_buffer
		and (vedinvedprocess or vedediting  or vedusewindows == "x") then
		rc_ved_char_consumer ->> cucharout -> cucharerr;
		prmishapinved -> prmishap;
	endif;


	if vedusewindows = "x" and not(vedinvedprocess) then
		rc_sync_display();
		vedinput(rc_really_handle_event(%w, item, data, proc%));
		external_defer_apply(vedprocess_try_input);
	else
		external_defer_apply(rc_really_handle_event(%w, item, data, proc%));
		;;;rc_really_handle_event(w, item, data, proc);
	endif;
	true -> pop_asts_enabled;
	sys_raise_ast(false);
enddefine;


;;; Made global so that event handlers using it can be redefined by users.

global vars
	;;; This is made true in rc_mousepic. Disables event handling while
	;;; event handlers are being changed.
	in_rc_mousepic = false,
	;

define vars procedure rc_do_button_actions(widget, item, data);
	;;; Invoke the handler for mouse button up or down events

	;;; [in mousepic ^in_rc_mousepic]=>
	;;; Don't handle events while event handlers are being changed.
	returnif(in_rc_mousepic);

	lvars pic, widget, item, data;
	exacc ^int data -> data; ;;; button number. positive if pressed
	if data < 0 then
		;;;[HANDLING up ^item]=>
		rc_handle_event(widget, item, -data, rc_system_button_up_callback);
		;;; [UP DONE ^item]=>
	else
		rc_handle_event(widget, item, data, rc_system_button_down_callback)
	endif;
enddefine;

define vars procedure rc_do_move_actions(widget, item, data);
	;;; Invoke the handler for move or drag events.

	;;; Don't handle move events while event handlers are being changed.
	returnif(in_rc_mousepic);

	;;; Temporarily disable interrupts while handling a
	;;; motion event. See REF * pop_asts_enabled
	dlocal pop_asts_enabled = false;

	exacc ^int data -> data; ;;; button number. positive if pressed
	if data < 256 then

		;;; A move, not a drag. Check whether this is a "dragonly" type
		;;; of window, and of so, do nothing.

		lvars win_obj = rc_window_object_of(widget);
		unless win_obj and rc_drag_only(win_obj) then
			rc_handle_event(widget, item, data, rc_system_move_callback)
		endunless;

	else

		;;; Dragging. Identify the button held down.
		if data >= 256 and data < 512 then 1
		elseif data >= 512 and data < 1024 then 2
		else
			3
		endif -> data;
		rc_handle_event(widget, item, data, rc_system_drag_callback)
	endif
enddefine;

define vars procedure rc_do_mouse_actions(widget, item, data);
	;;; This invokes handers for mouse entering or leaving window events.

	;;; Don't handle events while event handlers are being changed.
	returnif(in_rc_mousepic);

	exacc ^int data -> data; ;;; 7 if entering 8 if leaving
	;;;;[ENTER/LEAVE ^widget ^item ^data] =>
	if data == 7 then
		rc_handle_event(widget, item, data, rc_system_entry_callback)
	else
		rc_handle_event(widget, item, data, rc_system_exit_callback)
	endif
enddefine;


define vars procedure rc_do_keyboard_actions(widget, item, data);
	;;; Invoke handler for keypress events
	;;; 'starting keyboard' =>
	;;; Don't handle events while event handlers are being changed.
	returnif(in_rc_mousepic);

	lvars pic, widget, item, data;
	exacc ^int data -> data; ;;; ascii code positive if pressed
	rc_handle_event(widget, item, data, rc_system_keypress_callback)
enddefine;


;;; The following versions become the actual callbacks. Use indirection to
;;; make debugging easier.

define RC_DO_BUTTON_ACTIONS(widget, item, data );
	dlocal rc_inside_callback = true;
	rc_do_button_actions(widget, item, data );
enddefine;

define RC_DO_MOVE_ACTIONS(widget, item, data );
	dlocal rc_inside_callback = true;
	rc_do_move_actions(widget, item, data );
enddefine;

define RC_DO_MOUSE_ACTIONS(widget, item, data );
	dlocal rc_inside_callback = true;
	rc_do_mouse_actions(widget, item, data );
enddefine;

define RC_DO_KEYBOARD_ACTIONS(widget, item, data );
	dlocal rc_inside_callback = true;
	rc_do_keyboard_actions(widget, item, data);
enddefine;


/*

define -- Resize actions

*/

define :method rc_resize_object(win_obj:rc_resizeable);
    ;;; The default method for doing the re-sizing. Note the
	;;; importance of using external_defer_apply

	define lconstant do_resize_window(win_obj);
		dlocal in_rc_resize_object;

		;;; [RESIZING ^win_obj] ==>
		unless in_rc_resize_object then
			true -> in_rc_resize_object;
			
			XptSyncDisplay(XptDefaultDisplay);
			
			;;; this will update the widget, using current actual
			;;; window size
			rc_window_location(win_obj) -> ( , , , );
			XptSyncDisplay(XptDefaultDisplay);
		endunless;
	enddefine;

	;;; external_defer_apply(do_resize_window, win_obj, 1);
	do_resize_window(win_obj);
enddefine;

define vars procedure rc_do_resize_actions(widget_or_shell);
	;;; This invokes handlers for resize events
	;;; Don't handle events while event handlers are being changed
	;;; or set up
	returnif(in_rc_mousepic);
	lvars
		handler,
		win_obj = rc_window_object_of(widget_or_shell),
		handlers = recursive_valof(rc_resize_handler(win_obj));

		if islist(handlers) then
			;;; it's a list of handlers
			for handler in handlers do
				handler(win_obj);
			endfor;
		else
			handlers(win_obj);
		endif;
enddefine;

define RC_DO_RESIZE_ACTIONS(widget);
	;;; This is set as the callback. Use indirection to allow
	;;; the invoking procedure to be changed after callback is set.
	dlocal rc_inside_callback = true;
	unless in_rc_resize_object then
		;;; ['resizing' ^widget]=>
		XptSyncDisplay(XptDefaultDisplay);
		external_defer_apply(rc_do_resize_actions, widget, 1);
		;;; rc_do_resize_actions(widget);
	endunless;
enddefine;

define :method rc_set_resize_handler(win_obj: rc_window_object);

	;;; suppress various event handlers.
	dlocal in_rc_mousepic = true;
	unless rc_resize_handler(win_obj) then
		;;; now set the callback
		XptSyncDisplay(XptDefaultDisplay);
		RC_DO_RESIZE_ACTIONS-> XptResizeResponse(rc_window_shell(win_obj));

		"rc_resize_object" -> rc_resize_handler(win_obj);
		"resize" :: rc_event_types(win_obj)  -> rc_event_types(win_obj);
	endunless;

enddefine;


/*
define -- Making the window mouse sensitive
*/

define rc_mousepic(win, /* list */);
	;;; Optional list gives type of sensitivity
	;;; Setup the win so that the event handlers are installed.
	;;; Associate an instance of rc_window_object with it.
	;;; see REF * XT_CALLBACK

	;;; win is either a graphic widget or window_object

	;;; the optional list is given then that can be used to specify
	;;; which class of events to react to

	;;; disable event handling while event handlers are being changed
	dlocal in_rc_mousepic = true;

	lvars list ;

	if islist(win) or win == false then
		;;; set up both args
		(), win -> (win, list);

		if list then
			;;; check that the list has only legal words
			lconstant event_types = [button motion dragonly keyboard mouse resize];
			lvars item;
			for item in list do
				unless lmember(item, event_types) then
					mishap('WRONG EVENT TYPE', [^item NOT IN ^event_types])
				endunless;
			endfor;
		endif
	else
		[] -> list;
	endif;

	lvars win_obj;
	if isrc_window_object(win) then
		win -> win_obj;
		rc_widget(win_obj) -> win
	else
		rc_window_object_of(win) -> win_obj;
		unless win_obj then
			;;; No corresponding window object.
			mishap('WINDOW HAS NO WINDOW OBJECT: use rc_new_window_object',[^win]);
		endunless;
	endif;

	if list == false then

		XtRemoveAllCallbacks(win, XtN buttonEvent);
		XtRemoveAllCallbacks(win, XtN motionEvent);
		XtRemoveAllCallbacks(win, XtN keyboardEvent);
		XtRemoveAllCallbacks(win, XtN mouseEvent);

		false -> rc_sensitive_window(win_obj);
		false -> rc_resize_handler(win_obj);

		false -> rc_event_types(win_obj);

		return();
	endif;

	lvars types = rc_event_types(win_obj);

	;;; add new event types as needed

	;;; make it mouse sensitive
	if list == [] or lmember("button", list) then

		unless lmember("button", types) then
			XptSyncDisplay(XptDefaultDisplay);

			;;; SET UP BUTTON EVENTS
			;;; XtAddCallback(win, XtN buttonEvent, RC_DO_BUTTON_ACTIONS, "button");
			XptAddCallback(win, XtN buttonEvent, RC_DO_BUTTON_ACTIONS, "button", identfn);
			"button" :: types ->> types -> rc_event_types(win_obj);
		endunless;

	endif;

	if list == [] or lmember("motion", list) or lmember("dragonly", list)
	then
		unless lmember("motion", types) then
			XptSyncDisplay(XptDefaultDisplay);
			;;; SET UP MOTION EVENTS
			;;; XtAddCallback(win, XtN motionEvent, RC_DO_MOVE_ACTIONS, "move");
			XptAddCallback(win, XtN motionEvent, RC_DO_MOVE_ACTIONS, "move", identfn);
			"motion" :: types ->> types -> rc_event_types(win_obj);
			if lmember("dragonly", list) then
				;;; ignore motion events with button up
				true -> rc_drag_only(win_obj);
			endif;
		endunless;
	endif;

	if list == [] or lmember("mouse", list) then
		unless lmember("mouse", types) then
			XptSyncDisplay(XptDefaultDisplay);
			;;; SET UP ENTER/LEAVE EVENTS
			;;; XtAddCallback(win, XtN mouseEvent, RC_DO_MOUSE_ACTIONS, "mouse");
			XptAddCallback(win, XtN mouseEvent, RC_DO_MOUSE_ACTIONS, "mouse", identfn);
			"mouse" :: types ->> types -> rc_event_types(win_obj);
		endunless;
	endif;

	if list == [] or lmember("keyboard", list) then
		unless lmember("keyboard", types) then
			XptSyncDisplay(XptDefaultDisplay);
			;;; SET UP KEYBOARD EVENTS
			;;; XtAddCallback(win, XtN keyboardEvent, RC_DO_KEYBOARD_ACTIONS, "key");
			XptAddCallback(win, XtN keyboardEvent, RC_DO_KEYBOARD_ACTIONS, "key", identfn);
			"keyboard" :: types ->> types -> rc_event_types(win_obj);
		endunless;
	endif;

	if lmember("resize", list) then
		unless lmember("resize", types) then
			"resize" :: types ->> types -> rc_event_types(win_obj);
			rc_set_resize_handler(win_obj);
		endunless;
	endif;

	true -> rc_sensitive_window(win_obj);
enddefine;


define rc_mousepic_disable(widget);
	;;; Undo the effect of rc_mousepic

	;;; disable event handling while event handlers are being changed
	dlocal in_rc_mousepic = true;

	lvars win_obj;
	if isrc_window_object(widget) then
		widget -> win_obj;
		rc_widget(win_obj) -> widget
	else
		rc_window_object_of(widget) -> win_obj;
		unless win_obj then
			;;; No corresponding window object.
			mishap('WINDOW HAS NO WINDOW OBJECT: use rc_new_window_object',[^widget]);
		endunless;
	endif;

		XtRemoveCallback(widget, XtN buttonEvent, RC_DO_BUTTON_ACTIONS, "button");
		XtRemoveCallback(widget, XtN motionEvent, RC_DO_MOUSE_ACTIONS, "mouse");
		XtRemoveCallback(widget, XtN motionEvent, RC_DO_MOVE_ACTIONS, "move");
		XtRemoveCallback(widget, XtN keyboardEvent, RC_DO_KEYBOARD_ACTIONS, "key");
		false -> rc_sensitive_window(win_obj);
enddefine;

/*
define -- Adding picture objects to a window
*/

define rc_do_addpic_to_window(pic, win_obj, atfront);
	lvars
		list = rc_window_contents(win_obj);

	if fast_lmember(pic, list) then
		delete(pic, list, nonop ==) -> list;
	endif;
	if atfront then
		conspair(pic,list)
	else
		list nc_<> [^pic]
	endif -> rc_window_contents(win_obj);

enddefine;

define :method rc_add_pic_to_window(pic:rc_selectable, win_obj:rc_window_object, atfront);
	;;; make the window mouse sensitive
	if rc_event_types(win_obj) == [] then
		rc_mousepic(win_obj)
	endif;

	rc_do_addpic_to_window(pic, win_obj, atfront);
enddefine;

define :method rc_add_pic_to_window(pic:rc_keysensitive, win_obj:rc_window_object, atfront);
	;;; make the window mouse sensitive
	if rc_event_types(win_obj) == [] then
		rc_mousepic(win_obj)
	endif;

	rc_do_addpic_to_window(pic, win_obj, atfront);
enddefine;



define :method rc_remove_pic_from_window(pic:rc_selectable, win_obj:rc_window_object);
	delete(pic, rc_window_contents(win_obj), nonop ==) -> rc_window_contents(win_obj)
enddefine;


define :method rc_remove_pic_from_window(pic:rc_keysensitive, win_obj:rc_window_object);
	delete(pic, rc_window_contents(win_obj), nonop ==) -> rc_window_contents(win_obj)
enddefine;


endexload_batch;
endsection;
nil -> proglist;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 16 2002
		Allowed rc_charout_buffer to be false.
--- Aaron Sloman, Sep 14 2002
	Suggested by Jonathan Cunningham:
	Altered rc_picture_selected_type to use recursive_valof on the
	result of rc_mouse_limit(pic).

--- Aaron Sloman, Sep 14 2002
		Improved the test for whether rc_process_event(event) should
		restore rc_current_window_object to an earlier value.
--- Aaron Sloman, Sep 12 2002
		Put extra checks for live widget in rc_really_handle_event
		and other places
--- Aaron Sloman, Sep 10 2002
		Sorted out obscure bug that caused some events not to be handled
--- Aaron Sloman, Sep  9 2002
		Fixed rc_mousepic_disable, which had previously stopped working.

--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- 6 Sep 2002
		Renamed rc_handle_event as rc_really_handle_event and made
        rc_handle_event use vedinput to start a closure of
        rc_really_handle_event in the case where XVed is in use and is
        waiting for input. Otherwise rc_handle_event immediately
        calls rc_really_handle_event
--- Aaron Sloman, Sep  5 2002
		Made all events go via vedinput if in XVed

--- Aaron Sloman, Aug  4 2002
		Made to invoke
		rc_handle_vedwarpcontext

--- Aaron Sloman, Jul 27 2002
	Allowed rc_mousepic to set resize handling

	Altered rc_button_1_drag to ensure that the currently dragged object is
	also the currently selected object in the window.
--- Aaron Sloman, Jul 25 2002
		Added mechanisms for re-sizing a window object.
 	define :method rc_resize_object(win_obj:rc_resizeable);
	define vars procedure rc_do_resize_actions(widget_or_shell);
	define RC_DO_RESIZE_ACTIONS(widget);
	define :method rc_set_resize_handler(win_obj: rc_window_object);

	These facilities use new additions to LIB rc_window_object, to support
	resizable windows.

--- Aaron Sloman, Jul 19 2002
		Added method rc_under_mouse_control
		Added procedure rc_release_mouse_control;
		Added global variables
			rc_button_1_is_down
			rc_button_2_is_down
			rc_button_3_is_down

		Made these no longer lconstant
			rc_do_deferred_list
			rc_is_contained_window
			RC_DO_BUTTON_ACTIONS
			RC_DO_MOVE_ACTIONS
			RC_DO_MOUSE_ACTIONS
			RC_DO_KEYBOARD_ACTIONS
			rc_do_addpic_to_window
		
--- Aaron Sloman, Sep 15 2000
	added two new (part) methods:
		rc_add_pic_to_window(pic:rc_keysensitive, win_obj:rc_window_object, atfront);
		rc_remove_pic_from_window(pic:rc_keysensitive, win_obj:rc_window_object);

	Made selection of picture_object via mouse take account of type
	of event. Introduced
		:method rc_picture_selected_type(win_obj:rc_window_object, x, y, type) -> num;
		find_selected_object_type(window_obj, x, y, type) -> obj;

	if rc_transparent_objects is true then type will be one of isrc_keysensitive
	or isrc_keyselectable. Otherwise type will be identfn and the first object
	whose sensitive area includes the mouse will be selected.
		See HELP RC_EVENTS for details

--- Aaron Sloman, Sep 14 2000
	Made in_rc_mousepic a global variable so that users can
	redefine handlers using it.

	Changed rc_mousepic to allow "dragonly" event type, and made
	handlers check rc_drag_only(win_obj)

--- Aaron Sloman, Sep 11 2000
		Introduced HELP RC_EVENTS, giving an overview of event handling
		Rename real_handle_event as rc_process_event_queue
--- Aaron Sloman, Sep  9 2000
	Some additional cleaning up of event handler cases to prevent unwanted
	interactions. Introduced in_rc_process_event
--- Aaron Sloman, Mar  8 2000
	Changed apply_or_unpack so that it takes an optional extra argument, key.
	This simplifies rc_system_keypress_callback
--- Aaron Sloman, Mar  7 2000
	Fixed bug in method  rc_button_1_drag (for rc_selectable). The variable
	rc_current became unset if key was pressed during dragging.
--- Aaron Sloman, Mar  5 2000
	Made it possible for an object to have multiple event handlers associated with each
	category by allowing an event handler to be a list.
	Introduced apply_or_unpack, and the variable rc_no_more_handlers

--- Aaron Sloman, Feb 28 2000
	Introduced rc_charout_buffer, instead of 'output.p'
--- Aaron Sloman, Feb 21 2000
	Cleaned up process_defer_list() a bit, and removed this
		rc_reset_context(explode(rc_window_frame(rc_active_window_object)));
--- Aaron Sloman, Jul 30 1999
	Generalised handling of rc_sole_active_widget to allow a contained widget to
	be active (e.g. a slider panel, or scrolling text widget). Uses rc_is_contained_window
--- Aaron Sloman, Jul 29 1999
	Fixed some of the handling of deferred events.
	Made action buttons deffered by default, unless POPNOW is used.
--- Aaron Sloman, Jul 28 1999
	Changed to make actual callbacks invoke user definable callback handlers,
	to simplify debugging, etc. This makes available to users
		define vars procedure rc_do_button_actions(widget, item, data);
		define vars procedure rc_do_move_actions(widget, item, data);
		define vars procedure rc_do_mouse_actions(widget, item, data);
		define vars procedure rc_do_keyboard_actions(widget, item, data);

	removed the calls of external_defer_apply controlled by #_IF
		
--- Aaron Sloman, Jul  5 1999
	Used #_IF to control use of external_defer_apply, for older versions
	of Poplog.
--- Aaron Sloman, May 29 1999
	Now use in_rc_mousepic to prevent unwanted interactions???

--- Aaron Sloman, May 26 1999
	Used external defer apply everywhere by default
	made rc_modifier_codes available
--- Aaron Sloman, Nov 15 1997
	added
		rc_selected_picture_objects
		rc_selected_window_objects
		rc_prev_active_window_object
		rc_prev_active_picture_object
		new methods for dealing with these and the procedure
		rc_kill_selected_window_objects
--- Aaron Sloman, Aug 28 1997
	Introduced rc_sole_active_widget. Used in rc_message_wait and
	rc_popup_query
--- Aaron Sloman, Aug 17 1997
	Stopped deferred actions resetting rc_xorigin, etc.
--- Aaron Sloman, Aug  10 1997
	Had to make further changes to reduce unwanted interactions between
	things drawn by programs and button actions

--- Aaron Sloman, Aug  7 1997
	Finally (?) cleaned up dragging of already moving objects, by using
	the variable
		rc_moving_picture_object
--- Aaron Sloman, Aug  6 1997
	Fixed event handling for objects being dragged etc. while they are
	being redrawn.

--- Aaron Sloman, Aug  2 1997
	Event handling for keyboard sensitivity fixed

--- Aaron Sloman, Aug  1 1997
	Made event handling more modular, and made "defer" processing
	more consistent with non-deferred processing.

	Changed to make sure current window object's frame is set during
	event handling.
--- Aaron Sloman, Jul 23 1997
	Made things more customisable, and inserted more subtle checks
	for X stuff.
--- Aaron Sloman, Jul 11 1997
	Made windows become current if clicked on with CTRL and mouse
	button 1.
--- Aaron Sloman, Jun 21 1997
	Introduced rc_external_defer_apply
--- Aaron Sloman, Jun 14 1997
	Made rc_add_pic_to_window call rc_mousepic if necessary
--- Aaron Sloman, Jun 10 1997
		Added code for rc_event_types(win_obj);
--- Aaron Sloman, Jun 10 1997
	Changed method
 		rc_button_1_drag(pic:rc_selectable, x, y, modifiers);
	so that draggint without shift also works better.
--- Aaron Sloman, Jun  9 1997
	Changed method rc_button_1_down(pic:rc_selectable, x, y, modifiers)
	so that if shift key is down and there is a selected object it
	remains selected.
--- Aaron Sloman, Apr 19 1997
	Introduce entry and exit actions, via new methods
		rc_mouse_enter(pic:rc_selectable, x, y, modifiers);
		rc_mouse_exit(pic:rc_selectable, x, y, modifiers);
	and new slots (in lib rc_window_object)
		slot rc_entry_handler ="rc_mouse_enter";
		slot rc_exit_handler ="rc_mouse_exit";
	These methods are only applied to rc_window_object instances, not the
	pictures.

--- Aaron Sloman, Apr 13 1997
	Generalised procedure selected so that rc_mouse_limit entries in vector can be
	either pair of diagonally opposite corners.
--- Aaron Sloman, Apr  8 1997
	Replaced XtAddCallback with XptAddCallback

--- Aaron Sloman, Apr  4 1997
	Added rc_clear_events();
	Clarified restoration of rc_current_window_object by event handler.

	Added mechanism for defer_actions. These can change
		rc_current_window_object
	non-locally.

--- Aaron Sloman, Mar 28 1997
	Got rid of rc_live_window and put everything into the
	rc_window_object class
	included getting rid of all the live_window stuff

	Removed rc_*mousepic_start


--- Aaron Sloman, Mar 24 1997
	Made rc_redraw_window_object set its argument to
		become rc_current_window_object
	as rc_clear_window_object already did.

--- Aaron Sloman, Mar 22 1997
	Extended rc_mouse_limit: it can now be a procedure. See
	example in TEACH RC_LINEPIC
--- Aaron Sloman, Mar 19 1997
	Added rc_live_*win_of_widget, to fix rc_transxyin
--- Aaron Sloman, Jan 18 1997
	Allowed handlers to be false
--- Aaron Sloman, Jan 17 1997
	Added defer event lists, and removed localisation of current window,
	etc. in the event handler.
--- Aaron Sloman, Jan 12 1997
	Extended rc_mousepic_disable to cope with window objects
--- Aaron Sloman, Jan  8 1997
	Added rc_current_object, set in "real" handler
--- Aaron Sloman, Jan  8 1997
	Changed to allow rectangular sensitive area
--- Aaron Sloman, Jan  6 1997
	Changed to accommodate enlarged frame vector
--- Aaron Sloman, Jan  5 1997
	Many changes to make this work with window objects. Had to set the current
	window object during event handling.
--- Aaron Sloman, Jan  4 1997
	introduced class rc_window_object and changed the property name to
	rc_window_object_of
--- Aaron Sloman, Jan  4 1997
	Added rc_cur*rent_window for event handlers.
--- Aaron Sloman, Jan  2 1997
	Made the event handler go to the end of the 'output.p' file if
	necessary.
--- Aaron Sloman, Jan  1 1997
	added rc_fast_drag, rc_fast_move and tidied up event handling

CONTENTS


To access these use: ENTER g define

 define -- Global variables and mixin and class definitions
 define rc_create_mouse_limit(pic);
 define :method vars rc_coords(pic: rc_selectable) /* -> (x, y) */;
 define :method updaterof rc_coords(/*x, y,*/ pic:rc_selectable);
 define -- Utilities and methods concerned with mouse actions
 define rc_object_selected(x, y, picx, picy, piclim, pic) /* -> boole */;
 define :method rc_pictures_selected(win_obj:rc_window_object, x, y, findone) -> num;
 define :method rc_picture_selected_type(win_obj:rc_window_object, x, y, type) -> num;
 define -- The core utilities for handling callbacks
 define rc_defer_apply(proc);
 define :method rc_mousexyin(win_obj:rc_window_object, x, y) /* -> (x, y) */;
 define find_selected_object(window_obj, x, y) -> obj;
 define find_selected_object_type(window_obj, x, y, type) -> obj;
 define vars procedure rc_get_handler(obj, type, button) -> handler;
 define vars apply_or_unpack(proc, obj, x, y, modifiers, /*key*/);
 define vars procedure rc_system_button_down_callback(obj, x, y, modifiers, item, button);
 define rc_release_mouse_control();
 define vars procedure rc_system_button_up_callback(obj, x, y, modifiers, item, button);
 define vars procedure rc_system_move_callback(obj, x, y, modifiers, item, button);
 define vars procedure rc_system_drag_callback(obj, x, y, modifiers, item, button);
 define vars procedure rc_system_keypress_callback(obj, x, y, modifiers, data, key);
 define vars procedure rc_system_entry_callback(obj, x, y, modifiers, data, mode);
 define vars procedure rc_system_exit_callback(obj, x, y, modifiers, data, mode);
 define :method rc_set_front(pic:rc_selectable);
 define -- User definable event handlers
 define :method rc_button_1_down(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_down(pic:rc_window_object, x, y, modifiers);
 define :method rc_button_2_down(pic:rc_selectable, x, y, modifiers);
 define :method rc_make_selected(pic:rc_selectable, x, y, modifiers);
 define :method rc_make_unselected(pic:rc_selectable, x, y, modifiers);
 define :method rc_make_selected(pic:rc_window_object, x, y, modifiers);
 define :method rc_make_unselected(pic:rc_window_object, x, y, modifiers);
 define rc_kill_selected_window_objects();
 define :method rc_button_3_down(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_3_down(pic:rc_window_object, x, y, modifiers);
 define :method rc_button_1_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_2_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_3_up(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_1_drag(pic:rc_window_object, x, y, modifiers);
 define :method rc_button_1_drag(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_2_drag(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_2_drag(pic:rc_window_object, x, y, modifiers);
 define :method rc_button_3_drag(pic:rc_selectable, x, y, modifiers);
 define :method rc_button_3_drag(pic:rc_window_object, x, y, modifiers);
 define :method rc_move_mouse(pic:rc_selectable, x, y, modifiers);
 define :method rc_mouse_enter(pic:rc_selectable, x, y, modifiers);
 define :method rc_mouse_exit(pic:rc_selectable, x, y, modifiers);
 define :method rc_handle_keypress(pic:rc_selectable, x, y, modifiers, key);
 define :method rc_under_mouse_control(pic:rc_selectable) -> bool;
 define -- The actual event handlers
 define constant rc_modifier_codes =
 define rc_reset_context();
 define vars procedure process_defer_list();
 define rc_do_deferred_list();
 define rc_clear_events();
 define vars procedure rc_process_event(event);
 define rc_process_in_queue(event);
 define vars procedure rc_process_event_queue();
 define vars handle_drawing_deferred();
 define :method rc_draw_linepic(pic:rc_selectable);
 define :method rc_undraw_linepic(pic:rc_selectable);
 define :method rc_move_to(pic:rc_selectable, x, y, mode);
 define vars procedure rc_external_defer_apply();
 define rc_is_contained_window(w, container) -> boole;
 define vars rc_really_handle_event(w, item, data, proc);
 define vars rc_handle_event(w, item, data, proc);
 define vars procedure rc_do_button_actions(widget, item, data);
 define vars procedure rc_do_move_actions(widget, item, data);
 define vars procedure rc_do_mouse_actions(widget, item, data);
 define vars procedure rc_do_keyboard_actions(widget, item, data);
 define RC_DO_BUTTON_ACTIONS(widget, item, data );
 define RC_DO_MOVE_ACTIONS(widget, item, data );
 define RC_DO_MOUSE_ACTIONS(widget, item, data );
 define RC_DO_KEYBOARD_ACTIONS(widget, item, data );
 define -- Resize actions
 define :method rc_resize_object(win_obj:rc_resizeable);
 define vars procedure rc_do_resize_actions(widget_or_shell);
 define RC_DO_RESIZE_ACTIONS(widget);
 define :method rc_set_resize_handler(win_obj: rc_window_object);
 define -- Making the window mouse sensitive
 define rc_mousepic(win, /* list */);
 define rc_mousepic_disable(widget);
 define -- Adding picture objects to a window
 define rc_do_addpic_to_window(pic, win_obj, atfront);
 define :method rc_add_pic_to_window(pic:rc_selectable, win_obj:rc_window_object, atfront);
 define :method rc_add_pic_to_window(pic:rc_keysensitive, win_obj:rc_window_object, atfront);
 define :method rc_remove_pic_from_window(pic:rc_selectable, win_obj:rc_window_object);
 define :method rc_remove_pic_from_window(pic:rc_keysensitive, win_obj:rc_window_object);

 */
