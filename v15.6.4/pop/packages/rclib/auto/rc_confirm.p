/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_confirm.p
 > Purpose:			Get Yes or No answer to a question
 > Author:          Aaron Sloman, May  9 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
;;; test

rc_confirm(40, 20, ['There is a problem.' 'Do you know the answer?'], [Yes No], '9x15', 'Confirm')=>
rc_confirm(400, 20, ['Ugh a problem.' 'Continue?'], ['Yes' 'No' 'Maybe'], '10x20', 'Confirm')=>

An alternative:

rc_popup_query(
    x, y, ['hi there'], [OK], true, false, width, height,
        font, 'white', 'black', false, specs) -> =>

rc_popup_query(
    400, 20, ['Are you OK?'], [Yes No], true, false, 45, 30,
        '10x20', 'white', 'black', false, false)=>
*/


section;

uses rclib
uses rc_popup_query

compile_mode :pop11 +strict;

define rc_confirm(x, y, strings, answers, font, title) -> answer;
	lvars container = false;

	ARGS x, y, strings, answers, font, title, &OPTIONAL container:isrc_window_object;

	lvars done = false;

	define lconstant ok;
		true -> done;
	enddefine;

	define finished(obj, val);
		true -> done;
		val -> answer
	enddefine;

	rc_popup_panel(x, y,
		[	[TEXT {align centre} {offset 4} {font ^font} : ^^strings]
			[RADIO
				{width 80}
				{reactor ^finished}: ^^answers]
		],
		title, ident done, if container then container endif);

enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, May 19 1999
	 Allowed optional container argument for parent rc_window_object
 */
