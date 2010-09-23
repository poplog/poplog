/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_message_wait.p
 > Purpose:			Display a message
 > Author:          Aaron Sloman, 14 May 1997 (see revisions)
 > Documentation:	HELP RC_BUTTONS
 > Related Files:   LIB * RC_POSTER, RC_MESSAGE, RClib
 */
/*
rc_current_window_object =>
rc_xorigin, rc_yorigin =>

vars strings=
	['Now is the time''for all good men and women''to stand up'
	 'and be counted'];

;;;(x,y, strings, spacing, centre, font, bgcol, fgcol);
rc_message_wait(300,300,strings,0, true, '9x15', false, false);
rc_message_wait(300,100,strings,0, true, '8x13bold', false, false);
rc_message_wait(100,20,strings,0, true, '10x20', 'darkslategrey', 'yellow');
rc_message_wait(400,300,strings,0, true, 'lucidasans-20', 'yellow', 'blue');
rc_message_wait(600,100,['Hi there'],0, true, 'lucidasans-20', 'yellow', 'blue');
rc_message_wait(500,100,['Hi there'],0, true, 'lucidasans-20', 'black', 'white');

*/

compile_mode :pop11 +strict;

uses rclib;
uses rc_window_object;
uses rc_mousepic;
uses rc_warp_to;

;;; In case rc_buttons has not yet been compiled
global vars rc_in_button_handler;

if isundef(rc_in_button_handler) then
	false -> rc_in_button_handler
endif;

section;

global vars
	rc_message_wait_instruct = '[CLICK TO DISMISS]',
	;

lvars
	message_read = false,
	was_in_event_handler = false;

define lconstant destroy_message(win_obj, x, y, modifier);
	;;; Button 1 down handler for the window
	;;; ignore last three arguments.

	rc_kill_window_object(win_obj);
	false ->> rc_sole_active_widget -> rc_window;
	true -> message_read;
	if was_in_event_handler then
		;;; This seems to be required to get the system back to
		;;; a proper state. Dunno why. Without it rc_polypanel gets
		;;; into trouble.
		interrupt();
	endif;
enddefine;

define lconstant keydestroy_message(win_obj, x, y, modifiers, key);
	;;; Keypress down handler for the window
	;;; If key is going down, not up, key > 0. Dismiss window.
	if key > 0 then
		destroy_message(win_obj, x, y, modifiers);
	endif;
enddefine;

define rc_message_wait(x,y, strings, spacing, centre, font, bgcol, fgcol);

	dlocal
		message_read = false,

		;;; need to tell whether invoked asynchronously
		was_in_event_handler = rc_in_button_handler;

	;;; [was_in_handler ^was_in_event_handler] =>

	[^(if rc_message_wait_instruct then rc_message_wait_instruct, '' endif)
		^^strings] -> strings;

	lvars
		oldwinobj = rc_current_window_object,
		message_window;

	;;; create the message window
	rc_poster(x,y, strings, spacing, centre, font, bgcol, fgcol)
				-> message_window;

	rc_mousepic(message_window, [keyboard button]);

	;;; Set up event handlers for this window

	;;; key press handler
	keydestroy_message -> rc_keypress_handler(message_window);

	;;; Mouse button handler
	{ ^destroy_message  ^false ^false}
			-> rc_button_down_handlers(message_window);

	{ ^false ^false ^false} -> rc_button_up_handlers(message_window);

	rc_warp_to(message_window, false, false);
	rc_window_sync();

	lvars oldinterrupt = interrupt;

	define destroy_it();
		destroy_message(message_window, 0,0,'');

		if oldwinobj then oldwinobj else false endif -> rc_current_window_object;
		rc_window_sync();
	enddefine;

	define dlocal interrupt();
		dlocal interrupt = oldinterrupt;
		destroy_message(message_window, 0,0,'');
	enddefine;

	dlocal
		;;; disable other widgets
		rc_sole_active_widget = rc_widget(message_window),
		;;; Make sure all events are handled immediately
		rc_external_defer_apply = apply;
	repeat
		syshibernate();
		quitif(message_read)
	endrepeat;

	external_defer_apply(destroy_it);
enddefine;


endsection;
/*

CONTENTS

 define lconstant destroy_message(win_obj, x, y, modifier);
 define lconstant keydestroy_message(win_obj, x, y, modifiers, key);
 define rc_message_wait(x,y, strings, spacing, centre, font, bgcol, fgcol);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 18 2000
	Altered to accept key press instead of mouse button to dismiss

--- Aaron Sloman, Dec  9 1998
	Added global declaration of rc_in_button_handler

--- Aaron Sloman, Feb  3 1998
	Introduced was_in_event_handler. With the aid of this variable
	made the call of interrupt in the event handler depend on whether
	this is invoked asynchronously or not. There should be a better

	way.
--- Aaron Sloman, Nov 12 1997
	Added interrupt to the event handler. Seems to be needed.

--- Aaron Sloman, Aug 28 1997
	Fixed to handle events, even if already inside event handler.
	Also changed so that rc_message_wait_instruct can be set false.

	uses rc_sole_active_widget

--- Aaron Sloman, May 20 1997
	Reimplemented in terms of rc_poster
 */
