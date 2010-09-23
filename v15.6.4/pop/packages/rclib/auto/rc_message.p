/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_message.p
 > Purpose:			Display a message
 > Author:          Aaron Sloman, Apr 13 1997 (see revisions)
 > Documentation:	HELP RC_BUTTONS
 > Related Files:	LIB * RC_POSTER, RC_MESSAGE_WAIT,
 */
/*

vars strings=
	['Now is the time''for all good men and women''to stand up'
	 'and be counted'];

;;;(x,y, strings, spacing, centre, font, bgcol, fgcol) ->win_obj;
rc_message(300,300,strings,0, true, '9x15', false, false)->;
rc_message(300,200,strings,0, true, '8x13bold', false, false)->;
rc_message(300,200,strings,0, true, '10x20', 'darkslategrey', 'yellow')->;
rc_message(300,300,strings,0, true, 'lucidasans-20', 'yellow', 'blue')->;
rc_message(600,100,['Hi there'],0, true, 'lucidasans-20', 'yellow', 'blue')->;
rc_message(500,100,['Hi there'],0, true, 'lucidasans-20', 'black', 'white')->;

*/

compile_mode :pop11 +strict;

uses rclib;
uses rc_window_object;
uses rc_mousepic;

section;

global vars
	rc_message_instruct = '[CLICK TO DISMISS]',
	;

define lconstant destroy_message(win_obj, x, y, modifier);
	;;; Button 1 down handler for the window
	;;; ignore last three arguments.

	;;; Remember last window active before this one
	lvars
		prev_active = rc_active_window_object;

	define kill_it();

		lvars old1 = rc_current_window_object;
	
		rc_kill_window_object(win_obj);

		;;; forget window globals
		false -> rc_window;
		false -> rc_current_window_object;

		if prev_active and rc_widget(prev_active) then
			;;; reinstate previous one, if still alive.
			prev_active -> rc_current_window_object
		elseif old1 and rc_widget(old1) then
			old1 -> rc_current_window_object
		endif;
	enddefine;

	external_defer_apply(kill_it);

enddefine;

define lconstant keydestroy_message(win_obj, x, y, modifiers, key);
	;;; keyboard down handler for the window
	;;; If keypress, then key is > 0.
	if key > 0 then
		destroy_message(win_obj, x, y, modifiers);
	endif;
enddefine;

define rc_message(x,y, strings, spacing, centre, font, bgcol, fgcol) -> message_window;

	lvars oldwinobj = rc_current_window_object;

	[^(if rc_message_instruct then rc_message_instruct, '' endif)
		^^strings] -> strings;

	rc_poster(x,y, strings, spacing, centre, font, bgcol, fgcol)
			-> message_window;

	rc_mousepic(message_window, [keyboard button]);
	rc_window_sync();

	;;; Mouse button handlers
	{ ^destroy_message  ^false ^false} -> rc_button_down_handlers(message_window);
	{ ^false ^false ^false} -> rc_button_up_handlers(message_window);

	;;; Keypress handler
	keydestroy_message -> rc_keypress_handler(message_window);

	if oldwinobj then oldwinobj else false endif -> rc_current_window_object;
	rc_window_sync();
enddefine;


endsection;
/*

CONTENTS

 define lconstant destroy_message(win_obj, x, y, modifier);
 define lconstant keydestroy_message(win_obj, x, y, modifiers, key);
 define rc_message(x,y, strings, spacing, centre, font, bgcol, fgcol) -> message_window;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 19 2000
	Changed to allow keypress to dismiss message panel.
--- Aaron Sloman, Oct  5 1999
	Catered for yet more cases.
--- Aaron Sloman, Sep 16 1999
	Previous fix did not work fully.
	Fixed handling of globals, on exit, using external_defer_apply

--- Aaron Sloman, Jul 29 1999
	Made to restore current window object, if possible
--- Aaron Sloman, Aug 28 1997
	Allowed rc_message_instruct to be false

--- Aaron Sloman, May 20 1997
	reimplemented, using rc_poster
--- Aaron Sloman, May 14 1997
	Fixed test examples, and cleaned up slightly.
--- Aaron Sloman, May  1 1997
	Changed to return a result which can be saved to prevent removal
	by garbage collector.
--- Aaron Sloman, May  1 1997
	Cleaned up and simplified.
--- Aaron Sloman, Apr 29 1997
	Streamlined for new rc_text_area
 */
