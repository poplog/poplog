/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/brait/lib/process_event_queue.p
 > Purpose:			May be useful to deal with unwanted mouse interactions
 > Author:          Aaron Sloman, Oct  8 2000
 > Documentation:
 > Related Files:	LIB rc_mousepic/rc_process_event_queue.p
 */

/*
If this is compiled it redefines the procedure rc_process_event_queue
from LIB rc_mousepic so that it doesn't process any event while
rc_current_picture_object is non-false. That variable is made true
during drawing.

This may be needed to prevent mouse interaction messing up a drawing
in the brait window.

However it can also make the control panel too insensitive.

So it is not included by default in lib braitenberg_sim

A.Sloman 8 Oct 2000
*/


define vars procedure rc_process_event_queue();
	;;; widget is window, item is "button" or "move", data will be
	;;; the button number, < 0 if released. proc is the handler
	;;; procedure to be invoked, usually a method.

	;;; action to postpone events during processing of these
	;;; events
	dlocal
		rc_in_event_handler, vedwarpcontext = false;

	if rc_in_event_handler or rc_current_picture_object then
		;;;'in event handler' =>
		;;; Already handling an event. Stop.
		;;; Th events on the queue will be processed later
		;;; as the handler already active works through the Events list.
		;;; Just in case try again a hundredth of a second later
		1e4 -> sys_timer(rc_process_event_queue);
		return();
	else
		true -> rc_in_event_handler
	endif;

	 ;;;'entering event handler' =>

	lvars
		oldcucharout = cucharout,
		oldcucharerr = cucharerr,
		oldprmishap = prmishap;

	define lconstant ved_char_consumer(char);
		;;; if editing, then send output to a VED window
		vededit(rc_charout_buffer);
		dlocal vedbreak = true;
		unless vedline >= vvedbuffersize then vedendfile() endunless;
		vedcharinsert(char)
	enddefine;

	
	define lconstant prmishapinved();
		;;; If errors occur, restore output
		dlocal cucharout = oldcucharout, cucharerr = oldcucharerr;
		oldprmishap();
	enddefine;

	dlocal cucharout, cucharerr, prmishap;

	if vedinvedprocess or vedediting /* or vedusewindows == "x" */ then

		ved_char_consumer ->> cucharout -> cucharerr;
		prmishapinved -> prmishap;

	endif;

	until Events_list == [] do
		lvars event;
		sys_grbg_destpair(Events_list) -> (event, Events_list);

		rc_process_event(event);
	enduntil;

	rc_sync_display();	

	;;; now process deferred events, outside of the context used for the
	;;; current active window object
	chain(process_defer_list,external_defer_apply);
enddefine;

global constant process_event_queue = true;
