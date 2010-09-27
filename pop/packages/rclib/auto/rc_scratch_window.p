/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_scratch_window.p
 > Purpose:			Provide a window which can be interrogated to find
				    font characteristics, etc.
 > Author:          Aaron Sloman and Brian Logan, 24 Jun 1997 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
;;; TESTING
rc_scratch_window=>
rc_scratch_window.rc_widget=>
rc_current_window_object=>

rc_scratch_window -> rc_current_window_object;
rc_drawline(0,0,15,25);
rc_draw_blob(50,50,10,'red');

;;; useful repeatable command
rc_draw_blob(150-random(300),200-random(400),10+random(30),
	oneof(['red' 'orange' 'blue' 'pink']));

450,10,false, false -> rc_window_location(rc_scratch_window);
rc_show_window(rc_scratch_window);
rc_hide_window(rc_scratch_window);
rc_kill_window_object(rc_current_window_object);

false -> rc_scratch_window;
undef -> rc_scratch_window;
;;; then recompile this

uses rc_scratchpad
RCSCRATCH rc_drawline(0,-100,-100,-100);

rc_tearoff();
rc_scratch_window -> rc_current_window_object;
rc_draw_blob(150-random(300),200-random(400),10+random(30),'red');

RCSCRATCH rc_drawline(0,100,-100,-random(100));

rc_tearoff();

rc_scratchpad('rc_drawline(100,100,-100,-100)');
rc_scratchpad('rc_drawline(100,-100,-100,-100)');

rc_kill_tearoffs();
RCSCRATCH rc_draw_blob(150-random(300),200-random(400),10+random(30),'red');

false -> rc_scratch_window;

RCSCRATCH rc_drawline(0,100,100,-100);
*/


section;

uses rclib
uses rc_window_object
uses rc_window_sync
uses rc_mousepic

global vars
	rc_scratch_x = 520,
	rc_scratch_y = 300,
	rc_scratch_width = 500,
	rc_scratch_height = 500,
	rc_scratch_frame = true;


define :class rc_scratch_window; is rc_window_object;
	;;; windows that can include buttons
enddefine;

;;; Globals inaccessible to users
lvars

	default_window = false,

	;;; used to generate titles
	scratch_counter = 0,

	;;; List of previous scratchpad windows
	scratchpad_tearoffs = [],
;



define active rc_scratch_window() -> win_obj;
	if default_window and xt_islivewindow(rc_widget(default_window)) then
		default_window -> win_obj
	else
		false -> default_window;
		procedure();
			;;; this stuff is nested to stop dlocal being invoked later
			dlocal rc_current_window_object, rc_window;
			;;; create invisible window object;
			scratch_counter + 1 -> scratch_counter;
			rc_new_window_object(
				rc_scratch_x, rc_scratch_y,
					rc_scratch_width, rc_scratch_height, rc_scratch_frame,
					  newrc_scratch_window,
						'Scratch'sys_>< scratch_counter) -> win_obj;
			rc_mousepic(win_obj);
			rc_window_sync();
			win_obj -> default_window;
		endprocedure();
	endif;
enddefine;

define updaterof active rc_scratch_window(item);
	lvars win_obj;
	if item == undef then
		if default_window then
			;;; save current scratchpad window
    		rc_scratch_window :: scratchpad_tearoffs -> scratchpad_tearoffs;
			;;; Now forget this window,
			if default_window == rc_current_window_object then
				false -> rc_current_window_object;
			endif;
			;;; but don't delete it
			;;; and make sure next one is offset
			rc_window_location(default_window) ->
			(rc_scratch_x, rc_scratch_y,
				rc_scratch_width, rc_scratch_height);
			
			rc_scratch_x + rc_window_x_offset -> rc_scratch_x;
			rc_scratch_y + rc_window_y_offset -> rc_scratch_y;
			false ->  default_window;
			return();
		endif;
	elseif item then
		mishap('ONLY UNDEF or FALSE CAN BE ASSIGNED TO rc_scratch_window', [^item])
	endif;

	if default_window then
		;;; this conditional should now be redundant
		if default_window == rc_current_window_object then
			false -> rc_current_window_object
		endif;
		rc_kill_window_object(default_window);
		false -> default_window;
	endif;
enddefine;


;;; Save the current contents of rc_window and make a new one.
define rc_tearoff();

	;;; forget but don't destroy the current scratchpad. Add it to
	;;; the tearoffs
    undef  -> rc_scratch_window;
	
	;;; get new scratch window
	rc_scratch_window ->;
enddefine;

;;; Kill the scratchpad tearoff windows.
define rc_kill_tearoffs();

	;;; If one of them is the current window object, make sure it
	;;; isn't any more
	if lmember(rc_current_window_object, scratchpad_tearoffs) then
		false -> rc_current_window_object
	endif;

    applist(scratchpad_tearoffs, rc_kill_window_object);
    [] -> scratchpad_tearoffs;
enddefine;

define lconstant switch_scratchpad();
	lvars win_obj = rc_active_window_object;

	;;; First make the window the current one
	win_obj -> rc_current_window_object;

	;;; If it is not already the current scratchpad, swap it with the
	;;; current scratchpad

	if win_obj /== default_window
	and lmember(win_obj, scratchpad_tearoffs)
	then
		;;; swap this window with the current scratch pad
		if default_window and xt_islivewindow(rc_widget(default_window)) then
			;;; put the old scratch pad in the tearoffs list
			unless lmember(default_window, scratchpad_tearoffs) then
    			default_window :: scratchpad_tearoffs -> scratchpad_tearoffs;
			endunless;
			;;; make the current window the scratchpad
			delete(win_obj,scratchpad_tearoffs, nonop ==) -> scratchpad_tearoffs;
		endif;
	endif;	
	win_obj -> default_window;
enddefine;

define :method rc_button_1_down(pic:rc_scratch_window, x, y, modifiers);
	;;; Clicking with CTRL makes this the current window object and
	;;; the current scratchpad

	if modifiers = 'c' then
		;;; CTRL and mouse buton 1, so make this the current window object
		rc_defer_apply( switch_scratchpad );
	else
		call_next_method(pic, x, y, modifiers)
	endif;
enddefine;

endsection;
/*
         CONTENTS

 define :class rc_scratch_window; is rc_window_object;
 define active rc_scratch_window() -> win_obj;
 define updaterof active rc_scratch_window(item);
 define rc_tearoff();
 define rc_kill_tearoffs();
 define lconstant switch_scratchpad();
 define :method rc_button_1_down(pic:rc_scratch_window, x, y, modifiers);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug  3 1997
	Removed mindor redundancies
--- Aaron Sloman, Jul 18 1997
	Ensured that rc_kill_tearoffs makes sure none of them is the
	current window object. Makes undef -> rc_scratch_window
	put the old window in the tearoffs list.

--- Aaron Sloman, Jul 16 1997
	Introduce new rc_scratch_window class
	Move tearoff stuff in here

--- Aaron Sloman, Jul 11 1997
	Allowed undef to be assigned to rc_scratch_window, to "forget"
		the current window.
	Made new scratchpads be offset from olds, and sensitive to old
	one's size and location.
	Made scratchpad windows mouse sensitive
 */
