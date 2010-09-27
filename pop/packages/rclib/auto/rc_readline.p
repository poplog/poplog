/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_readline.p
 > Purpose:			Get a line of input
 > Author:          Aaron Sloman, May  8 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*

vars panel =
	rc_control_panel(400, 10,
		[{width 500}{height 400}
			[ACTIONS {gap 200}:
				[KILL rc_kill_menu]]], 'TEST');

vars instruct =
	['Type your name in'
	'Press return or click'
	'Then press "OK"'];

rc_readline(600, 300, instruct, '', [], 'Name?')=>
rc_readline(600, 300, instruct, '', [{font 'r24'}], 'Name?')=>
rc_readline(600, 300, instruct, '', [{font 'r24'}{width 500}], 'Name?')=>
rc_readline(6, 30, instruct, 'hello', [{font '6x13'}], 'Name?', panel)=>

*/

section;

compile_mode :pop11 +strict;

uses rclib
uses rc_text_input
uses rc_scrolltext
uses rc_control_panel
uses rc_popup_panel

define rc_readline(x, y, strings, prompt, specs, title) -> list;

	lvars container = false;

	ARGS x, y, strings, prompt, specs, title, &OPTIONAL container:isrc_window_object;

	lvars result;

	rc_getinput(x, y, strings, prompt, specs, title, if container then container endif) -> result;

	if result then
    	pdtolist( incharitem( stringin(result) ) ) -> list;

		;;; expand the dynamic list
    	expandlist(list) -> list;
	else
		[] -> list;
	endif;
		
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 19 1999
	 Allowed optional container argument for parent rc_window_object
 */
