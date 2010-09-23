/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_scratch_panel.p
 > Purpose:			Easy control of RC_GRAPHIC windows
 > Author:          Aaron Sloman, Jul  8 1997 (see revisions)
 > Documentation:	TEACH * RCLIB_DEMO.P/rc_scratchpad
 > Related Files:
 */

/*
;;; test it

rc_scratch_panel(10,10);

rc_draw_blob(0,0,20,'yellow');

rc_draw_blob(150-random(300),200-random(400),10+random(30),
	oneof(['red' 'green' 'blue' 'pink' 'black']));

*/

section;
compile_mode :pop11 +strict;

uses rclib
uses rc_scratchpad;
uses rc_control_panel
uses rc_make_current_window


define rc_scratch_panel(x, y);
	rc_control_panel(x, y,
		[[ACTIONS {cols 0} {width 85}:
        	;;; This saves the previous scratchpad and starts a new one
        	['New Pad'
				[POP11 rc_tearoff();
					rc_make_current_window(rc_scratch_window)]]

        	;;; this kills all the saved tearoffs
        	['Kill Torn' rc_kill_tearoffs]

        	;;; This hides the current scratchpad window
			['Hide Pad'
				[POP11 false -> rc_scratch_window]]

			{blob 'KILL' rc_kill_menu}
		]], 'SCRATCHPAD') ->
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 20 2000
	Altered to use rc_make_current_window
 */
