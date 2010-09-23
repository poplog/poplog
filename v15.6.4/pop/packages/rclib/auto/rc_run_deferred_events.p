/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_run_deferred_events.p
 > Purpose:			Process deferred events
 > Author:          Aaron Sloman, 23 Jul 2002
 > Documentation:	HELP RC_EVENTS (describes event handling)
					HELP * RCLIB, HELP * RC_MOUSEPIC REF * XT_CALLBACK
 > Related Files:	TEACH * RC_GRAPHIC, HELP * RC_GRAPHIC, LIB * RC_MOUSE
 > 					LIB * RC_BUTTONS
 */

section;

compile_mode :pop11 +strict;
uses rclib
uses rc_mousepic

define rc_run_deferred_events();
	;;; get all pending graphical events processed before continuing,
	;;; e.g. drawing events
	rc_sync_display();
	;;; now process previously deferred events.
	unless Events_list == [] do
		rc_process_event_queue();
	endunless;

	unless Deferred_events_list == [] do
		rc_do_deferred_list();
	endunless;

enddefine;

endsection;
