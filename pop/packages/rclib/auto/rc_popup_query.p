/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_popup_query.p
 > Purpose:			Display a meneu of options,and wait for selection
 > Author:          Aaron Sloman, Apr 13 1997 (see revisions)
 > Documentation:	HELP * RC_BUTTONS/rc_popup_query
 > Related Files:
 */
/*

vars
	strings=
	['Now is the time''for all good men and women''to stand up'
	 'and be counted.' 'What is your answer?'],
	answers1 = [yes no maybe thanks],
	answers2 = ['yes please' 'no thanks' 'sometimes' 'never'],
	answers3 = [ 1 2 3 4],
	answers4 = [one two three four five six seven eight nine ten eleven twelve],
	answers5 = [['yes please' yes] ['no thanks' no]
			['sometimes' sometimes] ['never' never]],
	answers6 = [ {select 'yes please' yes} {select 'no thanks' no}
				{select 'sometimes' sometimes} {select 'never' never} ],

;

vars button_specs =
	{^rc_button_font '8x13' ^rc_button_stringcolour 'yellow'
		^rc_button_bordercolour 'red' ^rc_button_labelground 'brown' };



;;;(x,y, strings, answers, centre, columns, buttonwidth, buttonheight, font, bgcol, fgcol, options, specs) -> selection;
rc_popup_query(300,30, strings, answers1, true, false, 80, 25, '9x15', 'pink', 'black', false, false) =>;
rc_popup_query(300,30, answers2, "numbers", true, 2, 80, 25, '9x15', 'pink', 'black', button_specs, false) =>;
rc_popup_query(300,30, answers2, "NUMBERS", false, 5, 50, 25, '9x15', 'pink', 'black', button_specs, false).datakey =>;
rc_popup_query(300,30, strings, answers1, true, 2, 80, 25, '9x15', 'pink', 'black', button_specs, true) =>;
rc_popup_query(300,30, strings, answers4, true, 4, 80, 25, '9x15', 'pink', 'black', button_specs, true) =>;
vars list =
	rc_popup_query(300,30, answers2, "numbers", false, 2, 40, 25, '9x15', 'pink', 'black', button_specs, true);
	if islist(list) then maplist(list, datakey) else list endif, list =>
rc_popup_query(300,30, answers2, "numbers", false, 2, 40, 25, '9x15', 'pink', 'black', button_specs, true) =>;
rc_popup_query(300,30, strings, answers4, true, 3, 80, 25, '9x15', 'pink', 'black', false, true) =>;
rc_popup_query(300,30, strings, answers1, true, false, 80, 25, '9x15', 'pink', 'black', false, true) =>;
rc_popup_query(300,30, strings, answers1, true, false, 80, 25, '9x15', 'pink', 'black', button_specs, true) =>;
rc_popup_query(300,300, strings, answers2, true, false, 100, 24, '9x15', false, false, false, false) =>;
rc_popup_query(300,300, strings, answers5, true, false, 100, 24, '9x15', false, false, false, false) =>;
rc_popup_query(300,300, strings, answers6, true, false, 100, 24, '9x15', false, false, false, false) =>;
rc_popup_query(300,300, strings, answers2, true, 2, 100, 24, '9x15', false, false, false, true) =>;
rc_popup_query(300,300, strings, answers5, true, 2, 100, 24, '9x15', false, false, false, true) =>;
rc_popup_query(300,300, strings, answers6, true, 2, 100, 24, '9x15', false, false, false, false) =>;
rc_popup_query(300,30,strings, answers1, true, false, 80, 24, '10x20', 'darkslategrey', 'yellow', false, false) =>;
rc_popup_query(300,30,strings, answers1, true, false, 80, 24, '10x20', 'darkslategrey', 'yellow', false, true) =>;
'[[[PLEASE ANSWER TRUTHFULLY]]]' -> rc_popup_query_instruct;
rc_popup_query(300,300,strings,answers3, true, false, 40, 30,'*lucida*-r-*sans-14*', 'yellow', 'blue', false, false) =>;
rc_popup_query(300,300,strings,answers3, true, 2, 40, 30,'*lucida*-r-*sans-14*', 'yellow', 'blue', false, true) =>;
false -> rc_popup_query_instruct;
rc_popup_query(600,100,['Hi there'],answers1, true, false, 80,30,'*lucida*-r-*sans-14*', 'yellow', 'blue', button_specs, false) =>;
rc_popup_query(600,100,['Hi there'],answers4, true, 6, 80,30,'*lucida*-r-*sans-14*', 'yellow', 'blue', false, true) =>;
rc_popup_query(600,100,['Hi there'],answers4, true, 6, 85,40,'12x24', 'yellow', 'blue', {^rc_button_font '12x24'},true) =>;

rc_kill_window_object(rc_current_window_object);
*/

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib
uses rc_window_object
uses rc_informant
uses rc_mousepic
uses rc_buttons
uses rc_warp_to

section;

global vars
	rc_current_query = false,
	;;; String to go at top of message.
	rc_popup_query_instruct = '[SELECT ONE ANSWER]',
	rc_popup_someof_instruct = '[SELECT OPTIONS]',
	rc_someof_labels = [ACCEPT ALL NONE],
	rc_someof_button_width = 80,
	rc_someof_button_height = 30,
	;

define :class rc_select_button; is rc_option_button;
	;;; These are buttons which return the label when selected.
	;;; They use the variable rc_selected_label, declared below.
	;;; Used for LIB rc_popup_query
enddefine;

define :method rc_draw_button_type(pic:rc_select_button, offset, height, colour);
	;;; Draw the border
	rc_draw_border_shape(pic, 0, 0, rc_button_width(pic), height, 2, 1, colour);
enddefine;

/*
define -- Facilities for select buttons
*/

define :method rc_rcbutton_1_down(pic:rc_select_button, x, y, modifiers);
	false -> rc_option_chosen(pic);	;;; it will be made true
	call_next_method(pic,x,y,modifiers);
	pic -> rc_selected_action_button;
enddefine;

global vars rc_selected_label = false;
	
define :method rc_rcbutton_1_up(pic:rc_select_button, x, y, modifiers);
	lvars oldwin = rc_window, wasdifferent = false;

	define lconstant exit_action();
		;;; Make sure button is redrawn even if there's an error
		;;; fix appearance if still on old window
		if rc_window == oldwin and pic then
			
			rc_setframe_draw_border(pic, rc_button_bordercolour(pic));
			;;; used in rc_popup_query
			unless wasdifferent then rc_hide_menu(); endunless;
		endif;
		false -> rc_selected_action_button;
		;;; rc_button_label(pic) -> rc_selected_label;
	enddefine;
	

	dlocal 0 %, if dlocal_context < 3 then exit_action() endif%;

	;;; [UP ^pic selected ^rc_selected_action_button] =>
	if pic==rc_selected_action_button then
		;;; [selected ^pic] =>
		;;; on previously selected button, so record the button info
		;;;	(often the same as the label)
		rc_button_label(pic) -> rc_selected_label;
	else
		;;; Moved off the selected button.
		;;; make sure exit_action works on the previously selected button
		true -> wasdifferent;
		rc_selected_action_button -> pic;
		if pic then
			false -> rc_option_chosen(pic);
			rc_draw_linepic(pic);
		endif;
	endif;
enddefine;

define :method rc_undo_selected(win_obj:rc_selectable, x, y, modifiers);
	if isrc_select_button(rc_selected_action_button) then
		false -> rc_option_chosen(rc_selected_action_button);
		rc_draw_linepic(rc_selected_action_button);
		false -> rc_selected_action_button;
	endif;
enddefine;

define lconstant trynumber(numbers_wanted, answer) -> answer;
	;;; convert strings back to numbers if necessary
	if numbers_wanted then
		if islist(answer) and answer /== [] then
			lvars item;
			[%for item in answer do trynumber(numbers_wanted, item) endfor%]
				-> answer
		else
			(isstring(answer) and strnumber(answer)) or answer  -> answer
		endif
	endif
enddefine;


define vars rc_getoptions(answer, buttons) -> options;
	;;; get all the labels of buttons in buttons that have been selected
	lvars
		button,
		(accept, all, none) = explode(rc_someof_labels);
	if answer == none then []
	elseif answer == all then
		maplist(buttons, rc_button_label)
	else
		;;; answer was accept
		rc_options_chosen(buttons)
	endif -> options
enddefine;




define rc_popup_query(x,y, strings, answers, centre, columns, buttonW, buttonH, font, bgcol, fgcol, specs, options) -> selection;
    ;;; flush all output buffers, so that previous printout is visible, etc.
	rc_flush_everything();

	lvars oldwin_obj = rc_current_window_object;

	dlocal rc_current_query;

	lvars
		numbers_wanted = false,
		strings, actionwidth;

	if answers == "numbers" or answers == "NUMBERS" then
		true -> numbers_wanted;
		lvars counter = 1, item;
		lvars temp = [];
		[%fast_for item in strings do
			counter sys_>< ': ' sys_>< item;
			conspair(counter, temp) -> temp;
			counter + 1 -> counter
		endfor%] -> strings;
		ncrev(temp) -> temp;
		if not(options) and answers == "NUMBERS" then
			;;; allow None as alternative
			[None ^^temp] -> temp
		endif;
		temp -> answers;
	endif;

	if options then
		if rc_popup_someof_instruct then
			[^rc_popup_someof_instruct '' ^^strings] -> strings
		endif,

		(rc_someof_button_width + 1)*length(rc_someof_labels) + 4 ->actionwidth

	elseif rc_popup_query_instruct then
		[^rc_popup_query_instruct '' ^^strings] -> strings;
		0 -> actionwidth
	endif;

	lvars rows, extra;

	if columns then
		listlength(answers)//columns -> (extra, rows);
		if extra > 0 then rows+1 -> rows endif;
	else
		listlength(answers) -> columns;
		1 -> rows;
	endif;

	lvars
		(list, stringW, stringH, ascent) = rc_text_area(strings, font),
		columnswidth = (buttonW + 1)*columns + 4,
		picW = max(columnswidth, stringW);

	if options then
		max(actionwidth, picW) -> picW;
	endif;

	lvars
		stringoffset	;;; indentation of strings
			= if stringW < picW then (picW - stringW) div 2 else 0 endif,

		buttonoffset	;;; indentation of buttons
			= if columnswidth < picW then (picW - columnswidth) div 2 else 0 endif,
		
		depth			;;; vertical space required
			=
			stringH*length(strings) + rows*buttonH
				+ if options then 10 + rc_someof_button_height else 4 endif;

	;;; Now make the window
	rc_new_window_object(
		x, y, round(picW+6), round(depth+8),
			{0 0 1 1}, newrc_button_window, 'RC_QUERY')
			   	->> rc_current_query -> rc_current_window_object;

	;;; Make its button_1_up handler unset select buttons
	lconstant up_handler = {rc_undo_selected ^false ^false};
	up_handler -> rc_button_up_handlers(rc_current_query);

	;;; Make the window sensitive to button and enter/exit events
	rc_mousepic(rc_current_query, [button mouse]);

	if bgcol then bgcol -> rc_background(rc_window); rc_window_sync(); endif;
	if fgcol then fgcol -> rc_foreground(rc_window); rc_window_sync(); endif;

	rc_print_strings(3+stringoffset, 4, strings, 0, centre, font, false, false) -> (, );


	;;; Create the main buttons from the list of answers
	lvars buttons =
	create_button_columns(
		4+buttonoffset, 6+stringH*length(strings), buttonW, buttonH,
		   1, columns, answers, if options then "someof" else "select" endif, specs);

	if options then
		;;; Create the action buttons to terminate interaction
		lvars
			actionoffset =
				if actionwidth < picW then (picW - actionwidth) div 2 else 0 endif;

		;;; rc_someof_labels.Veddebug;

		create_button_columns(
			2+actionoffset, 6+stringH*length(strings) + 5 + rows*(buttonH +1),
				rc_someof_button_width, rc_someof_button_height,
					1, 0, rc_someof_labels, "select", specs) ->;

		;;; and give the options buttons the appropriate up handler
		lvars pic;
		for pic in buttons do
			up_handler -> rc_button_up_handlers(pic);
		endfor;
	endif;


	sys_grbg_list(list);
	[] -> list;

	lvars oldinterrupt = interrupt;

	dlocal rc_selected_label = false;

	define dlocal interrupt();
		dlocal interrupt = oldinterrupt;
		;;; ['interrupt' ^rc_selected_label] =>
		rc_kill_window_object(rc_current_query);
		false -> rc_current_query;

		;;; decide on result
		if rc_selected_label then
			;;; somehow got hung up
			if options then
				rc_getoptions(rc_selected_label, buttons)
			else rc_selected_label
			endif
		else
			false
		endif -> selection;
		trynumber(numbers_wanted, selection);
		rc_flush_everything();
		if oldwin_obj then oldwin_obj -> rc_current_window_object endif;
		exitfrom(rc_popup_query)
	enddefine;

	;;; XtMapWidget(shell);

	false -> selection;
	rc_warp_to(rc_current_query, false, false);
	rc_window_sync();

	;;; make sure all events are handled immediately
	;;; and no events in other widgets are handled
	dlocal
		rc_external_defer_apply = apply,
		rc_sole_active_widget = rc_widget(rc_current_query);

	;;; Essentially sleep till (a) interrupted or (b) rc_selected_label
	;;; is set true
	repeat
		quitif(rc_selected_label);

		syshibernate();
	endrepeat;

	false -> rc_sole_active_widget;

	;;; Reset deferred actions
	external_defer_apply -> rc_external_defer_apply;

	;;; ['selection done' ^rc_selected_label] =>

	;;; Now work out what the result should be
	if options then
		rc_getoptions(rc_selected_label, buttons)
	else rc_selected_label
	endif -> selection;
	trynumber(numbers_wanted, selection) -> selection;

	rc_kill_window_object(rc_current_query);
	rc_window_sync();

	false -> rc_current_query;
	if oldwin_obj then oldwin_obj -> rc_current_window_object endif;
enddefine;


endsection;

/*
CONTENTS

 define :class rc_select_button; is rc_option_button;
 define :method rc_draw_button_type(pic:rc_select_button, offset, height, colour);
 define -- Facilities for select buttons
 define :method rc_rcbutton_1_down(pic:rc_select_button, x, y, modifiers);
 define :method rc_rcbutton_1_up(pic:rc_select_button, x, y, modifiers);
 define :method rc_undo_selected(win_obj:rc_selectable, x, y, modifiers);
 define lconstant trynumber(numbers_wanted, answer) -> answer;
 define vars rc_getoptions(answer, buttons) -> options;
 define rc_popup_query(x,y, strings, answers, centre, columns, buttonW, buttonH, font, bgcol, fgcol, specs, options) -> selection;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 25 2002
    replaced rc_ informant_contents with rc_informant_value
--- Aaron Sloman, Aug  7 2002
		Required changes to cope with improved LIB rc_buttons. The label is
		accessed via rc_ button_label not rc_ informant_contents

		Changed compile_mode from strict
--- Aaron Sloman, Jun 15 2000
	changed rc_draw_button_type for new format
--- Aaron Sloman, Sep 15 1999
	Extended to use new button format options.
--- Aaron Sloman, Jul 29 1999
	Made to restore previous current window object
--- Aaron Sloman, Feb  3 1998
	Rebuilt table of contents. Updating HELP * RC_BUTTONS
--- Aaron Sloman, Sep  2 1997
	Fixed so that raising button when moved off a "select" button resets the
		select button
--- Aaron Sloman, Aug 28 1997
	Changed to use rc_sole_active_widget
--- Aaron Sloman, Jul  8 1997
	Replaced rc_button*_info with rc_informant_value
--- Aaron Sloman, Jun 30 1997
	Fixed to handle info field
--- Aaron Sloman, Jun 29 1997
	Changed to use someof buttons and new rc_button facilities.
		Also allowed labels to be mapped on to other objects, e.g.
		strings to words or numbers
--- Aaron Sloman, Jun 22 1997
	Allow "NUMBERS" argument for answers, to add "None" as an option.
--- Aaron Sloman, Jun 21 1997
	Allow "numbers" argument for answers.
		Prevent deferred events in menus, by redefining
		rc_external_defer_apply as apply
--- Aaron Sloman, May  4 1997
	changed to use rc_warp_to
--- Aaron Sloman, May  1 1997
	made to use rc_flush_everything initially. Also now computes size of window
	before creating it, using rc_default_window_object via rc_text_area

--- Aaron Sloman, Apr 27 1997
	Extended to work with options buttons
 */
