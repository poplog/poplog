/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_popup_panel.p
 > Purpose:			Put up an instance of rc_control_panel waiting for input
 > Author:          Aaron Sloman, May  8 1999 (see revisions)
 > Documentation:
 > Related Files:	Various popup utilities based on this in
					$poplocal/local/rclib/auto, e.g.
					LIB * RC_POPUP_STRINGS, RC_GETFILE
 */

/*

;;; test rc_popup_panel

vars panel1 = rc_control_panel(200,20,
	[{width 300}{height 300}
		[ACTIONS {gap 100}:
			['DISMISS' rc_kill_menu]]], 'test');


lvars xxx = false;

define lconstant doit; true -> xxx enddefine;

rc_popup_panel(40, 20,
	[[ACTIONS: ['OK' ^doit ]]],
	'test_window', ident xxx, panel1)=>

*/


section;
compile_mode :pop11 +strict;

uses rclib
uses rc_control_panel


global vars rc_current_query;

define rc_popup_panel(x, y, panel_info, title, control_ident);
	lvars container = false;

	ARGS x, y, panel_info, title, control_ident, &OPTIONAL container:isrc_window_object;

	rc_control_panel(x, y, panel_info, title, if container then container endif) -> rc_current_query;

	lvars oldinterrupt = interrupt;
	dlocal interrupt = oldinterrupt;

	define dlocal interrupt();
		dlocal interrupt = oldinterrupt;
		;;; ['interrupt' ^selection] =>
		rc_kill_window_object(rc_current_query);
		false -> rc_current_query;
		false -> valof(control_ident);
		rc_flush_everything();
		clearstack();
		exitfrom(rc_popup_panel);
	enddefine;

	;;; put cursor on new panel
	rc_warp_to(rc_current_query, false, false);
	rc_window_sync();

	;;; make sure all events are handled immediately
	;;; and no events in other widgets are handled
	dlocal
		rc_external_defer_apply = apply,
		rc_sole_active_widget = rc_widget(rc_current_query);

	;;; Essentially sleep till (a) interrupted or (b) done
	;;; is set true
	false -> valof(control_ident);
	repeat
		quitif(valof(control_ident));

		syshibernate();
	endrepeat;

	false -> rc_sole_active_widget;

	;;; Reset deferred actions
	external_defer_apply -> rc_external_defer_apply;

	rc_kill_window_object(rc_current_query);
	rc_window_sync();

	false -> rc_current_query;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 19 1999
	Allowed optional container panel as extra argument
 */
