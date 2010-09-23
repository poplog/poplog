/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_window_object.p
 > Purpose:         A class for objects associated with graphic windows
 > Author:          Aaron Sloman, Jan  4 1997 (see revisions)
 > Documentation:	HELP RCLIB, TEACH RCLIB_DEMO.P, HELP RC_EVENTS
 > Related Files:	LIB RC_MOUSEPIC, HELP RC_LINEPIC
					LIB RC_CONTROL_PANEL, HELP RC_CONTROL_PANEL
					LIB RC_BUTTONS, HELP RC_BUTTONS
 */

/*

uses rc_mousepic;

define -- Tests

rc_kill_window_object(w0);
vars w0 = rc_new_window_object(500,20,300,250,{0 0 1 1},'w0');
'W0' -> rc_window_title(w0);
'w0' -> rc_window_title(w0);
vars w00 = rc_new_window_object(-3,-1,300,250,{0 0 1 1},'w0');
w0.rc_screen_frame ==w00.rc_screen_frame =>
vars w00 = rc_new_window_object(-1,-1,300,250,{0 0 1 1},'w0');
vars w00 = rc_new_window_object("right","bottom",300,250,{0 0 1 1},'w0');
vars w00 = rc_new_window_object("right","top",300,250,{0 0 1 1},'w0');
vars w00 = rc_new_window_object("middle","middle",300,250,{0 0 1 1},'w0');
uses rc_mousepic;
rc_mousepic(w0);
rc_xscale,rc_yscale,rc_xorigin,rc_yorigin =>
w0=>
vars w01 = rc_new_window_object(30,20,100,150,{0 0 1 1},'w01',w0);
rc_kill_window_object(w01);
rc_window_container(w01) =>
rc_window_shell(w01) == rc_window_shell(w0) =>
rc_unmap_window_object(w01);
rc_map_window_object(w01);
rc_map_window_object(w0);
w01 -> rc_current_window_object;
w0 -> rc_current_window_object;
rc_current_window_object =>

rc_draw_blob(20,20, 20, 'red');
rc_draw_blob(120,20, 20, 'blue');
rc_hide_window(w01);
rc_show_window(w01);

XtUnmapWidget(rc_window_composite(w01));
XtMapWidget(rc_window_composite(w01));
rc_mousepic(w01);

rc_kill_window_object(w1);
vars w1 = rc_new_window_object(500,20,300,250,true,'w1');
rc_mousepic(w1);
rc_draw_blob(0,100, 20, 'green');
rc_draw_blob(100,100, 20, 'green');
rc_draw_blob(300,100, 20, 'green');
rc_draw_blob(250,100, 20, 'green');
'red' -> rc_background(rc_window);
w1.rc_screen_frame =>
XptWMShellCoords(rc_widget(w1)) =>
XptWidgetCoords(XptShellOfObject(rc_widget(w1))) =>
rc_window_location(w1) =>
w1.rc_screen_frame =>
w1.rc_fix_window_location;
rc_window_location(w1) -> rc_screen_coords(w1);

500, 400, false, false -> rc_window_location(w1);
600, 10, false, false -> rc_window_location(w1);
XptWMShellCoords(rc_widget(w1)) =>
XptWidgetCoords(XptShellOfObject(rc_widget(w1))) =>
w1.rc_screen_frame =>
rc_window_location(w1) =>
false, false, 500, false-> rc_window_location(w1);
false, false, false, 400-> rc_window_location(w1);
false, false, 400, 100-> rc_window_location(w1);
'red' -> rc_background(rc_window);
false, false, 480, 200-> rc_window_location(w1);
400, 10, 550, 300-> rc_window_location(w1);
XptWMShellCoords(rc_widget(w1)) =>
XptWidgetCoords(rc_widget(w1)) =>
XptWidgetCoords(rc_window_composite(w1)) =>
XptWidgetCoords(rc_window_shell(w1)) =>
XptWidgetCoords(XptShellOfObject(rc_widget(w1))) =>
w1.rc_screen_frame =>
rc_window_location(w1) =>

rc_hide_window(w1);
XptWMShellCoords(rc_widget(w1)) =>
XptWidgetCoords(XptShellOfObject(rc_widget(w1))) =>
XtIsRealized(rc_window) =>
rc_window_visible(w1) =>
rc_screen_frame(w1) =>
rc_window_location(w1) =>
rc_show_window(w1);
rc_screen_coords(w1) =>
rc_screen_coords(w1) -> rc_window_location(w1);
XptWMShellCoords(rc_widget(w1)) =>
XptWidgetCoords(XptShellOfObject(rc_widget(w1))) =>
500,40,300,250-> rc_window_location(w1);
500,20,300,250-> rc_window_location(w1);
XptWMShellCoords(rc_widget(w1)) =>
XptWidgetCoords(XptShellOfObject(rc_widget(w1))) =>
XtIsRealized(rc_window) =>
rc_screen_coords(w1)=>
rc_screen_coords(w1) -> rc_window_location(w1);
rc_raise_window(w1);
rc_window_location(w1) =>
w1.rc_fix_window_location;
rc_screen_frame(w1) =>

rc_kill_window_object(w1);

vars w2 = rc_new_window_object(500,20,150,25,true,'w2');
rc_screen_frame(w2) =>
rc_window_location(w2) =>
XptWidgetCoords(XptShellOfObject(rc_widget(w2))) =>
rc_kill_window_object(w2);

vars w3 = rc_new_window_object(600,500,150,25,true,"hidden");
w3.datalist ==>
rc_screen_frame(w3) =>
rc_screen_coords(w3) =>
rc_window_location(w3) =>
rc_show_window(w3);
rc_window_location(w3) =>
rc_screen_frame(w3) =>
XptWidgetCoords(XptShellOfObject(rc_widget(w3))) =>
rc_hide_window(w3);
'w3' -> rc_window_title(w3);
rc_show_window(w3);
rc_window_location(w3) =>
rc_screen_frame(w3) =>
rc_screen_coords(w3) -> rc_window_location(w3);
rc_hide_window(w3);
rc_kill_window_object(w3);

vars w4 = rc_new_window_object(600,20,150,25,true,"hidden", 'w4');
rc_show_window(w4);
rc_kill_window_object(w4);
vars w5 = rc_new_window_object(600,80,150,25,true,'w5', "hidden");
700, 400, false, false -> rc_window_location(w5);
rc_show_window(w5);
rc_window_location(w5) =>
rc_kill_window_object(w5);

;;; ADDITIONAL TESTS Ignore these tests for now
rc_destroy();
sysgarbage();
Bug in TVTWM (not in other Window managers apparently)
rc_new_window(300, 25, 800, 20, true);
XptWMShellCoords(rc_window) =>
** 0 0 3506 1850
XptWidgetCoords(XptShellOfObject(rc_window)) =>
** 503 45 300 250
600,20, 400, 300 -> XptWMShellCoords(rc_window);
300,20, 400, 100 -> XptWMShellCoords(rc_window);
rc_drawline(0,-100,150,-20);
rc_drawline(0,0,-150,200);
603, 45, false, false -> XptWidgetCoords(XptShellOfObject(rc_window));
XtRealizeWidget(XptShellOfObject(rc_window));
;;; window moves far over to the right, nearly off the screen
XptWMShellCoords(rc_window) =>
** 0 0 3506 1850
XptWidgetCoords(XptShellOfObject(rc_window)) =>
** 1103 65 300 250

*/

/*
define -- Libraries required and global vars
*/

section;

exload_batch;

uses objectclass
uses create_instance;	;;; to prevent identifier clash if loaded later
uses xlib
uses popxlib;
uses xt_widget;
uses xt_callback;
uses xt_event;
uses Xpw
uses XpwGraphic;
uses XpwPixmap;
uses xpwGraphicWidget;
uses xpwCompositeWidget;
uses xtApplicationShellWidget;
uses XpwScrollText;
uses xt_composite;

include xpt_constants.ph;

uses xpt_cursorplane;

;;; Should we use these facilities??
;;; uses XWindowManipulation

uses rc_graphic
uses rc_drawline_absolute
uses rclib
uses rc_sync_display
uses rc_setup_linefunction
uses rc_linepic;


;;; compile_mode :pop11 +strict;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;



;;; save old values of rc_graphic utilities
global constant
	oldrc_start, oldrc_new_window;

if isundef(oldrc_start) then rc_start -> oldrc_start endif;
if isundef(oldrc_new_window) then rc_new_window -> oldrc_new_window endif;

;;; Make a list of procedures from other libraries known to require
;;; previous versions of rc_start and rc_new_window
global vars use_rc_graphic_versions = [];

define lconstant call_old_rc_proc(oldproc) -> called;
	;;; This procedure will work out whether to invoke oldproc, and if so
	;;; will invoke it and return true. Otherwise it returns false.
	;;; Used in re-defined versions of rc_start and rc_new_window, below.
	lvars item;
	for item in use_rc_graphic_versions do
		if identprops(item) /== undef
			and isprocedure(valof(item))
			and iscaller(valof(item))
		then
			oldproc();
			true -> called;
			return();
		endif;
	endfor;
	false -> called;
enddefine;

;;; This will be defined below
global vars active rc_current_window_object;
	;;; The main user interface. By assigning to this the user
	;;; makes a window current, so that drawing occurs there.

global vars rc_border_allowance = false, rc_title_allowance = false;
	;;; These are estimated by the  procedure rc_adjust_window_location the
	;;; first time it is called. The first estimates the current border
	;;; width, the second the combination of title bar and border for the
	;;; top of each window. Users may adjust them if required.

global vars rc_window_sync_time = 5;
	;;; This integer represents hundredths of a second delay after calls
	;;; of XptSyncDisplay(XptDefaultDisplay)
	;;; via the procedure rc_window_sync, defined below.
	;;; For a slow display accessed over the network a larger delay may be
	;;; needed.

	;;; If rc_new_window_object is given false arguments for x and y
	;;; then use previous values plus these offsets.
global vars rc_window_x_offset = 20, rc_window_y_offset = 20;

lvars LAST_WINDOW_X = 100, LAST_WINDOW_Y = 100;

global vars rc_resize_threshold;
if isundef(rc_resize_threshold) then 4 -> rc_resize_threshold endif;

define rc_window_sync();
	;;; see lib rc_sync_display
	dlocal rc_sync_delay_time = rc_window_sync_time ;
	rc_sync_display()
enddefine;

/*
define -- Global property mapping widgets to objects

Set up a property mapping window widgets to rc_window_object instances
*/

define vars procedure rc_window_object_of =
	;;; associate an instance of rc_window_object with each graphic window
	newproperty([], 32, false, "tmparg")
enddefine;


/*
define -- The main mixin rc_selectable, and its sub-classes
*/

;;; Default value for rc_mouse_limit. Used for checking whether
;;; a given point is in the bounding box of an object or not.
;;; It can be a number, a four element vector, or a procedure.
;;; Default is a vector representing a 20x20 square.
global vars
	rc_select_distance =
		if isundef(rc_select_distance) then {-10 -10 10 10}
		else rc_select_distance
		endif;

;;; Mixin: rc_selectable. Either a window pane or a drawable object.
;;; Each instance has associated handlers. Is that overkill?
;;; should they be only associated with the class?
;;; Where handlers are button-related, use a vector of three words
;;;		or procedures. Use words for de-referencing later.

define :mixin vars rc_selectable;
	;;; uncommenting the following can cause the wrong drawing
	;;; procedure to be associated with selectables
	;;; is rc_linepic;	
	;;; This can be used with rc_linepic, or rc_linepic_movable.
	;;; 	The former is for static pictures.

	;;; Next slot can hold a distance, or a rectangle specified by a vector
	;;; or a procedure. Give it a copy of the default vaue.
	slot rc_mouse_limit = rc_select_distance;

	;;; Button event handlers. defined in LIB rc_mousepic
	;;; Keypress handlers can be added via mixin rc rc_keysensitive;
	slot rc_button_up_handlers =
		{ rc_button_1_up rc_button_2_up rc_button_3_up };
	slot rc_button_down_handlers =
		{ rc_button_1_down rc_button_2_down rc_button_3_down };
	slot rc_drag_handlers =
		{ rc_button_1_drag rc_button_2_drag rc_button_3_drag };

    ;;; Move event handlers. These are defined in LIB rc_mousepic
	slot rc_move_handler = "rc_move_mouse";
	slot rc_entry_handler ="rc_mouse_enter";
	slot rc_exit_handler ="rc_mouse_exit";
enddefine;

define :mixin vars rc_keysensitive;
	slot rc_keypress_handler = "rc_handle_keypress";
	slot rc_mouse_limit = rc_select_distance;
enddefine;

define :method vars rc_keypress_handler(pic:rc_linepic);
	;;; default is to have no handler for picture objects
	false
enddefine;

;;; Added 24 Jul 2002
define :mixin vars rc_resizeable;
	;;; The default handler rc_resize_object is defined in LIB rc_mousepic
	slot rc_resize_handler = false;
enddefine;

define :method vars rc_resize_handler(pic:rc_linepic);
	;;; By default, there's no handler
	false
enddefine;

/*
define -- Main class definition
*/

define :class vars rc_window_object;
	;;; The main class for graphical window objects, with handlers that
	;;; are defined below. Pictures and strings can be drawn in
	;;; instances of this.
	is rc_selectable  rc_keysensitive rc_resizeable;

	;;; in case this is contained in a larger window.
	slot rc_window_container = false;

	;;; The top level shell
	slot rc_window_shell = false;

	;;; The composite object
	slot rc_window_composite = false;

	;;; The graphical window
	slot rc_widget = false;

	;;; x, y, width, height
	slot rc_screen_frame = {0 0 0 0};

	;;; this was supposd to be used for something or other...
	;;; slot rc_screen_adjust = {0 0};

	;;; Two vectors containing 12 rc_graphic startup values
	;;;		rc_xorigin, rc_yorigin, rc_xscale, rc_yscale
	;;; this is a vector with rc_xorigin, rc_yorigin, rc_xscale, rc_yscale
	;;; Once set these do not change. They are used to set rc_window_frame
	slot rc_window_origin = {0 0 0 0};

	;;; this will hold origin variables plus other globals to be reset
	;;; just before this ceases to be the current window object, e.g.
	;;;		rc_xposition, rc_yposition, rc_heading,
	;;;     rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax
	slot lconstant RC_window_frame ;

	;;; Slot set true by rc_mousepic
	slot rc_sensitive_window == false;

	;;; Sensitive objects in this window
	slot rc_window_contents == [];

	slot lconstant WIN_FRAME;

	;;; The currently selected picture object in this window
	slot rc_mouse_selected == false;

	;;; Is there a real graphical object (a widget) yet
	slot rc_window_realized == false;

	;;; Is it currently visible or not
	slot rc_window_visible == false;

	;;; List of event types set by rc_mousepic
	slot rc_event_types == [];

	;;; if this is true, then motion events but not drag events
	;;; are processed
	slot rc_drag_only == false;

	;;; this slot value is accessed only via method rc_window_title
	slot RC_TITLE == 'Xgraphic';	;;; used by the method below.
	;;; not really needed
	slot rc_mouse_limit == 0;
enddefine;

/*
define -- Methods for manipulating rc_window_objects
*/

define :method rc_window_frame(win_obj:rc_window_object) -> vec;
	lvars vec = RC_window_frame(win_obj);
	;;; update the frame origin every time it is accessed
	 explode(rc_window_origin(win_obj)) ->
		(fast_subscrv(1, vec), fast_subscrv(2, vec), fast_subscrv(3, vec), fast_subscrv(4, vec))
enddefine;

define :method updaterof rc_window_frame(win_obj:rc_window_object);
	-> RC_window_frame(win_obj);
enddefine;

define :method rc_window_title(win_obj:rc_window_object) -> string;
	RC_TITLE(win_obj) -> string;
enddefine;

define :method updaterof rc_window_title(win_obj:rc_window_object);
	lvars win = rc_window_composite(win_obj);
	if isstring(win) or not(win) then
		;;; window not yet realised, so just change in win_obj
		->> rc_widget(win_obj)
	else
		;;; update actual ttile
		->> rc_title(win)
	endif -> RC_TITLE(win_obj)
enddefine;

;;; Method for getting and setting current screen_frame values
;;; without changing anything on the screen. That is done by
;;; rc_window_location and its updater
define :method rc_screen_coords(win_obj:rc_window_object) /* -> (x, y, w, h) */;
	explode(rc_screen_frame(win_obj)) /* ->(x, y, w, h) */;
enddefine;

define :method updaterof rc_screen_coords(x, y, w, h, win_obj:rc_window_object);
	lvars
		(oldx, oldy, oldw, oldh) = explode(rc_screen_frame(win_obj));
	;;; Don't change values where false
	if x then x else oldx endif,
	if y then y else oldy endif,
	if w then w else oldw endif,
	if h then h else oldh endif,
	 	fill(rc_screen_frame(win_obj)) ->;
enddefine;


;;;include xpt_constants.ph;
define rc_adjust_window_location(win_obj);
	;;; Adjust location if necessary
	unless rc_border_allowance then
		rc_window_sync();

		lvars
			win = rc_widget(win_obj),
			(x, y, , ) = rc_screen_coords(win_obj),
			shell = rc_window_shell(win_obj);

		rc_window_sync();

		;;; find out how much allowance needs to be made for borders
		;;; and title, by finding actual widget location
		lvars (newx, newy, , ) = XptWidgetCoords(shell);

		newx - x -> rc_border_allowance;
		newy - y -> rc_title_allowance;

	endunless;

enddefine;

;;; Method for getting location of internal origin:

define :method rc_window_xyorigin(win_obj:rc_window_object) -> (x, y);
	explode(rc_window_origin(win_obj)) -> (x, y, , )
enddefine;


lvars in_window_location = false;

;;; Method for getting and setting real screen values.
;;; Also updates size of graphic object if the window object has
;;; been resized using mouse.
define :method rc_window_location(win_obj:rc_window_object) -> (x, y, w, h);
	;;; Return x and y position, plus width and height of window on screen

	dlocal in_window_location = true;

	if rc_window_realized(win_obj) and rc_window_visible(win_obj)
	then

		lvars
			resizeable = rc_resize_handler(win_obj),
			container = rc_window_container(win_obj);

		unless container then
			rc_adjust_window_location(win_obj);
		endunless;

		;;; It turns out that this was needed for the way Steve Allen was interfacing
		;;; his widgets with RCLIB
		unless rc_window_composite(win_obj) then
			rc_screen_coords(win_obj) ->(x, y, w, h);
			return();
		endunless;

		;;; [COMPOSITE	%	XptWidgetCoords(rc_window_composite(win_obj)) %]==>
		;;; [SHELL %XptWidgetCoords(rc_window_shell(win_obj)) %]==>
		;;; [WIDGET %XptWidgetCoords(rc_widget(win_obj)) %]==>

		XptWidgetCoords(rc_window_composite(win_obj)) ->(x, y, w, h);
		if container then
			;;; XptWidgetCoords(rc_window_composite(win_obj)) ->(x, y, w, h);
			return();
		else
			;;; Get the real values, possibly changed by user or window manager
			lvars
				( , , widg_w, widg_h) = XptWidgetCoords(rc_widget(win_obj)),
				(shell_x, shell_y, shell_w, shell_h) = XptWidgetCoords(rc_window_shell(win_obj));
			;;; XptWMShellCoords(rc_widget(win_obj)) ->(x, y, w, h);
			;;; now the "allowances" can be used

				;;; See whether window has been changed manually
				;;; [w ^w shell_w ^shell_w h ^h shell_h ^shell_h]==>
				(shell_w, shell_h) -> (w, h);
				shell_x - rc_border_allowance -> x;
				shell_y - rc_title_allowance -> y;
				
				if resizeable
					and ( abs(w - widg_w) > rc_resize_threshold or abs(h - widg_h) > rc_resize_threshold )
				then

					false, false, w, h -> rc_window_location(win_obj);
				else
					;;; update internal store
					x, y, w, h -> rc_screen_coords(win_obj);
				endif;
		endif;
	else
		;;; Just use the internal screen_frame values
		rc_screen_coords(win_obj) ->(x, y, w, h);
	endif;
enddefine;

lvars in_window_location_updater = false;

define :method updaterof rc_window_location(x, y, w, h, win_obj:rc_window_object);
	;;; If any of the args are false, the corresponding value is left unchanged
	;;; Attempts to correct changed window location after update. Does not
	;;; always work.

	dlocal in_window_location_updater;
	returnif(in_window_location_updater);
	true -> in_window_location_updater;

	if rc_window_realized(win_obj) then

		lvars container = rc_window_container(win_obj);

		if container then
			(x, y, w, h) -> XptWidgetCoords(rc_window_composite(win_obj));
		else
			lvars
				win = rc_widget(win_obj),
				shell = rc_window_shell(win_obj),
				;;; composite = rc_window_composite(win_obj),
				visible = rc_window_visible(win_obj),
				(oldx, oldy, ,) = XptWidgetCoords(shell),
				( , , oldw, oldh) = XptWidgetCoords(win);

		returnif(
				(not(x) or x = oldx)
			and (not(y) or y = oldy)
			and (not(w) or w = oldw)
			and (not(h) or h = oldh));

			;;; rc_window_sync();

			;;; Change the location and size on the screen
			;;; if it is visible, allow for border and title bar
			lvars
				screenx =
				if x and visible then x + rc_border_allowance else x endif,
				screeny =
				if y and visible then y + rc_title_allowance else y endif;

			if (screenx and abs(screenx - oldx) > 4)
			or (screeny and abs(screeny - oldy) > 4)
			then
				screenx, screeny, false,false -> XptWidgetCoords(shell);
				;;; screenx, screeny -> XptVal (shell)(XtN x:XptPosition, XtN y:XptPosition)
			endif;

			 if (w and w /== oldw)  or (h and h /== oldh) then
			;;;	false, false, w,h -> XptWidgetCoords(composite);
			;;;	false, false, w, h -> XptWidgetCoords(shell);
				false, false, w, h -> XptWidgetCoords(win);
			 endif;

			;;; save new screen coords
				
			x, y, w, h -> rc_screen_coords(win_obj);

			if (w and w > oldw) or (h and h > oldh) then
				;;; Paint the background

				;;; Use a nested procedure to ensure that the dlocal expression works

			procedure();
				dlocal rc_current_window_object = win_obj;

				;;; rc_window_sync();

				lvars startcoord;

				if w and w > oldw then

					(w + oldw) div 2 -> startcoord;			
                    ;;; paint the extended bit the background colour
					rc_drawline_absolute(
						startcoord,0, startcoord, h or oldh, "background", w - oldw);
				endif;

				if h and h > oldh then
					(h + oldh) div 2 -> startcoord;			
					
                    ;;; paint the extended bit the background colour
					rc_drawline_absolute(
						0, startcoord, w or oldw, startcoord, "background", h - oldh);
				endif;
			endprocedure();
			endif;

			;;; rc_window_sync();
			XptSyncDisplay(XptDefaultDisplay);

			unless in_window_location then
				;;; Just in case the window manager has a different idea,
				;;; update internal records
				rc_window_location(win_obj) -> -> -> ->;
			endunless;
		endif;

	else
		;;; Not yet realized, so just change screen frame values
		x,y,w,h -> rc_screen_coords(win_obj);
	endif
enddefine;


define rc_fix_window_location(win_obj);
	;;; make location and size correspond to internal setting.
	rc_window_sync();
	rc_screen_coords(win_obj) -> rc_window_location(win_obj);
	rc_window_sync();
	;;; just in case the window manager has done it's own thing,
	;;; update the internal record.
	rc_window_location(win_obj) -> -> -> ->;
enddefine;

define :method print_instance(win_obj:rc_window_object);
	;;; Print title, location width height and number of sensitive objects
	printf('<window_obj %P %P %P %P %P items: %P>',
		[% rc_window_title(win_obj),
			rc_window_location(win_obj), length(rc_window_contents(win_obj)) %])
enddefine;

/*
define -- Creating and destroying window objects
*/

define rc_get_current_globals(window);
	;;; Return twelve items representing the current values for
	;;; a graphic environment, i.e.
	;;;		rc_xorigin, rc_yorigin, rc_xscale, rc_yscale,
	;;;		rc_xposition, rc_yposition, rc_heading
	;;;     rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax

	;;; Assume current RC frame should always be used as defaults
	;;; except for position and heading
	
	rc_xorigin, rc_yorigin, rc_xscale, rc_yscale,
	if window == rc_window then
		;;; its the current window, so save turtle coords
		rc_xposition, rc_yposition, rc_heading,
		;;; clipping variables
		rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax
	else
		;;; otherwise default initial turtle position, etc.
		0, 0, 0,
		;;; clipping variables
		false, rc_xmin, rc_ymin, rc_xmax, rc_ymax
	endif;
enddefine;

define rc_islive_window_object(obj) -> boole;
	lvars win;
	obj and isrc_window_object(obj) and
	(rc_widget(obj) ->> win) and
	xt_islivewindow(win) -> boole;
enddefine;

define rc_save_window_object(win_obj);
	;;; Save the environment for the current widget in the corresponding
	;;; window object if there is one, and if rc_window is alive
	if rc_islive_window_object(win_obj)
	and rc_window_realized(win_obj) then
		if rc_window and rc_window == rc_widget(win_obj)
		then
			;;; save information about current window in the frame vector
			fill(rc_get_current_globals(rc_window), rc_window_frame(win_obj)) ->;
			;;; reset origin;
			rc_window_frame(win_obj) ->;
		endif;
	endif
enddefine;

define :method rc_set_window_globals(win_obj:rc_window_object);
	;;; Set 12 rc_graphic globals when a new window is created
	;;; can be redefined for a subclass to include rc_transxyin
	;;; associated with a window.
	lvars vec = rc_window_frame(win_obj);

	unless datalength(vec) == 12 then
		mishap('12 Values for RC Globals expected', [^vec])
	endunless;

	explode(vec) ->
		(rc_xorigin, rc_yorigin, rc_xscale, rc_yscale,
		;;; turtle variables
		rc_xposition, rc_yposition, rc_heading,
		;;; clipping variables
		rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax);
enddefine;

define vars rc_set_window_defaults(x, y, width, height) /* -> 12 results */;
	;;; User definable procedure for setting rc_window defaults
	;;; for a new window. Must return 12 results

	;;; Default origin in middle, x increasing to right, y going up
	;;; rc_xorigin,  rc_yorigin,   rc_xscale, rc_yscale,
		width div 2, height div 2, 1, -1,

	;;; turtle variables rc_xposition, rc_yposition, rc_heading,
		0, 0, 0,

	;;; clipping variables (turn off clipping)
	;;; rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax);
        false, 		 0, 	  0,	   width,	height

enddefine;

define :generic rc_kill_window_object(w);
enddefine;

define rc_destroy_widget(w);
	;;; this will be associated with the window, to be run if
	;;; killed by mouse
	lvars win_obj = rc_window_object_of(w);
	if win_obj then
		lvars container;
		while rc_window_container(win_obj) ->> container do
			container -> win_obj
		endwhile;
		rc_kill_window_object(win_obj);
		false -> rc_window_object_of(w);
	else
		XtDestroyWidget(w);
	endif;
enddefine;

;;; Next bit copied from LIB RC_GRAPHIC, but with "false" changed to "true"

;;; Adrian Howard, Feb 28 1992 : Added -rc_wm_input- to allow control of the
;;; "input" resource of the shell of XpwGraphic window.
global vars rc_wm_input = true;

;;; panel creation procedure partly copied from XptNewWindow
define XptNewPanel(name, size, args, class) -> (widget, composite, shell);
    ;;; Return a widget of type class in a composite widget in a shell.
    ;;; copied in part from XptNewWindow
	;;; Allow an optional container argument which is a rc_window_object instance

	lvars container = false;

	if isrc_window_object(class) then
		(name, size, args, class) ->
		(name, size, args, class, container)
	endif;

    lvars shellargs = [];

    ;;; look for optional shell args
    if islist(class) then
        ((), name, size, args, class) -> (name, size, args, class, shellargs);
    endif;

    unless XptDefaultDisplay then XptDefaultSetup(); endunless;

	if container then
		rc_window_shell(container) -> shell;

		XtCreateManagedWidget(name,
			xpwCompositeWidget,
			rc_window_composite(container),
	        XptArgList([% {width ^(size(1))}, {height ^(size(2))},
						{x ^(size(3))}, {y ^(size(4))}%] nc_<> args)) -> composite;

	    ;;; insert graphic widget
	    XtCreateManagedWidget(name, class, composite,
	        XptArgList([% {width ^(size(1))}, {height ^(size(2))}%] nc_<> args)) -> widget;

	else
    	[%  if size then {geometry ^(XptGeometrySpec(size))} endif,
        	{title ^name},
        	{iconName ^name},
        	{allowShellResize ^true},
			;;; {input ^(not(not(rc_wm_input))}
    	%] nc_<> shellargs -> shellargs;

		;;; should I use a different classname?
	    XtAppCreateShell(name sys_>< '_shell', XT_POPLOG_CLASSNAME,
	        xtApplicationShellWidget,XptDefaultDisplay,
	        XptArgList(shellargs)
	    ) -> shell;

    	[% if size then  {width ^(size(1))}, {height ^(size(2))} endif,
        	;;; {allowShellResize ^true},
			;;; {input ^(not(not(rc_wm_input)))}
        %] nc_<> args -> args;

    	;;; create composite widget added to the shell.
    	XtCreateManagedWidget(
        	name sys_><'_composite', xpwCompositeWidget, shell, XptArgList(args))
            -> composite;
	
;;; insert graphic widget in the composite
	    XtCreateManagedWidget(name, class, composite, XptArgList(args))
	        -> widget;
		
		XtManageChild(widget);
		XtManageChild(composite)
	endif;


	if container then
	    XtRealizeWidget(composite);
	else
	    XtRealizeWidget(shell);
		rc_destroy_widget -> XptShellDeleteResponse(shell);
	endif;
enddefine;


;;; Window creation procedure adapted from rc_graphic


define xt_new_panel(string, xsize, ysize, xloc, yloc) -> (widget,composite,shell);
    ;;; allow xloc, yloc to be false.

	;;; allow extra container argument
	lvars container = false;
	if isrc_window_object(yloc) then
		(string, xsize, ysize, xloc, yloc) ->
		(string, xsize, ysize, xloc, yloc, container)
	endif;
	
	lconstant arg_vector = initv(4); ;;; re-usable vector for XptNewPanel

	check_string(string);
	fi_check(xsize,0,false) ->;
	fi_check(ysize,0,false) ->;
	fi_check(xloc,false,false) ->;
	fi_check(yloc,false,false) ->;

	XptNewPanel(
		string,
		fill(xsize, ysize, xloc, yloc, arg_vector),
		[],
		xpwGraphicWidget,
		[{input ^(not(not(rc_wm_input)))}],
		if container then container endif) -> (widget, composite, shell);
enddefine;

define xt_new_window(string, xsize, ysize, xloc, yloc) -> widget;
	;;; may have extra argument for container.

	;;; redefined to use xt_new_panel. Could now be withdrawn?
    ;;; allow xloc, yloc to be false.

	;;; Ignore last two results
	xt_new_panel(string, xsize, ysize, xloc, yloc) -> (widget,,);

enddefine;


define :method rc_realize_window_object(win_obj:rc_window_object);
	;;; Start from an unrealized window object and use the contents
	;;; of rc_screen_frame to create it.

	;;; If already realized do nothing.
	returnif(rc_window_realized(win_obj));

	lvars old_obj, old_win, shell, composite, win,
		container = rc_window_container(win_obj);

	if rc_window and (rc_window_object_of(rc_window) ->> old_obj)then
		;;; if there's an active window object save the current settings
		rc_window -> old_win;
		rc_save_window_object(old_obj);
	endif;

	;;; Prevent old window being destroyed
	false -> rc_window;

	;;; get stored coordinates from win_obj
	lvars (x, y, width, height) = rc_screen_coords(win_obj);

	width -> rc_window_xsize;
	height ->rc_window_ysize;
	x -> rc_window_x;
	y -> rc_window_y;

	xt_new_panel('Xgraphic', width, height, x, y, if container then container endif)
		-> (win, composite, shell);

	composite -> rc_window_composite(win_obj);
	shell -> rc_window_shell(win_obj);

	;;; set the 12 global values from the frame vector (set in rc_new_window_object...)
	rc_set_window_globals(win_obj);

	;;; Save the widget
	win -> rc_widget(win_obj);

	;;; See if a title was set, and if so use it for name
	;;; rc_title works on widget just below the shell, alas
	if RC_TITLE(win_obj) then RC_TITLE(win_obj) -> rc_title(composite); endif;

	true -> rc_window_realized(win_obj);
	true -> rc_window_visible(win_obj);

	;;;;rc_window_sync();	;;; no. Can consume mouse events
	syssleep(rc_window_sync_time);

	;;; Adjust location coords if necessary (window manager problems)
	rc_adjust_window_location(win_obj);

	;;; now update stored screen coords
	x + rc_border_allowance, y + rc_title_allowance, false, false
			-> rc_screen_coords(win_obj);

	win_obj ->> rc_window_object_of(win)
			->> rc_window_object_of(shell) -> rc_current_window_object;
	win -> rc_window;
enddefine;

define rc_new_window_object(x, y, width, height, setframe) -> win_obj;
	;;; Optional extra arguments "hidden", or string for title name
	;;; and a "newXXX" procedure for creating windows of class XXX
	;;; Create a new window object. If setframe is false, don't
	;;; create default frame. If it is true, then create default
	;;; frame in middle of window. If it is a four element vector
	;;; then use it to set (rc_xorigin, rc_yorigin, rc_xscale, rc_yscale)
	;;; If it contains 7 elements, then also set
	;;;			(rc_xposition, rc_yposition, rc_heading)
	;;; If "hidden" is provided then don't create the widget yet.
	;;; 	just store information for when it is needed.

	;;; x, and y can be false, in which case a new window offset
	;;; from the last one will be created.

	lvars hidden = false, title = false, create_pdr = newrc_window_object,
		container = false;
	;;; see if extra argument "hidden" or title is supplied

	;;; ensure Glinefunction is set up, also drawing procedures
	;;; for movable objects
	rc_setup_linefunction();

	;;; Find out if 0, 1, 2, or 3, optional extra arguments provided
	repeat 4 times
		if isrc_window_object(setframe) then
			(x, y, width, height, setframe) ->
				(x, y, width, height, setframe, container);
		endif;
		if setframe == "hidden" then
			(x, y, width, height, setframe) ->
			(x, y, width, height, setframe, hidden);
		endif;
		if isstring(setframe) then
			(x, y, width, height, setframe) ->
			(x, y, width, height, setframe, title);
		endif;
		if isprocedure(setframe) then
			(x, y, width, height, setframe) ->
			(x, y, width, height, setframe, create_pdr);
		endif;
	endrepeat;

	unless width >= 0 and height >= 0 then
		mishap(width, height, 2, 'WIDTH AND HEIGHT OF WINDOW MUST BE POSITIVE')
	endunless;

	;;; First see if existing rc_window corresponds to a window object,
	;;; and if so save its state
	if rc_window then
		;;; Save the current window state. Will do nothing if there
		;;; isn't a corresponding window object
		rc_save_window_object(rc_window_object_of(rc_window))
	endif;

	;;; don't create widget yet, only window object
	create_pdr() -> win_obj;

	;;; save title, if given
	if title then title -> RC_TITLE(win_obj) endif;

	;;; store the global variables
	;;; Set internal window coordinates, etc. for rc_window_origin, rc_window_frame
	lvars vec;
	if isvector(setframe) then
		lvars len = datalength(setframe);
		{%
			explode(setframe);
			if len == 4 then
				;;; rc_xorigin, rc_yorigin, rc_xscale, rc_yscale)
				;;; add turtle globals
				0, 0, 0
			elseif len == 7 then
				;;; rc_xorigin, rc_yorigin, rc_xscale, rc_yscale,
				;;; rc_xposition, rc_yposition, rc_heading)
			else
				erasenum(len);
				mishap('VECTOR OF LENGTH 4 or 7 NEEDED', [^setframe])
			endif,
			;;; add five more values for clipping, etc
			;;; rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax
			    false,		 0, 	  0, 	   width, height;
			%}
	else
		{% rc_set_window_defaults(x, y, width, height) %}
	endif ->> vec -> rc_window_frame(win_obj);
	
	{% vec(1), vec(2), vec(3), vec(4) %} -> rc_window_origin(win_obj);

	;;; Make new picture in the container, or else on the screen
	if container then
		unless rc_widget(container) then
			mishap('CONTAINER MUST BE LIVE WINDOW OBJECT', [^container])
		endunless;

	 lblock
		;;; make sure container knows when it is realized
		container -> rc_window_container(win_obj);

		;;; If necessary fix coordinates in container
		lvars
			(xorigin, yorigin, xscale, yscale) = explode(rc_window_origin(container)),
			( , , c_width, c_height) = rc_window_location(container),
			(newxorigin, newyorigin) = rc_window_xyorigin(win_obj);

		if isnumber(x) then
			;;; subtract an extra 1 for the border
			round(xorigin + x*xscale - newxorigin - 1) -> x;
		elseif x == "left" then
			0 -> x;
		elseif x == "right" then
			;;; put the sub-panel on the right
			c_width - width - 2 -> x;
		elseif x == "abut" then
			c_width + 2 -> x;
		elseif x == "middle" then
			c_width div 2 - width div 2-> x;
		endif;

		if isnumber(y) then
			;;; measure from top
			;;; subtract an extra 1 for the border
			round(yorigin + y*yscale - newyorigin - 1) -> y;
		elseif y == "top" then
			0 -> y;
		elseif y == "bottom" then
			c_height - height - 2 -> y
		elseif y == "middle" then
			;;; put the sub-panel in the middle
			c_height div 2 - height div 2-> y;
		elseif y == "abut" then
			c_height + 2 -> y;
		endif;

		;;; Extend container window if necessary (will fix background)
		if (x+width+2 > c_width) or (y+height+2 > c_height) then

			;;; x, y, w, h -> rc_window_location(container);
			false, false,
				if x+width+2 > c_width then x+width+2 else false endif,
				if y+height+2 > c_height then y+height+2 else false endif
					-> rc_window_location(container);
		endif;
	  endlblock	

	else
		;;; Not inside container.

		;;; convert negative or symbolic values of x and y
		lblock
			;;; Find screen dimensions
			;;; This code may not be general enough
			lvars
				s_width = XDisplayWidth(XptDefaultDisplay,0),
				s_height = XDisplayHeight(XptDefaultDisplay,0);

			if isnumber(x) then
				if x < 0 then
					;;; measure from right, subtracting 2 for border
					s_width - width + x - 2 -> x;
					if rc_border_allowance then
						x - rc_border_allowance -> x
					endif;
				endif
			elseif x == "left" then
				0 -> x;
			elseif x == "right" then
				;;; put the sub-panel on the right
				s_width - width - 2 -> x;
					if rc_border_allowance then
						x - rc_border_allowance -> x
					endif;
			elseif x == "middle" then
				s_width div 2 - width div 2 -> x;
			endif;

			if isnumber(y) then
				if y < 0 then
					;;; measure from bottom, subtracting 2 for border
					s_height - height + y - 2 -> y;
					if rc_title_allowance then
						y - rc_title_allowance -> y
					endif;
				endif;
			elseif y == "top" then
				0 -> y;
			elseif y == "bottom" then
				s_height - height - 2 -> y;
					if rc_title_allowance then
						y - rc_title_allowance -> y
					else
						;;; guess at title height
						y - 25 -> y;
					endif;
			elseif y == "middle" then
				;;; put the sub-panel in the middle
				s_height div 2 - height div 2-> y;
			endif;

		endlblock;

		unless x then
			LAST_WINDOW_X + rc_window_x_offset -> x;
		endunless;
		unless y then
			LAST_WINDOW_Y + rc_window_y_offset -> y;
		endunless;

		x -> LAST_WINDOW_X;
		y -> LAST_WINDOW_Y;

	endif;

	x, y, width, height -> rc_screen_coords(win_obj);

	;;; Create new window, hidden or visible.
	if hidden then
		;;; window will be created later
		;;; previously rc_new_*graphic_widget('Xgraphic', width, height, x, y, setframe);
	else
		;;; do it now
		rc_realize_window_object(win_obj);
	endif;

enddefine;

;;; Re-define rc_new_window, using the above
;;; New global variables to aid compatibility with LIB RC_GRAPHIC
;;; Not sure these are needed. Confuses rc_start, rc_new_window
global vars
	rc_default_window_xsize = rc_window_xsize,
	rc_default_window_ysize = rc_window_ysize,
	rc_default_window_x = rc_window_x,
	rc_default_window_y = rc_window_y,
	rc_graphic_window_object = false;

global vars procedure rc_mousepic; 	;;; defined in lib rc_mousepic

;;;; get rid of old version.
cancel rc_new_window;

define vars rc_new_window(width, height, xloc, yloc, setframe);
	;;; modified copy of version in LIB RC_GRAPHIC

	dlvars setframe;

	;;; See if old version needs to be run, e.g. for popvision utilities.
	;;; put args on stack for old version.

	width, height, xloc, yloc, setframe,
		returnif(call_old_rc_proc(oldrc_new_window));

	;;; args not needed so remove them:
	erasenum(5);

	;;; Start a new window (non-object) with the specified attributes.
	;;; If setframe is true, setup turtle location and
	;;; co-ordinate frame etc, otherwise use old values.


	define dlocal rc_set_window_defaults(x, y, width, height) /* -> 12 results */;
		;;; Change locally to be consistent with rc_new_window in rc_graphic
		;;; Must return 12 results

		if setframe then
			width div 2, height div 2, 1, -1,
	
			;;; turtle variables rc_xposition, rc_yposition, rc_heading,
			0, 0, 0,
			;;; clipping variables (turn off clipping)
			;;; rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax);
        	false, 		 0, 	  0,	   width,	height
		else
			rc_xorigin, rc_yorigin, rc_xscale, rc_yscale,
			rc_xposition, rc_yposition, rc_heading,
			rc_clipping, rc_xmin, rc_ymin, rc_xmax, rc_ymax,

		endif;

	enddefine;

	rc_new_window_object(xloc, yloc, width, height, setframe) ->>
	rc_current_window_object -> rc_graphic_window_object;

	rc_mousepic(rc_graphic_window_object);

	;;; save values in case over-ridden
	width ->> rc_window_xsize -> rc_default_window_xsize;
	height ->> rc_window_ysize ->rc_default_window_ysize;
	xloc ->> rc_window_x -> rc_default_window_x;
	yloc ->> rc_window_y -> rc_default_window_y;

	;;; ensure globals are set, as in old version of rc_new_window_object
	rc_widget(rc_graphic_window_object) -> rc_window;

	explode(rc_window_origin(rc_graphic_window_object)) ->
			(rc_xorigin, rc_yorigin, rc_xscale, rc_yscale);

enddefine;


cancel rc_clear_window;

define rc_clear_window();
	;;; Clear current turtle window
	XpwClearWindow(rc_window);
	;;; update information about size, in case altered.
	rc_setsize();
enddefine;

cancel rc_start;

define rc_start();
	;;; Create or clear window, and set turtle at origin
	lvars
		win_obj = rc_window_object_of(rc_window);

	;;; Check whether old version is needed, for compatibility with popvision
	;;; utilities, etc.
	returnif(call_old_rc_proc(oldrc_start));
	
	if xt_islivewindow(rc_window)
	and win_obj and win_obj == rc_current_window_object then
		;;; do nothing -- use current window object. Just clear it
		XpwClearWindow(rc_window);
		rc_setsize();
	elseif xt_islivewindow(rc_window)
	and win_obj == rc_graphic_window_object then
		rc_graphic_window_object -> rc_current_window_object;
		;;; clear the window
		XpwClearWindow(rc_window);
		rc_setsize();
	else
		;;; use the current values of the globals. They may have been
		;;; clobbered by changing rc_current_window_object.
		false -> rc_current_window_object;
		rc_new_window(
			rc_window_xsize,
			rc_window_ysize,
			rc_window_x,
			rc_window_y, true);
		0 ->> rc_xposition ->> rc_yposition -> rc_heading;
	endif;
enddefine;

global vars  procedure rc_clear_events;	;;; defined in rc_mousepic

define: method rc_map_window_object(win_obj:rc_window_object);
	XtMapWidget(rc_window_composite(win_obj));
enddefine;

define: method rc_unmap_window_object(win_obj:rc_window_object);
	lvars composite = rc_window_composite(win_obj);
	if XptCheckWidget(composite) then
		;;; it is a live widget
		XtUnmapWidget(composite)
	endif;
enddefine;

define :method rc_kill_window_object(win_obj:rc_window_object);


	rc_window_sync();

	lvars
		wascurrent = (win_obj == rc_current_window_object),
		win = rc_window_shell(win_obj),
		composite = rc_window_composite(win_obj),
		container = rc_window_container(win_obj),
		win = if container then composite else rc_window_shell(win_obj) endif;

	unless isundef(rc_clear_events) then rc_clear_events(); endunless;

	if container then
		rc_unmap_window_object(win_obj);
	endif;
	
	;;; remove the window
	if xt_islivewindow(win) then
		;;; in case window manager does not get rid of it immediately
		;;; XptDestroyWindow(win)
		;;; XtUnmapWidget(win)
		;;; fast_XtUnmapWidget(win);
		;;; rc_window_sync();
		fast_XtDestroyWidget(win);
	endif;

	;;; remove from property table, and window_object record

	false ->> rc_window_object_of(rc_window_shell(win_obj))
		->> rc_window_object_of(win) ->> rc_widget(win_obj)
		->> rc_window_visible(win_obj) ->> rc_window_composite(win_obj)
		-> rc_window_shell(win_obj);

	if wascurrent then false -> rc_current_window_object endif;
	;;; if XptBusyCursorOn  then false -> XptBusyCursorOn endif;
		
enddefine;	

define rc_destroy();
	;;; Kill current rc_graphic_window_object
	;;; Redefined, replacing default version in Birmingham local library
	if rc_current_window_object == rc_graphic_window_object then
		false -> rc_current_window_object
	endif;
	if rc_graphic_window_object then
		rc_kill_window_object(rc_graphic_window_object);
		false -> rc_graphic_window_object
	endif;
enddefine;


/*
define -- Showing and hiding window objects
*/

define :method rc_show_window(win_obj:rc_window_object);
	;;; This needs to compensate for window manager problems.

	if rc_window_container(win_obj) then
		rc_map_window_object(win_obj);
	else
		lvars (x, y, w, h) = rc_screen_coords(win_obj);

		if rc_window_realized(win_obj) then
			unless rc_window_visible(win_obj) then
				if rc_current_window_object then
					false -> rc_current_window_object;
				endif;
				lvars
					shell = rc_window_shell(win_obj),
					;

				;;; update internal location
				x,y,w,h -> rc_window_location(win_obj);

				;;; rc_window_sync();
				;;; XtMapWidget(shell);
				fast_XtMapWidget(shell);
				;;; XtRealizeWidget(shell);

				rc_window_sync();
				;;; update location. For buggy twm type window managers
				rc_fix_window_location(win_obj);
				rc_window_sync();

				true -> rc_window_visible(win_obj);
			endunless
		else

			rc_realize_window_object(win_obj);

		endif;
	endif;
enddefine;

define :method rc_hide_window(win_obj:rc_window_object);

	lvars
		oldwinobj = rc_current_window_object,
		wascurrent = (win_obj == oldwinobj);

	if rc_window_container(win_obj) then
		rc_unmap_window_object(win_obj);
	else
		;;; save location in case it has changed
		rc_window_location(win_obj) -> rc_screen_coords(win_obj);

		;;; XtUnrealizeWidget(XptShellOfObject(rc_widget(win_obj)));
		;;; XtUnmapWidget(XptShellOfObject(rc_widget(win_obj)));
		fast_XtUnmapWidget(rc_window_shell(win_obj));
		false -> rc_window_visible(win_obj);
		rc_window_sync();
	endif;

	false -> rc_current_window_object;
	if oldwinobj and not(wascurrent) then oldwinobj -> rc_current_window_object endif;

enddefine;

define :method rc_raise_window(win_obj:rc_window_object);
	;;; should use ???? XRaiseWindow(XptDefaultDisplay, rc_widget(win_obj))
	if rc_window_visible(win_obj) then
		rc_hide_window(win_obj);
		rc_window_sync();
	endif;
	rc_show_window(win_obj);
	;;; adjust location
	rc_screen_coords(win_obj) -> rc_window_location(win_obj);
enddefine;


global vars rc_in_event_handler = false;	;;; defined in rc_mousepic

define lconstant rc_restore_window_object(win_obj);
	;;; Make the old widget the current rc_window, and reset the frame
	;;; environment
	lvars container = rc_window_container(win_obj);
	if container and not(rc_widget(container)) then
		;;; container is dead, don't try to restore.
		return();
	endif;

	if rc_islive_window_object(win_obj) then
		rc_widget(win_obj) -> rc_window;
		;;; set RC coordinate frame, etc.
		rc_set_window_globals(win_obj);

		;;; Check if window has been adjusted by user
		rc_window_location(win_obj)
			-> (rc_window_x, rc_window_y, rc_window_xsize, rc_window_ysize);
	else
		unless rc_in_event_handler then
			;;; Can be invoked in event handler. Don't raise error then
			mishap('CANNOT RESTORE DEAD WINDOW OBJECT', [^win_obj])
		endunless;
	endif;
enddefine;


lvars current_win_obj = false;

define active rc_current_window_object /* -> win_obj */;
	current_win_obj  /* -> win_obj */;
enddefine;

define updaterof active rc_current_window_object(win_obj);
	;;; Use win_obj to set the current environment.
	;;; First save the old environment
	if current_win_obj then
		rc_save_window_object(current_win_obj);
	endif;
	if win_obj then
		;;; Then set the new one if possible
		rc_restore_window_object(win_obj);
		if win_obj == rc_window_object_of(rc_window) then
			;;; restored successfully, so
			win_obj -> current_win_obj
		endif;
	else
		false ->> rc_window -> current_win_obj;
	endif;
enddefine;



/*
define -- simulate some rc_linepic methods
*/

define :method rc_graphic_frame(w:rc_window_object) -> (x, y, xscale, yscale);
	dlocal rc_current_window_object = w;
	rc_xorigin, rc_yorigin, rc_xscale, rc_yscale -> (x, y, xscale, yscale);
enddefine;

define :method rc_transxyout_in(w:rc_window_object, x, y) -> (x, y);
	dlocal rc_current_window_object = w;
		rc_transxyout(x,y) -> (x,y);
enddefine;

define :generic rc_mousexyin(w, x, y) -> (x, y);
	;;; defined properly in lib rc_mousepic
enddefine;

define :method rc_transxyin_in(w:rc_window_object, x, y) -> (x, y);
	dlocal rc_current_window_object = w;
		rc_mousexyin(w, x,y) -> (x,y)
enddefine;

define :method rc_container_xy(w:rc_window_object, x, y) -> (x, y);
	;;; given coordinates x, y in w, find the corresponding coordinate
	;;; in the frame of the container
	rc_transxyout_in(w, x, y) -> (x, y);

	lvars
		container = rc_window_container(w),
		(xorigin, yorigin, , ) = rc_window_location(w);

	;;; add 1 for the border width.
	x + 1.0 -> x; y + 1.0 -> y;
	if container then
		rc_transxyin_in(container, x+xorigin, y+yorigin) -> (x,y);
	else
		xorigin + x -> x; yorigin + y -> y;		
	endif;
enddefine;

define :method rc_move_to(w:rc_window_object, x, y, visible);
	unless visible then
		;;; If visible is false, hide and move.
		rc_hide_window(w);
	endunless;

	lvars container = rc_window_container(w);

	if container then
		rc_transxyout_in(container, x, y) -> (x, y);

		lvars (xorigin, yorigin) = rc_window_xyorigin(w);

		;;; subtract 1 from each to allow for border
		x-xorigin-1, y-yorigin-1, false, false
	else
		x,y, false, false
	endif
		-> rc_window_location(w);
enddefine;

define :method vars rc_coords(w:rc_window_object) -> (x, y);
	;;; If there is a container, then return x and y coordinates of the
	;;; xyorigin of w in its container, otherwise location of top left corner
	lvars container = rc_window_container(w);

	if container then
		rc_container_xy(w, 0, 0) -> (x, y);
	else
		rc_window_location(w) -> (x, y, , );
	endif;
enddefine;

define :method updaterof rc_coords(/*x, y,*/ w:rc_window_object);
	;;; move object to specified location
	lvars x, y;
	-> (x, y);
	rc_move_to(w, x, y, true);
enddefine;

define :method rc_move_by(w:rc_window_object, dx, dy, visible);
	lvars (oldx,oldy) = rc_coords(w);

	rc_move_to(w, oldx + dx, oldy + dy, visible)
enddefine;


define :method vars rc_picx(w:rc_window_object) -> x;
	rc_coords(w) -> (x, );
enddefine;

define :method updaterof rc_picx(x, w:rc_window_object);
	(x, rc_picy(w)) -> rc_coords(w);
enddefine;

define :method vars rc_picy(w:rc_window_object) -> y;
	rc_coords(w) -> ( ,y);
enddefine;

define :method updaterof rc_picy(y, w:rc_window_object);
	(rc_picx(w), y) -> rc_coords(w);
enddefine;

/*
define -- Re-drawing and clearing a window

(Can't go in lib rc_window_object because it uses stuff from here)

*/

global vars
	;;; This is set to the window being redrawn.
	rc_redrawing_window = false,
	rc_clear_before_redraw = true;

define :method rc_redraw_window_object(win_obj:rc_window_object);
	;;; Clear the window and redraw all the picture objects it knows about.
	;;; Optional boolean argument removed.[27 Jul 2002]

	win_obj -> rc_current_window_object;

	;;; this is needed because iscaller does not work with methods
	dlocal rc_redrawing_window = win_obj;

	;;; get window contents in reverse order so that things at top of
	;;; list get drawn last, and therefore are most likely to be visible.
	lvars item,
		list = rev(rc_window_contents(win_obj));
	
	;;; undraw movable objects so that they are redrawn in the right
	;;; state
	for item in list do
		if isrc_linepic_movable(item) then rc_undraw_linepic(item) endif;
	endfor;

	if rc_clear_before_redraw then
		XpwClearWindow(rc_widget(win_obj));
	endif;

	for item in list do rc_draw_linepic(item) endfor;

	;;; it's a temporary list, so return to heap
	sys_grbg_list(list);

enddefine;

define :method rc_clear_window_object(win_obj:rc_window_object);
	win_obj -> rc_current_window_object;
	XpwClearWindow(rc_widget(win_obj));
enddefine;	

	
;;; for "uses"
global vars rc_window_object = true;
endexload_batch;
endsection;

nil -> proglist;
/*
CONTENTS Use ENTER g define, or ENTER gg

 define -- Tests
 define -- Libraries required and global vars
 define lconstant call_old_rc_proc(oldproc) -> called;
 define rc_window_sync();
 define -- Global property mapping widgets to objects
 define vars procedure rc_window_object_of =
 define -- The main mixin rc_selectable, and its sub-classes
 define :mixin vars rc_selectable;
 define :mixin vars rc_keysensitive;
 define :method vars rc_keypress_handler(pic:rc_linepic);
 define :mixin vars rc_resizeable;
 define :method vars rc_resize_handler(pic:rc_linepic);
 define -- Main class definition
 define :class vars rc_window_object;
 define -- Methods for manipulating rc_window_objects
 define :method rc_window_frame(win_obj:rc_window_object) -> vec;
 define :method updaterof rc_window_frame(win_obj:rc_window_object);
 define :method rc_window_title(win_obj:rc_window_object) -> string;
 define :method updaterof rc_window_title(win_obj:rc_window_object);
 define :method rc_screen_coords(win_obj:rc_window_object) /* -> (x, y, w, h) */;
 define :method updaterof rc_screen_coords(x, y, w, h, win_obj:rc_window_object);
 define rc_adjust_window_location(win_obj);
 define :method rc_window_xyorigin(win_obj:rc_window_object) -> (x, y);
 define :method rc_window_location(win_obj:rc_window_object) -> (x, y, w, h);
 define :method updaterof rc_window_location(x, y, w, h, win_obj:rc_window_object);
 define rc_fix_window_location(win_obj);
 define :method print_instance(win_obj:rc_window_object);
 define -- Creating and destroying window objects
 define rc_get_current_globals(window);
 define rc_islive_window_object(obj) -> boole;
 define rc_save_window_object(win_obj);
 define :method rc_set_window_globals(win_obj:rc_window_object);
 define vars rc_set_window_defaults(x, y, width, height) /* -> 12 results */;
 define :generic rc_kill_window_object(w);
 define rc_destroy_widget(w);
 define XptNewPanel(name, size, args, class) -> (widget, composite, shell);
 define xt_new_panel(string, xsize, ysize, xloc, yloc) -> (widget,composite,shell);
 define xt_new_window(string, xsize, ysize, xloc, yloc) -> widget;
 define :method rc_realize_window_object(win_obj:rc_window_object);
 define rc_new_window_object(x, y, width, height, setframe) -> win_obj;
 define vars rc_new_window(width, height, xloc, yloc, setframe);
 define rc_clear_window();
 define rc_start();
 define: method rc_map_window_object(win_obj:rc_window_object);
 define: method rc_unmap_window_object(win_obj:rc_window_object);
 define :method rc_kill_window_object(win_obj:rc_window_object);
 define rc_destroy();
 define -- Showing and hiding window objects
 define :method rc_show_window(win_obj:rc_window_object);
 define :method rc_hide_window(win_obj:rc_window_object);
 define :method rc_raise_window(win_obj:rc_window_object);
 define lconstant rc_restore_window_object(win_obj);
 define active rc_current_window_object /* -> win_obj */;
 define updaterof active rc_current_window_object(win_obj);
 define -- simulate some rc_linepic methods
 define :method rc_graphic_frame(w:rc_window_object) -> (x, y, xscale, yscale);
 define :method rc_transxyout_in(w:rc_window_object, x, y) -> (x, y);
 define :generic rc_mousexyin(w, x, y) -> (x, y);
 define :method rc_transxyin_in(w:rc_window_object, x, y) -> (x, y);
 define :method rc_container_xy(w:rc_window_object, x, y) -> (x, y);
 define :method rc_move_to(w:rc_window_object, x, y, visible);
 define :method vars rc_coords(w:rc_window_object) -> (x, y);
 define :method updaterof rc_coords(/*x, y,*/ w:rc_window_object);
 define :method rc_move_by(w:rc_window_object, dx, dy, visible);
 define :method vars rc_picx(w:rc_window_object) -> x;
 define :method updaterof rc_picx(x, w:rc_window_object);
 define :method vars rc_picy(w:rc_window_object) -> y;
 define :method updaterof rc_picy(y, w:rc_window_object);
 define -- Re-drawing and clearing a window
 define :method rc_redraw_window_object(win_obj:rc_window_object);
 define :method rc_clear_window_object(win_obj:rc_window_object);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Sep  8 2002
		Made sure window objects do not share screen_frame
		Made rc_hide_window make rc_currrent_window_object false if
		the hidden window was the current one.
--- Aaron Sloman, Sep  5 2002
		added rc_window_sync() to rc_kill_window_object
--- Aaron Sloman, Jul 29 2002
		Added a check for composite in rc_window_location (needed for Steve Allen's
		Abbot program to work)
--- Aaron Sloman, Jul 29 2002
		Minor fix in rc_redraw_window_object
--- Aaron Sloman, Jul 28 2002
		Changed some mixin and class definitions to vars
		Added uses xt_composite
--- Aaron Sloman, Jul 27 2002
	Made rc_adjust_window_location(win_obj) accessible to users

	Made rc_window_location not resize unless rc_resize_handler set.
		
	Changes to rc_redraw_window_object(win_obj)
		Altered to draw objects in the reverse order of
			rc_window_contents(win);
		so that most recently added or moved item is drawn last, to be 'on top'.
		Removed optional boolean argument for rc_redraw_window_object.
		(Not compatible with status as method.) Instead added global variable
			rc_clear_before_redraw  : default true

--- 25 Jul 2002 Resize event handling added
	define :mixin rc_resizeable;
		slot rc_resize_handler ="rc_resize_object";
 	define :method rc_resize_handler(pic:rc_linepic);

	Also altered rc_window_location so that when invoked it updates size of graphic
	object if the window object has been resized using mouse or a resize program
	command, provided that rc_resize_handler(win) is non-false.
	Event handlers are defined in LIB rc_mousepic
	
	rc_resize_threshold is an integer, controlling the minimum size change
	before the window resize event handler is triggered.

--- Aaron Sloman, Dec  5 2000 rc_destroy_widget(w) altered.
	Bug reported by Matthieu Schutz: if a panel is inserted in another
	panel, then attempting to kill the window using the window
	manager "close" function kills only the sub-panel. Another
	close kills the whole thing. Fixed by killing the outermost
	container.
--- Aaron Sloman, Oct  8 2000
	If y value for new window is "bottom" and rc_title_allowance not yet known
	then guess a value, in rc_new_window_object

--- Aaron Sloman, Oct  3 2000
	Introduced rc_destroy_widget and used it with XptShellDeleteResponse;

--- Aaron Sloman, Sep 15 2000

	Made sure that rc_keysensitive objects have a
		rc_mouse_limit slot.

--- Aaron Sloman, Sep 14 2000
	Introduced slot rc_drag_only, Changed rc_mousepic
--- Aaron Sloman, Feb 29 2000
	Fixed (final?) bug in rc_new_window: made sure it set globals
	at the end. use_rc_graphic_versions may no longer be needed. Changed
	its default to [].
--- Aaron Sloman, Feb 27 2000
	Made more consistent with old rc_start, rc_new_window
--- Aaron Sloman, Feb 26 2000
	Extended with facilities to decide whether to invoke old versions of
		rc_start, rc_new_window
	based on the list
--- Aaron Sloman, Feb 19 2000
	Changed to use rc_drawline_absolute with "background" argument when
		extending width or height of a window.
--- Aaron Sloman, Dec 26 1999
	Altered to make rc_wm_input default to true, not false
--- Aaron Sloman, Oct 10 1999
	Stopped rc_hide_window object from always making rc_current_window_object false.
	added rc_islive_window_object(obj)
--- Aaron Sloman, Oct  9 1999
	added rc_start, rc_new_window, rc_destroy, etc. redefining the
	procedures in LIB RC_GRAPHIC as required to produce consistency
	with rc_graphic teach files
--- Aaron Sloman, Aug 10 1999
	Prevented an error condition in the updater of rc_current_window_object:
	don't restore window whose container is dead.
--- Aaron Sloman, Aug  9 1999
	Changed rc_new_window_object to accept negative x or y coordinates,
	for non-embedded windows, to refer to right hand side or bottom of screen.

	Also allowed "top", "bottom", "left", "right", "middle" as screen coordinates
	These two are no longer lconstant
		rc_get_current_globals(window);
		rc_save_window_object(win_obj);

--- Aaron Sloman, Jul  5 1999
	As advised by Anthony Worrall, inserted the following in XptNewPanel
        XtDestroyWidget -> XptShellDeleteResponse(shell);
--- Aaron Sloman, Jun  3 1999
	Fixed rc_coords, and related methods.
--- Aaron Sloman, May 29 1999
	Include stuff for extending windows to accommodate sub-windows, if necessary.
	Changed rc_realize_window_object to ensure rc_window_object_of
		is not set wrongly
--- Aaron Sloman, May 25 1999
	Added rc_container_xy
	Added more procedures to simulate rc_linepic
	rc_picx
	rc_picy
	rc_coords
	adjusted rc_new_window_object to allow for border width in contained
		windows.

--- Aaron Sloman, May 23 1999
	Allowed sub-windows to have symbolic as well as numeric values for x, y.
	Added several new methods and procedures
		rc_graphic_frame rc_transxyout_in rc_transxyin_in
	This enabled rc_move_to and rc_move_by and dragging to work in a
	sub_panel.

--- Aaron Sloman, May 20 1999
	Altered rc_window_location and its updater to take account of windows contained
	in other windows
--- Aaron Sloman, May 19 1999
	Allowed a window to be a container of another.
	Changed rc_kill_window_object to cope with a window contained by another.
	(allowed optional extra argument)
--- Aaron Sloman, May 15 1999
	Extended rc_kill_window_object to remove shell and composite widget,
	to minimise store occupancy.
--- Aaron Sloman, May  8 1999
	Changed rc_kill_window_object to work a bit faster, after
	doing  rc_clear*_events

--- Aaron Sloman, Apr 29 1999
	Made rc_title work again
--- Aaron Sloman, Apr 26 1999
	Fixed bug in width/height of panel creation procedure.
	Added XptNewPanel and xt_new_panel.
	Made window objects contain shell+composite widget+
	graphic widget.

--- Aaron Sloman, Sep  7 1997
	added rc_move_to and rc_move_by methods.

--- Aaron Sloman, Aug 19 1997
	Stopped allowing basic window variables to be changed by context
	switches. Introduced rc_window_origin
--- Aaron Sloman, Aug  3 1997
	Changed rc_hide_window so that it no longer assigns to
		rc_current_window_object
	Altered rc_kill_window_object so that where appropriate it makes
		rc_current_window_object false.
--- Aaron Sloman, Jun 28 1997
	made window objects have default mouse limit of 0. Vector not needed.
--- Aaron Sloman, Jun 26 1997
	Found it necessary to pre-compile objectclass create_instance in
	Poplog V15.5
--- Aaron Sloman, Jun 16 1997
	Altered rc_window_location so that if a window is enlarged the new area
	takes on the current background colour (it sometimes came out black).
--- Aaron Sloman, Jun 15 1997
	allowed rc_redraw_window_object to take an extra boolean to indicate
	whether to clear the window before redrawing.
--- Aaron Sloman, Jun 14 1997
	Added rc_redrawing_window

--- Aaron Sloman, Jun 10 1997
	Added slot rc_event_types, to win_obj

	At suggestion of Brian Logan, introduced
		rc_window_x_offset , rc_window_y_offset

	Added
		rclib/auto/rc_transfer_window_contents.p

--- Aaron Sloman, 19 Apr 1997
	new slots to go with new methods in rc_mousepic.p
		slot rc_entry_handler ="rc_mouse_enter";
		slot rc_exit_handler ="rc_mouse_exit";

--- Aaron Sloman, Apr 16 1997
	 introduced new method rc_keypress_handler(pic:rc_linepic),returning false
	 by default.

--- Aaron Sloman, Apr 14 1997
	Made rc_kill_window_object first unmap the widget, to deal with "slow"
	window managers (like ctwm).
--- Aaron Sloman, Apr 12 1997
	rc_new_window_object extended to allow optional newXXX argument
	Turned rc_realize_window_object into a method, so that subclasses can
	take extra action. See LIB * RC_BUTTONS
--- Aaron Sloman, Apr  3 1997
	Cleaned up and reorganised so that with "hidden" as argument,
	rc_new_window_object just creates the Pop-11 object but doesn't
	create the widget until it is first shown. Seems to overcome some
	problems. There are still difficulties with twm, tvtwm, ctwm, not
	getting screen coordinates right.	

	Added rc_window_sync()  and rc_window_sync_time = 15;

--- Aaron Sloman, Mar 29 1997
	Replaced rc*setsize with use of rc_window_location
--- Aaron Sloman, Mar 28 1997
	Removed rc_kill*_current_window_object, also simplified and
	streamlined by getting rid of rc_live_window class
--- Aaron Sloman, Mar 24 1997
	Made rc_new_window_object invoke
		rc_setup_linefunction();
--- Aaron Sloman, Mar 17 1997
	Allowed extra string as optional title name for rc_new_window_object
--- Aaron Sloman, Jan 30 1997
	Introduced "hidden" option in 2rc_new_window_object
--- Aaron Sloman, Jan  6 1997
	Changed to store clipping information also. Fixed obscure bug.
	Made rc_clipping false by default in all new windows. (X windows
	clip anyway).
	Reduced time delay when first changing location.
	Added slight delay before correcting location when creating
		new window_object
	Introduced rc_g*et_current_frame(window);
	Made rc_new_window_object adjust location
--- Aaron Sloman, Jan  6 1997
	Tidied various things and made default print routine include
	window title
 */
