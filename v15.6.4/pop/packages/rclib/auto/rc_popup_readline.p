/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_popup_readline.p
 > Purpose:			Pop up a window with a text or number input field
 > Author:          Aaron Sloman, Aug 19 1997
 > Documentation:	HELP * RC_TEXT_INPUT
 > Related Files:   LIB * RC_TEXT_INPUT, * RC_POPUP_READIN * RC_INTERPRET_KEY
 */
/*
;;; TEST


rc_popup_readline(
		500,40, ['Who are you' 'tell me'], 'fred',
		"left", 400, 25, '10x20', 'white', 'grey80', 'blue') =>

rc_popup_readline(
		500,40, ['How old are you?' 'Write it in words'], '',
		"centre", 200, 25, 'r24', 'white', 'grey80', 'blue') =>
*/



section;
compile_mode :pop11 +strict;

uses rclib;
uses rc_text_input
uses rc_warp_to
uses rc_control_panel

define rc_popup_readline(
	x,y, strings, default, align, textwidth, textheight, font, bgcol, editcol, fgcol) -> list;

lvars rep =
	incharitem(
		stringin(
			rc_popup_readin(
				x,y, strings, default, align,
					textwidth, textheight, font, bgcol, editcol, fgcol)));

	dlocal popnewline = true;

	lvars item;

	;;; Make a list items to next newline
	[% until (rep() ->> item) == newline or item == termin do item enduntil %] -> list;


enddefine;

endsection;
