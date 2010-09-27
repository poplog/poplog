/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_text_input.p
 > Purpose:			Support picture objects with text input fields
 > Author:          Aaron Sloman, Jul 28 1997 (see revisions)
 > Documentation:	HELP * RC_TEXT_INPUT, HELP * RCLIB, HELP * RC_KEYCODES
 > Related Files:	LIB * RCLIB, LIB * RC_INTERPRET_KEY
 > 					LIB * RC_POPUP_READIN * RC_INTERPRET_KEY
 > 					LIB * RC_POPUP_READLINE, * RC_CONTROL_PANEL
 */

/*

;;; TESTS
rc_kill_window_object(win1);
uses rclib;
uses rc_window_object;
;;; Test the commands below in each of these windows. Despite scale change,
;;; the text and number input fields should be the same size. Only location
;;; changes.
vars win1 = rc_new_window_object(700, 40, 300, 250, true, 'win1');
vars win1 = rc_new_window_object(520, 40, 600, 500, {300 250 2 2}, 'win1');
vars win1 = rc_new_window_object(520, 40, 600, 500, {300 250 -2 2}, 'win1');
vars win1 = rc_new_window_object(520, 40, 600, 500, {300 250 2 -2}, 'win1');
win1 -> rc_current_window_object;


;;;create_text_input_field(x, y, width, height, value, extendable, font, creator) -> field;
vars xxx = 'hello';

rc_start();
vars t1 = create_text_input_field(0,95,80, 20, [^undef {ident xxx}], true, '8x13', newrc_text_button);
vars t1a = create_text_input_field(0,95,80, 20, ['' {ident xxx}], true, '8x13', newrc_text_button);
t1 =>
rc_text_value(t1) =>
xxx =>
;;; check that text field expands
'SILLY' -> rc_text_value(t1);
'SILLY fish' -> rc_text_value(t1);
'SILLY fishes' -> rc_text_value(t1);
'SILLY BOY' -> rc_informant_value(t1);

rc_informant_value(t1) =>
rc_informant_ident(t1) =>
rc_pic_strings(t1) =>

;;; Add a string to be printed as label,when the field is next updated
;;; or drawn. (This is not as good as using the label mechanism)
[{-70 -15 'My name:'}] -> rc_pic_strings(t1);
;;; for doubled scale
[{-30 7.5 'My name:'}] -> rc_pic_strings(t1);
;;; for doubled scale with yscale negative
[{-30 -7.5 'My name:'}] -> rc_pic_strings(t1);
rc_draw_linepic(t1);

vars t1val;
ident t1val -> rc_informant_ident(t1);

t1val =>

vars t2 =
	create_text_input_field(-50,65,80, 30, 'Hello', false, '9x15', newrc_text_button);

rc_text_value(t2) =>

;;; '12x24' -> rc_text_font(t1);

;;; A text input field with a label, and extra specifications
vars t3 =
	create_text_input_field(-50,30,100, 40,
		['T3 button' {labelstring 'Myname:'}{labelfont '12x24'}{labelcolour 'blue'}
			{fg 'brown'}{bg 'ivory'}{activebg 'yellow'} {font '10x20'}],
			false, '9x15', newrc_text_button);

;;;create_input_field(x, y, width, height,
;;;		content, extendable, font, proc) -> field;
vars t3a =
	create_input_field(-50,-30,100, 40,
		['T3 here' {labelstring 'Myname:'}{labelfont '12x24'}{labelcolour 'blue'}
			{fg 'ivory' bg 'brown' activebg 'darkgreen' font '8x13'}],
			true, '9x15', identfn);

rc_start();
vars t3b =
	create_input_field(-40,-30,100, 40,
		[55 {labelstring 'Mynumber:'}{labelfont '12x24'}{labelcolour 'blue'}
			{fg 'brown'}{bg 'ivory'}{activebg 'yellow'} {font '10x20'}],
			false, '9x15',identfn);

;;; this should be a number input field.
t3b =>

t3.rc_label_string =>
rc_text_value(t3) =>
'HI' -> rc_text_value(t3);

;;; Now a number input field
vars t4 = create_text_input_field(0,-20,90,20, 0, false, '10x20', newrc_number_button);
t4 =>
333->rc_informant_value(t4);
333.225->rc_informant_value(t4);
0 -> rc_text_value(t4);
rc_pr_places(t4) =>
2 -> rc_pr_places(t4);


rc_start();
;;; Now a number input field with a label
vars t5 =
	create_text_input_field(
		-10,-50,70,25,
		[10 {label 'Age at birth:'} {labelfont '10x20'} {labelcolour 'darkgreen'}
			;;; try uncommenting one of these
			;;; {constrain round}
			{places 2}
		],
		120, '12x24', newrc_number_button);

t5=>
rc_text_value(t5) =>
333.567 -> rc_text_value(t5);
'333.567' -> rc_text_value(t5);
555.4567 -> rc_informant_value(t5);
555555.4567 -> rc_informant_value(t5);
'555555.45678' -> rc_informant_value(t5);
'10' -> rc_informant_value(t5);
rc_pr_places(t5) =>
t5=>

rc_text_value(t5) =>
'SILLY DOGGIE' -> rc_text_value(t1);


;;; Now a number input field with variable pre-set
vars nt6 = 99;
vars t6 = create_text_input_field(0,-50,90,20, [^undef {ident nt6}], false, '10x20', newrc_number_button);
nt6=>

win1.rc_window_contents ==>

t1.rc_informant_value ==>
t1.rc_pic_strings ==>
t1.rc_text_string ==>
t1.rc_text_input_active =>
t1 =>
t1.datalist ==>
rc_text_font(t1) -> rc_text_font(t1);
;;; try clicking on a text input window after changing the font.
'8x13' -> rc_text_font(t1);
'10x20' -> rc_text_font(t1);
'12x24' -> rc_text_font(t1);
t1.rc_keypress_handler =>

t3=>
rc_text_string(t3) =>
rc_text_value(t3) =>
;;; This will corrupt t3.
999 -> rc_text_value(t3);
'999' -> rc_text_value(t4);
999.99999 -> rc_text_value(t5);

'8x13bold' -> rc_text_font(t3);
'10x20' -> rc_text_font(t3);
'12x24' -> rc_text_font(t3);

rc_kill_window_object(win1);

*/


section;
;;; compile_mode :pop11 +strict;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;


uses rclib
uses rc_linepic
uses rc_window_object
uses rc_informant
uses rc_mousepic
;;; uses rc_default_window_object
uses interpret_specs

global vars
	;;; default font for text fields
	rc_text_font_def = '8x13',
	rc_label_font_def = '8x13',
	rc_text_border_width_def = 2,
	rc_text_input_bg_def = 'white',
	rc_text_input_active_bg_def = 'grey85',
	rc_text_input_fg_def = 'black' ,
	rc_label_colour_def = 'black' ,
	rc_text_length_def = 100,
	rc_text_height_def = 20;
	;

;;; This can be used temporarily to turn off the effects of input keys
define vars rc_text_input_disabled(key, modifier);
	false
enddefine;

define :mixin vars rc_text_input;
    is rc_keysensitive, rc_linepic, rc_selectable, rc_informant;
	slot rc_informant_reactor == "rc_text_altered";
	slot constant RC_text_font = rc_text_font_def;
	slot constant RC_char_width = undef;
	slot constant RC_char_height = undef;
	slot constant RC_char_ascent = undef;
	slot rc_text_border_width = rc_text_border_width_def;
	slot rc_text_input_bg = rc_text_input_bg_def ;
	slot rc_text_input_active_bg = rc_text_input_active_bg_def;
	slot rc_text_input_fg = rc_text_input_fg_def;
	slot rc_text_length = rc_text_length_def;
	slot rc_text_height = rc_text_height_def;
	slot rc_text_input_active == false;
	;;; controls whether box expands to accommodate string
	slot rc_text_extendable == true;
	slot rc_pic_lines = "rc_DRAW_TEXT_INPUT";
	slot rc_pic_strings == "rc_SHOW_TEXT_LABEL";
	slot rc_text_string == nullstring;
	slot rc_label_string == nullstring;
	slot rc_label_font = rc_label_font_def;
	slot rc_label_colour = rc_label_colour_def;
	slot rc_check_text == identfn;
	;;; the next two slots are given number to string and string
	;;; to number procedures for number fields.
	slot rc_text_convert_out == identfn;
	slot rc_text_convert_in == identfn;
	slot rc_text_pointer == undef;
	slot vars rc_mouse_limit = {0 %20.0/rc_yscale,  100/rc_xscale% 0};
	slot rc_keypress_handler = "rc_handle_text_input";
	;;; Change default event handlers
	slot vars rc_button_up_handlers =
		{ ^false ^false ^false};
	slot vars rc_button_down_handlers =
		{ rc_button_1_down ^false ^false};
	slot vars rc_drag_handlers =
		{ ^false ^false ^false};

    ;;; Move event handlers
	slot vars rc_move_handler = false;
enddefine;

define :mixin vars rc_number_input; is rc_text_input;
	slot rc_text_convert_in = "rc_convert_number_in";
	slot rc_text_convert_out = "rc_convert_number_out";
	slot rc_text_string == '0';
	slot rc_check_text == "rc_check_number_format";
	;;; A slot holding a value to be used for pop_pr_places
	slot rc_pr_places == false;
	slot rc_number_input_saved == '0';
	;;; This slot removed 26 Mar 1999 because rc_constrain_contents does its job
	;;; slot rc_constrain_number == identfn;
enddefine;


/*
;;; Tests for next procedure (remove "constant")
transform_places('3.566',2)=>
transform_places('-3.566',2)=>
transform_places('3.5646',2)=>
transform_places('-3.5646',2)=>
transform_places('3.5',2)=>
transform_places('300.1234567',2)=>
transform_places('3000000.1234567',2)=>
transform_places(1.2345_+:3.4567,2)=>

*/

define constant transform_places(num, places)->num;
	;;; Truncate number of decimal places to pop_pr_places
	;;; after rounding
	dlocal
		pop_pr_quotes = false,
		pop_pr_places = places;

	lvars wasstring = isstring(num);

	if places and places /== 0 then
		if wasstring then strnumber(num) -> num endif;

		`0` << 16 || places -> pop_pr_places;
		(num + 0.0) >< nullstring -> num;

		unless wasstring then strnumber(num) -> num endunless;
	endif;
enddefine;

define :method prepare_for_printing(num, pic:rc_number_input) -> num;
	lvars places = rc_pr_places(pic);
	if places then
		;;; Ensure adequate decimal points shown.
		dlocal pop_pr_places, pop_pr_quotes = false;

		if places == 0 then places	
		else `0` << 16 || places
		endif -> pop_pr_places;

		lvars n = strnumber(num);
		if n then (n + 0.0) >< nullstring -> num; endif;
	endif;
enddefine;


define :method updaterof rc_informant_value(newval, pic:rc_text_input);
	;;; returnif(self_caller());
	
	lvars
		old_win = rc_current_window_object,
		textin_win = rc_informant_window(pic);

	;;; run any constraint, etc (May mishap)
	call_next_method(newval, pic);
	;;; get converted value
	rc_informant_value(pic) -> newval;

	;;; Update the text input field
	recursive_valof(rc_text_convert_in(pic))(newval) -> newval;
	prepare_for_printing(newval, pic) -> rc_text_string(pic);

	if textin_win and textin_win /== old_win then
		textin_win -> rc_current_window_object;
	endif;
	false -> rc_text_input_active(pic);
	datalength(rc_text_string(pic)) -> rc_text_pointer(pic);
	rc_draw_linepic(pic);
	rc_information_changed(pic);
	if rc_current_window_object /== old_win then
		old_win -> rc_current_window_object
	endif;
enddefine;


define :method updaterof rc_informant_value(val, pic:rc_number_input);

	lvars places = rc_pr_places(pic);

	if places and places /== 0 then
		;;; make sure trailing places are padded with 0
		transform_places(val, places) ->val;
	endif;

	call_next_method(val, pic);
	
	;;; just in case a string was stored as value
	lvars newval = rc_informant_value(pic);
	unless isnumber(newval) then
		strnumber(newval) -> rc_informant_value(pic)
	endunless;
enddefine;

define :method rc_text_value(pic:rc_text_input) -> val;
	lvars
		s = rc_text_string(pic),
		newval = recursive_valof(rc_text_convert_out(pic))(s),
		val = rc_informant_value(pic);

	;;; allow text value to be converted
	unless val = newval then
		newval ->> val -> rc_informant_value(pic)
	endunless;
enddefine;

define :method updaterof rc_text_value(newval, pic:rc_text_input);
	newval -> rc_informant_value(pic)
enddefine;

define :method constant consolidate_or_activate(pic:rc_text_input);
	;;; switch between active and non-active mode	
	lvars
		ISactive = rc_text_input_active(pic);

	if ISactive then
		prepare_for_printing(ISactive, pic) -> rc_text_string(pic);
		false -> rc_text_input_active(pic);
		recursive_valof(rc_text_convert_out(pic))(ISactive)
					-> rc_informant_value(pic);
	else
		prepare_for_printing(rc_text_string(pic), pic) -> rc_text_input_active(pic);
	endif;
	rc_draw_linepic(pic);
enddefine;


define :method rc_button_1_down(pic:rc_text_input, x, y, modifiers);
	;;; Click on an object to move it in and out of edit mode.
	consolidate_or_activate(pic);
enddefine;



define :method print_instance(pic:rc_text_input);
	printf('<TEXTIN(%P,%P): %P>',
			[%rc_coords(pic), rc_text_value(pic)%])
enddefine;

define :method constant consolidate_or_activate(pic:rc_number_input);
	;;; consolidate, taking account of rc_pr_places
	lvars places = rc_pr_places(pic);
	if places then
		lvars ISactive
			ISactive = rc_text_input_active(pic);
		if ISactive then
			transform_places(ISactive, places) -> rc_text_input_active(pic);
		else
			transform_places(rc_text_string(pic), places) -> rc_text_string(pic);
		endif;
	endif;
	call_next_method(pic);
enddefine;

define :method print_instance(pic:rc_number_input);
	dlocal pop_pr_places;
	lvars places = rc_pr_places(pic);
	if places == 0 then
		places -> pop_pr_places
	elseif places then
		`0` << 16 || places -> pop_pr_places
		endif;
	printf('<NUMBERIN(%P,%P): %P>',
			[%rc_coords(pic), rc_text_value(pic)%])
enddefine;

;;; Not constant. Must be user definable
define rc_convert_number_in(number) -> string;
	if isnumber(number) then
		number sys_>< nullstring -> string
	elseif isstring(number) and strnumber(number) then
		number -> string;
	else
		mishap(number, 1, 'Number expected')
	endif
enddefine;

;;; Not constant. Must be user definable
define rc_convert_number_out(string) -> number;
	strnumber(string) -> number
enddefine;

;;; This should not be constant. User definable.
define rc_check_number_format(string) -> boole;
	;;; allow integers, decimals, ratios and complex numbers

	if string == nullstring or strnumber(string) or string = '-' then
		true
	elseif isendstring('_', string) or isendstring('_/', string)
	or isendstring('_+', string) or isendstring('_+:', string)
	or isendstring('_-', string) or isendstring('_-:', string)
	or isendstring('e', string)
	or isendstring('e-', string)
	or isendstring('e+', string)
	or isendstring('d+', string)
	or isendstring('d-', string)
	or isendstring('s-', string)
	or isendstring('s+', string)
	or (length(string) > 1
		and isnumbercode(string(length(string)-1))
		and strmember(last(string), 'ds:') )
	then
		true
	else
		string(datalength(string)) == `.` and
		(isinteger(strnumber(allbutlast(1, string)))
			or hassubstring(string, '_+:')
			or hassubstring(string, '_-:'))
	endif -> boole;
enddefine;

define :method rc_text_altered(pic:rc_text_input, val);
	;;;; user definable
enddefine;

define :method rc_text_altered(pic:rc_number_input, val);
	;;; User definable
enddefine;

define constant rc_increment_pointer(num, pic, string);
	lvars p = rc_text_pointer(pic);
	if p == undef then datalength(string) -> p endif;
	max(0, p + num) -> p;
	min(p, datalength(string)) -> rc_text_pointer(pic);
enddefine;

define constant rc_places_ok(pic, string, p, key) -> boole;

	;;; Check if adding more decimal points is OK.
	lvars
		constrainer = rc_constrain_contents(pic),
		places = rc_pr_places(pic);
	if recursive_valof(constrainer) == round then
		0 -> places
	endif;
	if key == `.` then
		;;; cannot allow "." if rounding or places == 0
		isinteger(places) and places > 0 or not(places) -> boole
	elseif isinteger(places) then
		lvars loc = locchar_back(`.`,p,string);
		if loc then
			;;; Contains decimal point make sure it's not the imaginary part
			;;; of an imaginary number
			lvars loc2 = locchar_back(`_`,p,string);
			if loc2 and loc2 > loc then
				true -> boole
			;;; And doesn't use the 'e' or 'd' or 's' syntax
			elseif strmember(`e`, string) or strmember(`d`,string)
				or strmember(`s`, string)
			then
				true -> boole
			else
				p - loc < places -> boole
			endif
		else
			;;; no decimal point
			true -> boole;
		endif
	else
		true -> boole;
	endif;
enddefine;

define :method rc_handle_text_input(pic:rc_text_input, x, y, modifier, key);

	lvars
		ISactive = rc_text_input_active(pic),
		string = rc_text_string(pic);

	unless ISactive then
		;;; make sure string pointer has a value
		rc_increment_pointer(0,pic,string);
	endunless;

	;;; React only to downwards keypresses
	returnunless(key > 0);

	;;; Stuff for possible debugging
	;;; write to Ved's output file, in non-saving mode
    ;;; vededit('output.p', vedhelpdefaults);
    ;;; vedendfile();
    ;;; Make printing go into the output buffer
    ;;; dlocal cucharout = vedcharinsert;

	rc_interpret_key(key) -> key;

	if rc_text_input_disabled(key, modifier) then
		return()
	elseif key == "END" or (modifier = 'c' and key == `.`) then
		not(rc_text_extendable(pic)) -> rc_text_extendable(pic);
		return();
	elseif key == "HOME" or (modifier = 'c' and key == `r`) then
		;;; CTRL R, or Home: reset to previous value
		false -> rc_text_input_active(pic);
		consolidate_or_activate(pic);
		return();
	elseif modifier = 'c' then
		;;; Control key held down
		if ISactive then ISactive -> string endif;
		if key == `u` then
			;;; CTRL U, delete whole line
			nullstring ->> ISactive -> string;
			rc_increment_pointer(0,pic,string);
		elseif key == `a` then
			rc_increment_pointer(-9999999, pic, string)
		elseif key == `e` then
			rc_increment_pointer(9999999, pic, string)
		elseif key == `=` then
			;;; CTRL =   print the text
			prepare_for_printing
				(nullstring >< recursive_valof(rc_constrain_contents(pic))
					(recursive_valof(rc_text_convert_out(pic))(
						if ISactive then ISactive else string endif)),pic) =>
			return()
		else
			return()
		endif;
	elseif modifier /= nullstring and modifier /= 's' then
		return()
	elseif key == "BACKSPACE" or key == "DELETE" then
		if ISactive then ISactive -> string endif;
		if datalength(string) > 0 then
			lvars p = rc_text_pointer(pic);
			rc_increment_pointer(-1, pic, string);
			if p >= datalength(string) then
				allbutlast(1, string) -> string;
			elseif p > 0  then
				substring(1, p - 1, string) <> allbutfirst(p, string) -> string
			endif
		endif
	elseif fast_lmember(key, #_< [SHIFT CAPSLOCK CONTROL ESC] >_# ) then
		;;; Ignore for now. These may be used later
		return();
	elseif key == "RETURN" or key == "ENTER" then
		consolidate_or_activate(pic);
		return();
	elseif isnumber(key) and key >= 32 and key < 127 then
		;;; insert character
		if ISactive then ISactive -> string endif;
		;;; make sure p is a number
		rc_increment_pointer(0, pic, string);
		lvars p = rc_text_pointer(pic);
		if isrc_number_input(pic)
		and (isnumbercode(key) or key == `.`)
		and not(rc_places_ok(pic, string, p, key))
		then
			'CANNOT ADD MORE DECIMAL PLACES HERE' =>
		else
			lconstant s1 = ' ';
			if p >= datalength(string) then
				consstring(#| explode(string), key |#) -> string;
			else
				key -> s1(1);
				substring(1, p, string) <> s1 <> allbutfirst(p, string) -> string
			endif;
			rc_increment_pointer(1, pic, string);
		endif;
	elseif key == "LEFT" or key == "KP_4" then
		if ISactive then ISactive -> string endif;
		rc_increment_pointer(-1, pic, string);
	elseif key == "RIGHT" or key == "KP_6" then
		if ISactive then ISactive -> string endif;
		rc_increment_pointer(1, pic, string);
	else
		'UNRECOGNIZED KEY FOR TEXT INPUT: ' sys_>< key =>
		return();
	endif;

	if recursive_valof(rc_check_text(pic))(string) then
		string -> rc_text_input_active(pic);
		rc_draw_linepic(pic);
	else
		if isrc_number_input(pic) then
			;;; make sure there's a valid number
			rc_text_string(pic) -> rc_text_input_active(pic);
			rc_draw_linepic(pic);
		endif;
		vedscreenbell();
		'INVALID INPUT: ( ' sys_>< string sys_>< ' ) PLEASE TRY AGAIN' =>
	endif

enddefine;



define :method rc_text_font (pic:rc_text_input) -> font;
	lvars
		font = RC_text_font(pic);
enddefine;

define constant update_font_specs(pic);
	lvars
		width = RC_char_width (pic);

	unless isinteger(width) then
		lvars
			height,
			win = rc_widget(rc_default_window_object);

		RC_text_font(pic) -> rc_font(win);
		;;; Use as default a wide letter. Will be accurate for fixed
		;;; fonts, and conservative for non-fixed fonts.
		XpwTextWidth(win, 'W') -> RC_char_width(pic);
		XpwFontHeight(win) ->> height -> RC_char_height(pic);
		XpwFontAscent(win) -> RC_char_ascent(pic);
		max(rc_text_height(pic), height + 4) -> rc_text_height(pic)
	endunless;
enddefine;

define :method updaterof rc_text_font(font, pic:rc_text_input);
	lvars oldfont = RC_text_font(pic);
	unless oldfont = font then
		font -> RC_text_font(pic);
		undef -> RC_char_width (pic);
	endunless;
	;;; Make sure slots are updated
	update_font_specs(pic);
enddefine;

define :method prepare_for_printing(string, pic:rc_text_input) -> string;
	;;; don't transform string;
enddefine;

define :method rc_DRAW_TEXT_INPUT(pic:rc_text_input);
	if rc_informant_value(pic) == undef then
		;;; use input string to work out value
		rc_text_value(pic) ->;
	endif;

	update_font_specs(pic);

	lvars
		xscale = abs(rc_xscale),
		yscale = abs(rc_yscale),
		(stringx, stringy) = rc_coords(pic),
	 	string = rc_text_string(pic),
		bg = rc_text_input_bg(pic),
		active_bg = rc_text_input_active_bg(pic),
		ISactive = rc_text_input_active(pic),
		fg = rc_text_input_fg(pic),
		char_w = RC_char_width(pic)/xscale,
		char_h = RC_char_height(pic)/yscale,
		char_a = RC_char_ascent(pic)/yscale,
		box_len = (rc_text_length(pic) - 1)/xscale,
		box_height = rc_text_height(pic)/yscale,
		border_width = rc_text_border_width(pic)/xscale,
		extendable = rc_text_extendable(pic),
		;

	if ISactive then
		active_bg -> bg;
		ISactive -> string;
	endif;

	lvars
		string_len = datalength(string),
		length_needed = (string_len)*char_w + 2*border_width,
		height_needed = (char_h + 2/yscale + 2*border_width);
		;

	;;; [length_needed ^length_needed extendable ^extendable]=>
	if isnumber(extendable) then extendable/xscale -> extendable endif;

	if extendable then
		;;; See if the box length needs to change
		if length_needed  > box_len then
			if isnumber(extendable) and length_needed > extendable then
				;;; over the limit. Set this amount, but extend no more.
				false -> rc_text_extendable(pic);
				extendable
			else
				length_needed
			endif -> box_len; box_len*xscale + 2 -> rc_text_length(pic)
		endif;

		if height_needed > box_height then
			height_needed  -> box_height;
			box_height*yscale -> rc_text_height(pic);
		endif;
	endif;

	lvars ycentre = (box_height / 2.0)*sign(rc_yscale);
	
	;;; Obliterate previous picture
	rc_drawline_relative(
		2/rc_xscale, ycentre , box_len*sign(rc_xscale), ycentre, bg, box_height);

	dlocal %rc_foreground(rc_window)% = rc_text_input_fg(pic);
	dlocal %rc_line_width(rc_window)% = round(border_width*xscale);
	dlocal %rc_font(rc_window)% = rc_text_font(pic);
	dlocal %rc_line_width(rc_window)% = 2;

	;;; Draw boundary, slightly to the right
	rc_draw_rect(2/rc_xscale, 0, box_len -1, box_height);
	;;; decide whether to print the whole string

	;;; fix location for drawing text, etc.
	lvars
		margin = (box_height - char_h)*0.5,		;;; margin above and below text
		text_x = (border_width + 2)/rc_xscale,
		text_y = (char_a + margin )*sign(rc_yscale);
		;;;text_y = (char_h + 2/yscale)*sign(rc_yscale);

	define do_printing(text_x, text_y, string, p, char_h, box_h) with_props do_printing;
		;;; Utility to print whole or part of string, possibly with pointer in
		;;; the middle, after p characters.

		lvars yscale=abs(rc_yscale)+0.0;

		box_h - 4/yscale -> box_h;
		if p then
			;;; need to print text before "cursor" first.

			lvars string1 = substring(1, p, string);
			rc_print_at(text_x, text_y, string1);

			;;; compute location of end of the printed text
			lvars x = (text_x + (XpwTextWidth(rc_window, string1))/rc_xscale);

			;;; Length of vertical line
			lvars h = min(box_h, (2 + char_h))*sign(rc_yscale);

			;;; draw short vertical line indicating location of pointer
			rc_drawline_relative(x, 2/rc_yscale, x, h, true, 0);

			;;; print rest of text
			rc_print_at(x+1/rc_xscale, text_y, allbutfirst(p, string));
		else
			rc_print_at(text_x, text_y, string);
		endif;
	enddefine;

	;;; Ensure pointer is up to date
	rc_increment_pointer(0, pic, string);

	;;; Now work out how much to display and where to put the pointer.
	lvars
		p = rc_text_pointer(pic),
		;;; Now compute how much of string can be shown
		max_visible = round(box_len/char_w) - 1;

	;;; [max_visible ^max_visible box_len ^box_len char_w ^char_w]=>	
	;;; Draw the text with location pointer
	if extendable == true or length_needed <= box_len
	then
		do_printing(text_x, text_y, string, ISactive and p, char_h, box_height);
	else
		;;; find out if pointer is within truncated length from beginning
		if p + 2 < max_visible then
			;;; show only max_visible characters from the beginning
		elseif p = string_len or p + 1 = string_len then
			lvars chop = string_len - max_visible;
			allbutfirst(chop, string) -> string;
			p - chop -> p;
		else
			lvars chop = p + 2 - max_visible;
			if string_len > chop then
				allbutfirst(chop, string) -> string;
				max_visible - 2 -> p;
			endif;
		endif;
		;;; remove stuff from far end
		if datalength(string) > max_visible then
			substring(1, max_visible, string) -> string;
		endif;
		;;;
		do_printing(text_x, text_y, string, ISactive and p, char_h, box_height);
	endif;

	;;; Update size of sensitive area
	;;; MUST be a vector
	lvars
		vec = recursive_valof(rc_mouse_limit(pic)),
		(x1, y1, x2, y2) = explode(vec);

		max(abs(x2), rc_text_length(pic)/xscale)*sign(rc_xscale) -> vec(3);
		if rc_yscale < 0 then
			min(y1, -(char_h + 2)) -> vec(2)
		else
			max(abs(y1), abs(char_h + 2)) -> vec(2)
		endif;

enddefine;

define :method rc_SHOW_TEXT_LABEL(pic:rc_text_input);

	dlocal
		%rc_font(rc_window)%,
		%rc_foreground(rc_window)%,
	;
	
	lvars string = rc_label_string(pic);
	
	returnif(string == nullstring);	;;; no string to draw

	;;; Set up label font and label colour if necessary
	unless rc_font(rc_window) = rc_label_font(pic) then
		rc_label_font(pic) -> rc_font(rc_window)
	endunless;

	unless rc_foreground(rc_window) = rc_label_colour(pic) then
		rc_label_colour(pic) -> rc_foreground(rc_window)
	endunless;

	;;; Now work out how to print the label
	lvars
		yscale = abs(rc_yscale),
		textw = (XpwTextWidth(rc_window, string))/rc_xscale,
		textascent = XpwFontAscent(rc_window)/yscale,
		texth = XpwFontHeight(rc_window)/yscale,
		height = rc_text_height(pic)/yscale,
		bwidth = rc_text_border_width(pic)/yscale,
		margin = (height - texth)*0.5

		;

	;;; rc_print_at(-textw, height/2.0 + textdescent/sign(rc_yscale), string);
	rc_print_at(-textw, (margin + textascent)*sign(rc_yscale), string);


enddefine;


/*
define -- Class definitions and creation procedures
*/

define :class vars rc_text_button; is rc_text_input;
	;;; The basic text input field
enddefine;

define :class vars rc_number_button; is rc_number_input;
	slot rc_text_string = '0';
enddefine;


;;; this can be a temporary replacement for featurespec_abbreviation
;;; used by interpret_specs
define vars rc_textin_field_abbreviations =
	newproperty(
		[
			[labelstring rc_label_string]
			[label rc_label_string]
			[font rc_text_font]
			[labelfont rc_label_font]
			[labelcolour rc_label_colour]
			[fg rc_text_input_fg]
			[textinfg rc_text_input_fg]
			[bg       rc_text_input_bg]
			[textingb  rc_text_input_bg]
			[activebg rc_text_input_active_bg]
			[ident rc_informant_ident]
			[constrain rc_constrain_contents]
			[places rc_pr_places]], 16, false, "perm")
enddefine;


define create_text_input_field(x, y, width, height, content, extendable, font, creator) -> field;
	dlocal
		featurespec_abbreviation = rc_textin_field_abbreviations,
		rc_text_font_def = font,
		rc_text_length_def = width,
		rc_text_height_def = height;

	creator() -> field;

	rc_current_window_object -> rc_informant_window(field);

	(x,y) -> rc_coords(field);
	extendable -> rc_text_extendable(field);

	;;; drawing will take account of the font, and may change height
	;;; and length

	lvars rest, value, labelcoords;
	if islist(content) then
		dest(content) ->(value, rest);
		lvars item, ok = false;;
		;;; interpret the rest of the spec.
		for item in rest do
			;;; Veddebug([item ^item]);
			if isvector(item) then
				lvars vlen = datalength(item);
				if vlen == 2 then
					true -> ok;
					lvars (key, val)= explode(item);
					if key == "specs" then
						interpret_specs(field, val)
					else interpret_specs(field, item)
					endif;
				elseif vlen mod 2 == 0 then
					true -> ok;
					;;; a vector of even length
					interpret_specs(field, item)
				else ;;; not OK
				endif;
			endif;
			unless ok then
				mishap('UNRECOGNISED SPEC FOR INPUT FIELD', [^item ^content])
			endunless;
		endfor;
	else
		content -> value;
	endif;

	;;; possibly replace value with value of identifier
	if value = nullstring or value = undef or isundef(value) then
	    lvars
		    id = rc_informant_ident(field);
	    if id and not(isundef(valof(id))) then
		    valof(id) -> value;
	    endif;
	endif;

	value -> rc_informant_value(field);

	rc_draw_linepic(field);

	rc_text_length(field) -> width;
	rc_text_height(field) -> height;

	;;; Assign default sensitive area. May be adjusted.
	{%0, (2+height)/rc_yscale, width/rc_xscale, 0 %} -> rc_mouse_limit(field);

	;;; make sure the window is keyboard sensitive
	rc_mousepic(rc_current_window_object, #_< [keyboard button] >_#);
	;;; tell window about this text input field
	rc_add_pic_to_window(field, rc_current_window_object, true);
enddefine;


define create_input_field(x, y, width, height, content, extendable, font, proc) -> field;
	;;; this will create either a number or a text input field depending
	;;; on the content argument. The proc argument should take in the newly created
	;;; object, do what ever it has to do and return that object.
	lvars creator = newrc_text_button;
	if isnumber(content)
	or islist(content) and isnumber(hd(content))
	then
		newrc_number_button -> creator;
	endif;
	create_text_input_field(x, y, width, height, content, extendable, font, creator<>proc) -> field;
enddefine;
	

vars rc_text_input = true;	;;; for uses

endsection;

nil -> proglist;

/*
         CONTENTS - (Use <ENTER> g define to access required sections)

 define vars rc_text_input_disabled(key, modifier);
 define :mixin vars rc_text_input;
 define :mixin vars rc_number_input; is rc_text_input;
 define constant transform_places(num, places)->num;
 define :method prepare_for_printing(num, pic:rc_number_input) -> num;
 define :method updaterof rc_informant_value(newval, pic:rc_text_input);
 define :method updaterof rc_informant_value(val, pic:rc_number_input);
 define :method rc_text_value(pic:rc_text_input) -> val;
 define :method updaterof rc_text_value(newval, pic:rc_text_input);
 define :method constant consolidate_or_activate(pic:rc_text_input);
 define :method rc_button_1_down(pic:rc_text_input, x, y, modifiers);
 define :method print_instance(pic:rc_text_input);
 define :method constant consolidate_or_activate(pic:rc_number_input);
 define :method print_instance(pic:rc_number_input);
 define rc_convert_number_in(number) -> string;
 define rc_convert_number_out(string) -> number;
 define rc_check_number_format(string) -> boole;
 define :method rc_text_altered(pic:rc_text_input, val);
 define :method rc_text_altered(pic:rc_number_input, val);
 define constant rc_increment_pointer(num, pic, string);
 define constant rc_places_ok(pic, string, p, key) -> boole;
 define :method rc_handle_text_input(pic:rc_text_input, x, y, modifier, key);
 define :method rc_text_font (pic:rc_text_input) -> font;
 define constant update_font_specs(pic);
 define :method updaterof rc_text_font(font, pic:rc_text_input);
 define :method prepare_for_printing(string, pic:rc_text_input) -> string;
 define :method rc_DRAW_TEXT_INPUT(pic:rc_text_input);
 define :method rc_SHOW_TEXT_LABEL(pic:rc_text_input);
 define -- Class definitions and creation procedures
 define :class vars rc_text_button; is rc_text_input;
 define :class vars rc_number_button; is rc_number_input;
 define vars rc_textin_field_abbreviations =
 define create_text_input_field(x, y, width, height, content, extendable, font, creator) -> field;
 define create_input_field(x, y, width, height, content, extendable, font, proc) -> field;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 14 2002
		used recursive_valof on result of rc_mouse_limit
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 30 2002
		Added uses interpret_specs
--- Aaron Sloman, Aug 25 2002
    replaced rc_informant_contents with rc_informant_value

--- Aug 10 2002
		Extended formats to allow spec vectors with multiple attribute value items.
--- Aug  3 2002
		create_input_field(x, y, width, height, content, extendable, font, proc) -> field;
		this will create either a number or a text input field depending
		on the content argument.
--- Aug  2 2002
	Changed to use rc_textin_field_abbreviations table instead of inline code.
--- Jul 28 2002
		Minor redeclaration of slot
--- Aaron Sloman, Oct 10 1999
	Made updaters switch to the appropriate window object
--- Aaron Sloman, Apr 11 1999
	Fixed anomaly arising from previous bug-fix!
--- Aaron Sloman, Apr  8 1999
	Fixed bug when places == 0
--- Aaron Sloman, Apr  7 1999
	Allowed "activebg" in contents list
--- Aaron Sloman, Apr  6 1999
	Altered to ensure that a valid number value remains in numberin text
	string after errors.
--- Aaron Sloman, Apr  2 1999
	Made text panel use variable value if appropriate
	fixed updater of rc_informant_value to update text value
	Included rc_pr_places in rc_number_input
	Allowed input checking to use "round" constraint or rc_pr_places

--- Aaron Sloman, Mar 30 1999
	Changed to allow negative numbers!
--- Aaron Sloman, Mar 29 1999
	Reorganised to make better use of rc_informant facilities
--- Aaron Sloman, 26 Mar 1999
	replaced rc_constrain*_number slot with rc_constrain_contents
--- Aaron Sloman, Mar 24 1999
	Introduced rc_constrain*_number slot in number input fields, and "constrain" key
--- Aaron Sloman, Mar 23 1999
	Introduced support for rc_informant_ident, via method rc_information_changed
--- Aaron Sloman, Mar 21 1999
	Fixed rc_check_number_format to allow more of the formats specified
	in REF * ITEMISE
--- Aaron Sloman, Mar 21 1999
	Changed printing methods to be more helpful
--- Aaron Sloman,
Aug 19 1997
	Introduced user definable rc_text_input_disabled(key, modifier);
 */
