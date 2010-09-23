/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_popup_readin.p
 > Purpose:			Pop up a window with a text or number input field
 > Author:          Aaron Sloman, Aug 19 1997 (see revisions)
 > Documentation:	HELP * RC_TEXT_INPUT
 > Related Files:   LIB * RC_TEXT_INPUT, * LIB * RC_POPUP_READLINE
 */

/*
;;; TEST

rc_popup_readin(
		500,40, ['Who are you' 'tell me'], 'fred',
		"left", 200, 25, '10x20', 'white', 'grey80', 'blue') =>

rc_popup_readin(
		500,40, ['How old are you?'], 0,
		"centre", 200, 25, 'r24', 'white', 'grey80', 'blue') + 0 =>
*/

section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib;
uses rc_text_input
uses rc_warp_to
uses rc_control_panel


;;; Define a couple of methods to take over button 1 down handling
;;; and also text input handling inside rc_popup_readin

define lconstant rc_button_1_down_temp(win, x, y, modifiers);
	;;; a temporary method for taking over interaction in a window.
	lvars input_field = rc_field_contents(rc_field_of_label(win, "text1"));
	rc_button_1_down(input_field, x, y, modifiers)
enddefine;

define lconstant rc_handle_text_input_temp(win, x, y, modifier, key);
	lvars input_field = rc_field_contents(rc_field_of_label(win, "text1"));
	rc_handle_text_input(input_field, x, y, modifier, key);
enddefine;

define rc_popup_readin(
		x,y, strings, default, align, textwidth, textheight, font, bgcol, editcol, fgcol) -> input;

	lvars numeric = isnumber(default);

	unless numeric or isstring(default) then
		mishap(default, 1, 'String or number default needed for text input field')
	endunless;

	dlocal
		rc_text_length_def = textwidth,
		rc_text_height_def = textheight,
		rc_text_font_def = font,
		rc_text_input_bg_def = bgcol,
		rc_text_input_active_bg_def = editcol,
		rc_text_input_fg_def = fgcol;

	lvars panel =
    	rc_control_panel(x, y,
      	[
        {events [mouse keyboard]}
        ;;; A text header field
        [TEXT
            {margin 5}  ;;; margin above and below the text
			
            {align ^align} :
            ;;; Now the strings
      		^^strings
		]
        [%if numeric then "NUMBERIN" else "TEXTIN" endif%
            	{label text1}
            	{align left}
            	{gap 5} {margin 5}
            	{offset 5}
				:
            	^default
        		]
      			], 'readin');

	lvars input_field = rc_field_contents(rc_field_of_label(panel, "text1"));

	
	rc_handle_text_input_temp -> rc_keypress_handler(panel);
	rc_button_1_down_temp -> rc_button_down_handlers(panel)(1);

	if numeric then default sys_>< nullstring else default endif
			-> rc_text_input_active(input_field);

	;;; rc_draw_linepic(input_field);

	rc_warp_to(panel, false, false);

	lvars oldinterrupt = interrupt;

	define dlocal interrupt();
		rc_kill_window_object(panel);
		oldinterrupt();
	enddefine;

	define dlocal rc_text_input_disabled(key, modifier);
		key == "END" or (key == `.` and modifier = 'c')
	enddefine;


	dlocal rc_sole_active_widget = rc_widget(panel);


	repeat
		syshibernate();
		quitunless(rc_text_input_active(input_field))
	endrepeat;
	rc_text_value(input_field) -> input;

	rc_kill_window_object(panel);
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 28 1997
	Changed to use rc_sole_active_widget
--- Aaron Sloman, Aug 19 1997
	Changed so that keyboard input works anywhere, and text fields are
	not extendable.
 */
