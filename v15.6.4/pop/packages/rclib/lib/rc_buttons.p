/* --- Copyright University of Birmingham 2004. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_buttons.p
 > Purpose:			Create control panels for VED utilities.
 > Author:          Aaron Sloman, Jan  4 1997 (see revisions)
 > Documentation:	TEACH RCLIB_DEMO.P, TEACH RC_CONTROL_PANEL
					HELP RC_BUTTONS
 > Related Files:	LIB * RCLIB, LIB * RC_BUTTON_UTILS
 */


/*
;;; For more tests See
	HELP * RC_BUTTONS
	HELP * RC_CONTROL_PANEL
;;; LIB * RC_POLYPANEL


rc_kill_window_object(win1);
rc_kill_window_object(win2);
rc_kill_window_object(win3);
vars win1 = rc_new_window_object( 650, 20, 350, 350, true, newrc_button_window, 'win1');
vars win2 = rc_new_window_object( 650, 20, 450, 450, {30 200 -1.5 1.5}, newrc_button_window, 'win2');
vars win3 = rc_new_window_object( 650, 20, 450, 450, {225 225 1.5 -1.5}, newrc_button_window, 'win3');

rc_event_types(win1) =>

rc_drawline(-50,150,200,150);
rc_drawline(-50,150-29,200,150-29);
rc_drawline(0,120, 10, 120);
rc_drawline(5,200, 5, 0);

rc_draw_blob(0, 100, 5, 'red');

rc_start();

;;; test invisible action button, with visible string.
vars button1 =
	create_rc_button(
		0, 150, 60, 29,
			['Press me' [POP11 'hello' =>]], "invisible", false);

rc_undraw_button(button1);
rc_start();

;;; Another invisible button with long vertical active area
vars button2 =
	create_rc_button(
		0, 120, 10, 300,
			[^nullstring [POP11 'HELLO' =>]], "invisible", false);

button2.rc_mouse_limit =>
{0 0 20 -20} -> rc_mouse_limit(button1);
rc_coords(button1) =>

untrace rc_draw_button_type;

rc_start();

;;; lmm

vars
	counter = 22, digit = 8,
	sbc1 = create_rc_button(-16, 140, 150, false, ['Memlim' popmemlim 10000], "counter" , [])
,
	sbc2 = create_rc_button(-16, 100, 150, false, ['Linemax' poplinemax {1 50 90}], "counter", []),
	sbc3 = create_rc_button(-16, 60, 150, false, ['Counter' counter {1 20}], "counter", []),
	sbc4 = create_rc_button(-16, 20, 150, false, ['Digit' ^(ident digit) {1 ^false 9}], "counter", []),
	sbc5 = create_rc_button(-16, -20, 150, 30, [popgctrace ^(ident popgctrace) {textbg 'grey85'}], "toggle", [{textfg 'blue'}]),
	sbc6 = create_rc_button(-16, -60, 150, false, {counter 'Count' ^(ident counter) {1 0 30} {textbg 'yellow' textfg 'blue' blobrad 16 height 40}}, "counter", []),
;;;	sbc7 = create_rc_button(-16, -105, 150, false, {counter 'Count' ^(ident counter) {1 0 30} {textbg 'pink' textfg 'blue' blobrad 10 height 40 blobcol 'blue'}}, "counter", [{blobrad 20 blobcol 'blue'}]),
	sbc7 = create_rc_button(-16, -105, false, false, {counter 'Count' ^(ident counter) {1 0 30} {textbg 'pink' textfg 'blue' height 46 }}, "counter", {width 180 blobrad 20 blobcol 'yellow'}),
;

sbc7.rc_button_blobrad =>


popmemlim =>
poplinemax =>

popmemlim -10000 -> rc_button_value(sbc1);
77 -> rc_button_value(sbc2);

rc_undraw_button(sbc1);
rc_undraw_button(sbc2);
rc_undraw_button(sbc3);
rc_undraw_button(sbc4);
rc_undraw_button(sbc5);
rc_undraw_button(sbc6);
rc_undraw_button(sbc7);

rc_drawline(-250,140,200,140);
rc_drawline(-250,140-rc_button_height_def,200,140-rc_button_height_def);

rc_drawline(-250,100,200,100);
rc_drawline(-250,100-rc_button_height_def,200,100-rc_button_height_def);
*/

uses rclib
uses rc_defaults
uses rc_window_object
uses rc_linepic
uses rc_mousepic
uses rc_informant


;;; These two are not strictly necessary. Included for backward compatibility
uses rc_kill_panel
uses rc_hide_panel

section;

;;; compile_mode :pop11 +strict;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;


/*
define -- New class of window object (rc_button_window)
This can be given special information about dealing with buttons.
*/

;;; variable used in rc_control_panel
global vars rc_redrawing_panel = false;

define :class vars rc_button_window; is rc_window_object;
	;;; windows that can include buttons
enddefine;

define :method rc_realize_window_object(win_obj:rc_button_window);
	;;; Make sure this is sensitised if ever it is realised
	call_next_method(win_obj);
	rc_mousepic(win_obj, #_< [button] >_#);
enddefine;


/*
define -- Globals holding default values for button appearance

These defaults are used as default slot values for various classes.

They can be overridden in subclasses, and also dlocally overridden
in procedurs, etc.

*/

define :rc_defaults;

	;;; total height of button
	rc_button_height_def = 24;

	;;; total length of button
	rc_button_width_def = 120;

	;;; default border width
	rc_button_border_def = 3;

	;;; standard font for label
	rc_button_font_def =
		'-adobe-helvetica-bold-r-normal-*-10-*-*-*-p-*-*-*';
		;;; Other possibilities '9x15'; '8x13';
		;;; '*lucida*-r-*sans-10*';

	;;; colour of text label
	rc_button_stringcolour_def = 'black';

	;;; make this non-zero to get a blob on action button
	rc_button_blobrad_def = 0;

	;;; If there's a blob to left of label use this colour
	rc_button_blobcolour_def = 'grey50';

	;;; This is "blob" size for "display" buttons, e.g.	
	;;; e.g. toggle, counter, radio, someof buttons
	rc_button_default_blobrad = 5;

	;;; colour of border
	rc_button_bordercolour_def = 'grey60';

	;;; colour of border of action button when pressed
	rc_button_pressedcolour_def = 'grey75'; ;;;'lightsalmon'; ;;; 'linen' ; ;;;'LightGrey';

	;;; colour of background to label
	rc_button_labelground_def = 'white';

	;;; background colour for option button when pressed
	rc_button_chosenground_def = 'grey75';

	;;; Toggle button shows true or false using one of these labels
	;;; can easily be replaced with another pair of strings.
	rc_toggle_labels_def = {' (T)' ' (F)'};

	;;; Counter buttons show the number between brackets. Use
	;;; these as default
	rc_counter_brackets_def = {'[' ']'};

	;;; Make this false to prevent attempts to redirect output
	;;; when action buttons cause printing
	;;; replaced by synonym below
	;;;; async_vedbuffer = rc_charout_buffer;

enddefine;

;;; for backward compatibility.
syssynonym("async_vedbuffer", "rc_charout_buffer");

/*
define -- rc_button and rc_display_button mixins
*/

;;; Define the main mixin for button objects

define :mixin vars rc_button;
    is rc_linepic, rc_selectable, rc_informant;
	slot rc_button_label = '??Label??';
	slot rc_button_height = rc_button_height_def;
	slot rc_button_width = rc_button_width_def;
	slot rc_button_border = rc_button_border_def ;
	slot rc_button_font = rc_button_font_def ;
	slot rc_button_stringcolour = rc_button_stringcolour_def;
	slot rc_button_bordercolour = rc_button_bordercolour_def;
	slot rc_button_labelground = rc_button_labelground_def;
	slot rc_button_blobrad = 0;
	;;; next slot removed 29 Mar 1999 because of changes in
	;;; lib rc_informant

	;;; Not needed. Inherits from rc_informant
	;;; slot rc_informant_value

	;;; Sensitivity rectangle for buttons
	;;; This needs to be kept consistent with height and width of button
	slot rc_mouse_limit =
		{%rc_button_border_def/rc_xscale, rc_button_border_def/rc_yscale,
		(rc_button_width_def-rc_button_border_def)/rc_xscale,
		(rc_button_height_def-rc_button_border_def)/rc_yscale%};

	;;; This specifies the drawing procedure to be used
	;;; Previously "rc_DRAWBUTTON". Changed 14 Jun 2000
	slot  rc_pic_lines == "rc_draw_button";

	slot rc_button_up_handlers =
		{ rc_rcbutton_1_up rc_button_do_nothing rc_button_do_nothing};
	slot rc_button_down_handlers =
		{ rc_rcbutton_1_down rc_button_do_nothing rc_button_do_nothing};
	slot rc_drag_handlers =
		{rc_button_do_no_drag rc_button_do_no_drag rc_button_do_no_drag };
	slot rc_move_handler = "rc_button_do_nothing";
	slot rc_button_container == undef;
enddefine;


;;; This is used for toggle, counter, radio and someof buttons

define :mixin vars rc_display_button;
	;;; No longer has a border: has a square or blob to left of label
	;;; square for counter and toggle buttons.
	;;; blob for someof and radio buttons
	slot rc_button_labelground = 'grey95';
	slot rc_button_blobcolour = rc_button_blobcolour_def;
	slot rc_button_blobrad = rc_button_default_blobrad;
enddefine;


/*
define -- The main button classes: action, blob, toggle,etc.
*/

define :class vars rc_action_button; is rc_button;
	slot rc_button_action = identfn;
	slot rc_button_pressedcolour = rc_button_pressedcolour_def;
enddefine;

define :class vars rc_invisible_action_button; is rc_action_button;
	;;; This needs to be kept consistent with height and width
	;;; Default box below and to right of button location.
	slot  rc_mouse_limit = {0 0 20 -20};
	slot rc_drag_handlers = {rc_drag_invisible ^false ^false};
enddefine;

define :class vars rc_blob_button; is rc_action_button;
	;;; for action buttons with blob on left.
	slot rc_button_blobcolour = rc_button_blobcolour_def;
	slot rc_button_blobrad = rc_button_blobrad_def;
enddefine;


define :class vars rc_toggle_button; is rc_display_button rc_button;
	;;; These are buttons with an extra boolean field
	slot RC_informant_value = false;
	;;; NB the same vector is shared by all instances.
	;;; So make a copy if some are to have different toggle_labels.
	slot rc_toggle_labels = rc_toggle_labels_def;
enddefine;

define :class vars rc_counter_button; is rc_display_button rc_button;
	;;; These are buttons with a number and an increment.
	;;; Clicking with button 1 increases the number by the increment.
	;;; Clicking with button 3 decreases it.
	;;; Removed rc_counter_value 29 Mar 1999

	slot rc_counter_inc = undef;
	slot rc_counter_min = false;
	slot rc_counter_max = false;
	;;; the number will be printed inside these values
	slot rc_counter_brackets = rc_counter_brackets_def;
	slot rc_button_down_handlers ==
		{ rc_rcbutton_1_down rc_button_do_nothing rc_rcbutton_3_down };
	slot rc_original_label = false;
enddefine;

define :class vars rc_option_button; is rc_display_button rc_button;
	;;; These are buttons to be used in an array of options, where
	;;; any subset of the options can be selected or unselected
	slot RC_informant_value == false;
	slot rc_real_contents == false;
	slot rc_chosen_background = rc_button_chosenground_def;
enddefine;

define :class vars rc_radio_button; is rc_option_button;
	;;; These are buttons to be used in an array of options, where
	;;; choosing one option undoes the choice of a different option
	slot rc_radio_list = [];	;;; list of sibling buttons
	slot rc_radio_select_action = erase;
	slot rc_radio_deselect_action = erase;
enddefine;

define :class vars rc_someof_button; is rc_radio_button;
	;;;  Allow any number in the list to be turned on
	;;; will have slightly different methods
enddefine;


/*
define -- Utility methods
*/

define :method rc_move_to(pic:rc_button, x, y, trail);
	;;; do nothing cannot be moved. Should give an error?
	['WARNING: Attempt to move button' ^pic ] =>
enddefine;

/*
define -- generic button methods for values/contents, etc.
*/


;;; When updating the value of a button the informant methods will
;;; be triggered. We need to prevent this during button creation.
global vars rc_creating_button = false;	;;; made true in create_rc_button

define lconstant DEREF(item) -> item;
	if isword(item) or isident(item) then valof(item) else item
	endif -> item;
enddefine;

define :method rc_button_value(pic:rc_display_button) -> val;
	lvars val = DEREF(rc_informant_value(pic));
enddefine;

define :method updaterof rc_button_value(val, pic:rc_display_button);
	val -> rc_informant_value(pic);
enddefine;

lvars in_rc_button_value = false;

define :method updaterof rc_button_value(val, pic:rc_radio_button);

	dlocal in_rc_button_value;
	if in_rc_button_value then
		val -> rc_informant_value(pic);
	else
        true -> in_rc_button_value;
		
		lvars
			oldval = rc_button_value(pic);

			returnif(val == oldval);

			;;; update and if necessary inform siblings.

		if isrc_someof_button(pic) or val == true then
     		;;; this saves having to pre-declare the method, defined below
			valof("rc_rcbutton_1_down")(pic, 0,0,nullstring);
		else

			;;; turn off the only true radio button
			val -> rc_informant_value(pic);
			rc_draw_linepic(pic);
			;;; now see if associated identifier has to be turned off
			lvars wid = rc_informant_ident(pic);
			if isword(wid) or isident(wid) then
				undef -> valof(wid)
			endif;
		endif;
	endif;
enddefine;


;;; This method is not really needed. Kept for backward compatibility
define :method rc_toggle_value(pic:rc_toggle_button);
	rc_informant_value(pic);
enddefine;

define :method updaterof rc_toggle_value(val, pic:rc_toggle_button);
	val -> rc_informant_value(pic);
enddefine;

;;; This method is not really needed. Kept for backward compatibility
define :method rc_counter_value(pic:rc_counter_button);
	rc_informant_value(pic);
enddefine;

define :method updaterof rc_counter_value(val, pic:rc_counter_button);
	val -> rc_informant_value(pic);
enddefine;


;;; This method is not really needed. Kept for backward compatibility
;;; used in rc_popup_query. Fix !! (use rc_informant_value ?)
define :method rc_option_chosen(pic:rc_option_button);
	rc_informant_value(pic);
enddefine;

define :method updaterof rc_option_chosen(val, pic:rc_option_button);
	val -> rc_informant_value(pic);
enddefine;

;;; When updating the value of a button the informant methods will
;;; be triggered. We need to prevent this during button creation.

define :method updaterof rc_informant_value(val, button:rc_display_button);

	call_next_method(val, button);

	unless rc_creating_button then
		rc_draw_linepic(button);
	endunless;

	rc_information_changed(button);	;;; May do nothing
enddefine;


define :method updaterof rc_informant_value(val, button:rc_counter_button);

	call_next_method(val, button);

	unless rc_creating_button then
		rc_draw_linepic(button);
	endunless;

	rc_information_changed(button);	;;; May do nothing
enddefine;


/*
define -- Some dummy methods for buttons with missing slots
(for harmless use in spec vectors).
These all have updaters that just pick up the item and do nothing.

Should probably be done differently.
*/

define :method updaterof rc_button_pressedcolour(x, pic:rc_button);
enddefine;

define :method updaterof rc_button_blobcolour(x, pic:rc_button);
enddefine;

define :method updaterof rc_button_blobrad(x, pic:rc_button);
enddefine;

define :method updaterof rc_counter_brackets(x, pic:rc_button);
enddefine;

define :method updaterof rc_toggle_labels(x, pic:rc_button);
enddefine;

define :method updaterof rc_chosen_background(x, pic:rc_button);
enddefine;

define :method updaterof rc_radio_select_action(x, pic:rc_button);
	;;; May be unnecessary
enddefine;

define :method updaterof rc_radio_deselect_action(x, pic:rc_button);
	;;; May be unnecessary
enddefine;


/*
define -- Utility methods and procedures
*/

define :method print_instance(pic:rc_button);
	lvars label = rc_button_label(pic);
	;;; show strings as strings
	dlocal pop_pr_quotes = true;
    printf('<rc_button %P>', [%label%])
enddefine;

define :method print_instance(pic:rc_display_button);
	lvars label = rc_button_label(pic);
	;;; show strings as strings
	dlocal pop_pr_quotes = true;
    printf('<display_button %P %P>', [%label, rc_informant_value(pic)%])
enddefine;

define :method print_instance(pic:rc_counter_button);
	lvars label = rc_button_label(pic);
	;;; show strings as strings
	dlocal pop_pr_quotes = true;
    printf('<counter_button %P %P>', [%label, rc_informant_value(pic)%])
enddefine;


define :method print_instance(pic:rc_toggle_button);
	lvars label = rc_button_label(pic);
	;;; show strings as strings
	dlocal pop_pr_quotes = true;
    printf('<toggle_button %P %P>', [%label, rc_informant_value(pic)%])
enddefine;

define :method print_instance(pic:rc_radio_button);
	lvars label = rc_button_label(pic);
	;;; show strings as strings
	dlocal pop_pr_quotes = true;
    printf('<radio_button %P %P>', [%label, rc_informant_value(pic)%])
enddefine;


define :method print_instance(pic:rc_someof_button);
	lvars label = rc_button_label(pic);
	;;; show strings as strings
	dlocal pop_pr_quotes = true;
    printf('<someof_button %P %P>', [%label, rc_informant_value(pic)%])
enddefine;





define :method print_instance(pic:rc_action_button);
	lvars label = rc_button_label(pic);
	;;; show strings as strings
	dlocal pop_pr_quotes = true;
    printf('<action_button %P>', [%label%])
enddefine;

;;; Could do this for others

/*
define -- Drawing methods and procedures for buttons
*/

define lconstant DRAW_OB(x, y, xinc, yinc, width, height, border, radius, colour);
	;;; Drawing oblongs, for borders. All measures absolute except x,y

	dlocal
		%rc_foreground(rc_window)% = colour,
		%rc_line_width(rc_window)% = border;

	;;; rc_transxyout(x+xinc*sign(rc_xscale), y+yinc*sign(rc_yscale)) -> (x, y);
	rc_transxyout(x+xinc/rc_xscale, y+yinc/rc_yscale) -> (x, y);
	round(abs(width)) -> width;
	round(abs(height))  -> height;
	round(abs(radius))  -> radius;

	XpwDrawRoundedRectangle(
		rc_window,
		x,
		y,
		width,
		height,
		radius,
		radius)
enddefine;

define :method rc_draw_border_shape(pic:rc_button, x, y, width, height, border, halfborder, colour);
	DRAW_OB(x, y, halfborder, halfborder, width-border, height-border, border, border, colour);
enddefine;


define :method rc_draw_border(pic:rc_button, colour);
	;;; This is used to draw and redraw the border (e.g. when button pressed)
	;;; Assume the local coordinate
	;;; frame for pic has already been set.
	lvars
		border = rc_button_border(pic),
		halfborder = intof(border*0.5),
		height = rc_button_height(pic),
		width = rc_button_width(pic);
		
	;;; Draw the border as an oblong, or rectangle, or,...
	rc_draw_border_shape(pic, 0, 0, width, height, border, halfborder, colour);

enddefine;


define :method rc_draw_border(pic:rc_invisible_action_button, colour);
	;;; do nothing
enddefine;

define :method rc_setframe_draw_border(pic:rc_button, colour);
	;;; Set the pic's local coordinate frame and then draw the border
	lvars pic;
	dlocal
		rc_xorigin = rc_xorigin + rc_xscale*rc_picx(pic),
		rc_yorigin = rc_yorigin + rc_yscale*rc_picy(pic);

	rc_draw_border(pic, colour);
enddefine;

define :method rc_setframe_draw_border(pic:rc_invisible_action_button, colour);
	;;; do nothing for invisible actions.
enddefine;

;;; Stuff for drawing blobs of various kinds
define :method rc_draw_button_type(pic:rc_display_button, blobrad, height, colour);

	lvars square_size = blobrad*2/abs(rc_xscale);

	;;; [blobrad ^blobrad]=>

	rc_draw_centred_rect(
		(blobrad + 2)/rc_xscale, (height div 2)/rc_yscale,
		square_size, square_size, colour, 3);
enddefine;

define :method rc_draw_button_type(pic:rc_radio_button, blobrad, height, colour);
	rc_draw_blob(
		(blobrad + 1)/rc_xscale, (height div 2)/rc_yscale,
		blobrad/abs(rc_xscale), colour);
enddefine;

define :method rc_draw_button_type(pic:rc_someof_button, blobrad, height, colour);
	rc_drawline_relative(
		1/rc_xscale, (height div 2)/rc_yscale,
		blobrad*2/rc_xscale, (height div 2)/rc_yscale,
		colour, blobrad*2/abs(rc_yscale));
enddefine;



define :method rc_offset_print_button_label(pic:rc_button, stringx, stringy, label);
	rc_print_at(stringx, stringy, label);
enddefine;

define :method rc_offset_print_button_label(pic:rc_display_button, stringx, stringy, label);
	rc_print_at(stringx, stringy, label);
enddefine;

define :method rc_offset_print_button_label(pic:rc_invisible_action_button, stringx, stringy, label);
	rc_print_at(stringx, stringy, label);
enddefine;

define :method rc_string_offset(pic:rc_button, border, blob_rad) -> offset;
	(border + blob_rad)*2 -> offset;
	;;; in case there is a blob, add some extra space before label
	if blob_rad /== 0 then offset + 2 -> offset endif;
enddefine;

define :method rc_string_offset(pic:rc_display_button, border, blob_rad) -> offset;
	(blob_rad*2)+5 -> offset;
enddefine;

define :method rc_draw_button_string(pic:rc_button, blob_rad, border, width, height);
	;;; draw the string
	lvars
		label = rc_button_label(pic),
		font = rc_button_font(pic),
		string =
				;;; get the label to print
				if islist(label) or isvector(label) then label(1)
				;;; elseif isstring(label) or isword(label) or isnumber(label) then
				;;;	label
				else
					;;; ??? mishap('Word, String, List or Vector needed', [^label])
					label
				endif,
		;;; start x coordinate for string
		stringx = rc_string_offset(pic, border, blob_rad)/rc_xscale,
		( _ , stringheight, _, descend) = rc_font_dimensions(font, nullstring),
		halfstringheight = stringheight*0.5,
		stringbase = height*0.5 + halfstringheight - descend,
		stringy = round(stringbase)/rc_yscale,    ;;; start y coordinate
		;

	dlocal
		%rc_font(rc_window)% = font,
		%rc_foreground(rc_window)% = rc_button_stringcolour(pic);

	unless isstring(string) then
		string sys_>< nullstring -> string
	endunless;

	rc_offset_print_button_label(pic, stringx, stringy, string);
enddefine;

define :method rc_draw_border_or_blob(pic:rc_button);
	;;; draw the border for buttons that have one
	rc_draw_border(pic, rc_button_bordercolour(pic));
enddefine;

define :method rc_draw_button_blob(pic:rc_display_button);
	;;; Previously drew a border made of two nested rectangles
	;;; Now draws a square or blob to left of button label
	lvars
		blobrad = rc_button_blobrad(pic),
		height = rc_button_height(pic),
		colour = rc_button_blobcolour(pic);

	rc_draw_button_type(pic, blobrad, height, colour);
enddefine;

define :method rc_draw_border_or_blob(pic:rc_display_button);
	;;; draw the blob for display buttons e.g. toggle,counter,
	;;; someof, radio
	rc_draw_button_blob(pic);
enddefine;

define :method draw_action_blob(pic:rc_button, mid, border, blob_rad);
	;;; If necessary draw the blob, if non-zero radius
	if blob_rad > 0 then
		lvars scale = (abs(rc_xscale) + abs(rc_yscale))*0.5;
		rc_draw_unscaled_blob(
			;;; need to (de-)scale x and y coords, not radius
			(blob_rad + 1 + border)/rc_xscale,
			mid/rc_yscale,
			round(blob_rad),
			rc_button_blobcolour(pic));
	endif;
enddefine;

define :method rc_draw_button_background(pic:rc_button, mid, border, blob_rad, width, height);
	;;; draw the background for a buton

	;;; Draw a horizontal coloured rectangle as the background
	rc_drawline_relative(
		(2 + border div 2)/rc_xscale, mid/rc_yscale,
		(width-(border div 2) - 2)/rc_xscale, mid/rc_yscale,
		rc_button_labelground(pic),
		abs((height - border - 2)/rc_yscale));

	;;; If necessary draw the blob
	draw_action_blob(pic, mid, border, blob_rad);

enddefine;


define :method rc_draw_button_background(pic:rc_display_button, mid, border, blob_rad, width, height);
	;;; draw the background for a button, using absolute values

	rc_drawline_relative(
		0, mid/rc_yscale,
		width/rc_xscale, mid/rc_yscale,
		rc_button_labelground(pic),
		abs(height/rc_yscale) );

enddefine;



define :method rc_draw_button(pic:rc_button);
	;;; Previously invoked from rc_DRAWBUTTON, inside rc_draw_linepic
	;;; Draw a button by drawing its background, then the border,
    ;;; then the label
	lvars
		border = abs(rc_button_border(pic)),
		height = rc_button_height(pic),
		width = rc_button_width(pic),
		mid = round(height*0.5),		;;; y coord of mid line
		blob_rad = abs(rc_button_blobrad(pic)),
		;

	;;;; [Button w ^width h ^height b ^border mid ^mid stringx ^stringx stringy ^stringy] =>

	rc_draw_button_background(pic, mid, border, blob_rad, width, height);

	;;; Draw the border or blob
	rc_draw_border_or_blob(pic);

	;;; Now the label
	rc_draw_button_string(pic, blob_rad, border, width, height);

enddefine;

define :method rc_draw_button(pic:rc_invisible_action_button);
	;;; invoked from rc_DRAWBUTTON, inside rc_draw_linepic
	;;; Draw only the label
	lvars
		border = abs(rc_button_border(pic)),
		height = rc_button_height(pic),
		width = rc_button_width(pic),
		blob_rad = abs(rc_button_blobrad(pic)),
		;

	;;; Now the label
	rc_draw_button_string(pic, blob_rad, border, width, height);

enddefine;

;;; Should there be be an undraw method for the above also?

define :method rc_draw_button(pic:rc_toggle_button);
	lvars
		item = rc_informant_value(pic),
		vec = rc_toggle_labels(pic),
		oldlabel = rc_button_label(pic),
		val, label,
		;
	lconstant tests = [^isboolean ^isword ^isident];
	check_item(item, tests, false);

	if isboolean(item) then item -> val
	else
		;;; isword(item) or isident(item)
		valof(item) -> val
	endif;

	;;; get item to be shown on button (e.g. [T], or [F])
	;;; temporarily make it part of the label for the drawing method
	if val then vec(1) else vec(2) endif -> label;

	oldlabel sys_>< label -> rc_button_label(pic);

	call_next_method(pic);

	oldlabel -> rc_button_label(pic);
enddefine;



;;; now redundant. Left for compatibility
define vars rc_DRAWBUTTON(pic);
	;;; Value of rc_pic_lines slot for buttons, invoked by
	;;; rc_draw_linepic
	rc_draw_button(pic);
enddefine;

/*
define -- Undrawing methods for buttons
*/

define :method rc_undraw_button_background(pic:rc_button, mid, border, blob_rad, width, height);
	;;; draw the background for a button to remove it

	rc_drawline_relative(
		0, mid/rc_yscale,
		;;;(width-(border div 2) - 2)/rc_xscale, mid/rc_yscale,
		width/rc_xscale, mid/rc_yscale,
		"background",
		abs((height+border*0.5)/rc_yscale));

enddefine;

define :method rc_undraw_button(pic:rc_button);
	lvars
		border = abs(rc_button_border(pic)),
		height = rc_button_height(pic),
		width = rc_button_width(pic),
		mid = round(height*0.5),		;;; y coord of mid line
		blob_rad = abs(rc_button_blobrad(pic)),
		;

	lvars oldxorigin = rc_xorigin, oldyorigin = rc_yorigin;

	dlocal
		0 % , if dlocal_context fi_< 3 then
				oldxorigin -> rc_xorigin;
				oldyorigin -> rc_yorigin;
				endif%;

	rc_xorigin + rc_picx(pic)*rc_xscale,
	rc_yorigin + rc_picy(pic)*rc_yscale -> (rc_xorigin, rc_yorigin);

	rc_undraw_button_background(pic, mid, border, blob_rad, width, height);

enddefine;

define :method rc_undraw_linepic(pic:rc_button);
	rc_undraw_button(pic)
enddefine;

/*
define -- Mouse and motion methods for windows and buttons
*/

;;; global variable holding last selected action button, which may need to be
;;; redrawn if mouse button is released, etc
global vars rc_selected_action_button = false;

define :method rc_button_1_up(win_obj:rc_button_window, x, y, modifiers);
	;;; in case mouse was moved off selected button, cancel the action
	if rc_selected_action_button and
		isrc_button(rc_selected_action_button)
	then
		rc_setframe_draw_border
			(rc_selected_action_button, rc_button_bordercolour(rc_selected_action_button));
	 	false -> rc_selected_action_button;
	endif;
	call_next_method(win_obj, x, y, modifiers);
enddefine;

define :method rc_mouse_exit(win_obj:rc_button_window, x, y, modifiers);
	;;; in case mouse was moved off selected button, cancel the action
	;;; Need to check that it is a picture button, not a "panel" button
	if rc_selected_action_button and
		isrc_button(rc_selected_action_button)
	then
		;;; redraw the border, using local button coordinates
		
		procedure();
			dlocal
				rc_xorigin = rc_xorigin + rc_xscale*rc_picx(rc_selected_action_button),
				rc_yorigin = rc_yorigin + rc_yscale*rc_picy(rc_selected_action_button);

			rc_draw_border(rc_selected_action_button, rc_button_bordercolour(rc_selected_action_button));
		endprocedure();

	 	false -> rc_selected_action_button;
	endif;
	call_next_method(win_obj, x, y, modifiers);
enddefine;

define :method rc_button_do_nothing(pic:rc_button, x, y, modifiers);
	;;; default event handler
enddefine;

define :method rc_button_do_no_drag(pic:rc_button, x, y, modifiers);
	;;; default event handler
enddefine;

define :method rc_drag_invisible(pic:rc_invisible_action_button, x, y, modifiers);
	;;; Needed because mouse can be dragged across invisible buttons!!
	;;; Must transfer control to the window.
	;;; Drag as if no button were there. Assume it's button 1 for now.
	if rc_selected_action_button == pic then
		rc_button_1_drag(rc_active_window_object, x, y, modifiers);
	endif;
enddefine;

define :method rc_rcbutton_1_down(pic:rc_button, x, y, modifiers);
	;;; default is do nothing
enddefine;

define :method rc_rcbutton_1_up(pic:rc_button, x, y, modifiers);
	;;; Default is to behave as if button were not there, i.e. button up in
	;;; the window.
	rc_button_1_up(rc_active_window_object, x, y, modifiers);
enddefine;

/*
define -- Facilities for action buttons
*/

define rc_async_apply(proc, deferring);
	;;; Previously in separate library
	;;; Apply the procedure, raise any new file, but don't
	;;; warp context. Suitable for buttons rotating or swapping
	;;; files, etc.

	;;; Save the current environment, which may need to be
	;;; checked or restored
	lvars
		;;; make sure busy cursor is re-set in Xved
		was_busy = XptBusyCursorOn,
		procedure proc,
		oldfile = vedcurrentfile,
		oldline = vedline,
		oldcolumn = vedcolumn,
		;;; the window in which the action is happening
		active_win = rc_active_window_object,
		isactivewin = active_win and rc_islive_window_object(active_win);

	;;; [async ^rc_current_window_object]=>

	define update_edit() with_props 'update_edit';
		;;; Update edit buffers after action
		if  vedcurrentfile /== oldfile
		or vedline /== oldline or vedcolumn /== oldcolumn
		then
			vedcheck();
			vedrefreshstatus();
			vedsetcursor();
		endif
	enddefine;

	define do_set_current(win_obj) with_props 'do_set_current';
		;;; Restore current window object, if appropriate
		if isrc_window_object(win_obj)
		and win_obj /== rc_current_window_object
		and rc_widget(win_obj)
		and xt_islivewindow(rc_widget(win_obj))
		then
			;;;; 'restoring in async'=>
			win_obj
		else
			false
		endif -> rc_current_window_object;
	enddefine;

	define lconstant do_proc() with_props 'do_proc';
		;;; Run the action.
		;;; This may be run in a deferred context, when the wrong
		;;; window object is current. So set the one in which the
		;;; button was invoked. First save the current one.

		lvars old_window = rc_current_window_object;

		;;; old_window=>
		;;; Make sure appropriate window is made current, so that
		;;; drawing works, etc.
		unless old_window == active_win or not(isactivewin) then

			active_win -> rc_current_window_object;

		endunless;
		;;; [before ^rc_current_window_object]=>

		rc_sync_display();
		proc();
		rc_sync_display();


		;;; [After ^rc_current_window_object]=>
		;;; now restore environment
		unless old_window == rc_current_window_object then
			do_set_current(old_window);
		endunless;

		;;;; [After reset ^rc_current_window_object]=>

		if vedusewindows == "x" then

			if vedcurrentfile /== oldfile and wvedalwaysraise then
				true -> xved_value("currentWindow", "raised");
			endif;
			false -> wvedwindowchanged;

			update_edit();
		elseif vedinvedprocess and vedediting then
			update_edit();
		endif;

		if vedusewindows == "x" and vedbufferlist /== []
		and not(vedinvedprocess)
		then
			vedinput(vedrefresh);
		endif;

		;;;if isclosure(proc) then sys_grbg_closure(proc) endif;
		;;; Removed 19 Feb 2004

	enddefine;


	;;; Some ved mechanisms must run inside ved_apply_action
	define lconstant do_action_inVed() with_props 'do_action_inVed';
		ved_apply_action(
		  	procedure() with_props 'inVed';
				
				dlocal
					cucharout,
					cucharerr = cucharout,
					vedwarpcontext = false;

				if isstring(rc_charout_buffer) then
					;;; Output is to be directed to a VED buffer.
					lvars file = vedopen(rc_charout_buffer);
					;;; file.ved_buffer_pathname =>

					veddiscout(ved_buffer_pathname(file))
						->> cucharout -> cucharerr;
				endif;

            	;;; Finally run the action button procedure
				;;; It will restore current window if necessary.
				do_proc();

			endprocedure);
	enddefine;

	if (vedediting and isstring(rc_charout_buffer))
		or vedinvedprocess or vedusewindows == "x"
	then
		;;; Run the procedure in an appropriate context for Ved actions
		if vedinvedprocess and vedusewindows == "x"
		then
			do_action_inVed();
			;;; sys_raise_ast(false);
			;;; XptSetXtWakeup();
			chain(procedure;
					was_busy -> XptBusyCursorOn;
				  endprocedure);
		else
			external_defer_apply(do_action_inVed);
			external_defer_apply(procedure; was_busy -> XptBusyCursorOn; endprocedure);
		endif
	else
		;;; Output not wanted in VED AND process not running in Ved
    	;;; so simply run the procedure
		external_defer_apply(do_proc);
	endif;

	;;; Process any remaining signals (redundant? but harmless)
enddefine;

define :method rc_async_apply_action(pic:rc_button, action_type);
	;;; handle the action in an appropriate context, e.g. to ensure that
	;;; printing goes to the right place.
	;;; This method could be redefined for some types of buttons to avoid
	;;; the use of rc_async_apply

	;;; create action closure
	lvars p = recursive_valof(action_type(pic))(%pic%);

	rc_async_apply(p, false);

enddefine;


define :method rc_do_button_action(pic:rc_action_button);
	;;; Action to be performed when mouse pic is released.
	;;; action will determine the action

	;;; Re-enable events. Is this safe ?
	dlocal rc_in_event_handler = false;

	lvars real_action, action = rc_button_action(pic);

	;;; [action ^action]=>
	;;; in case it is a word or identifier, get its valof
	recursive_valof(action) -> action;

	;;; if isclosure(action) then pdpart(action) => endif;

	if isident(action) then idval(action) -> action endif;

	if isclosure(action) and pdpart(action) == rc_defer_apply then

		action();
		;;;process_defer_list();
		return;
	elseif isprocedure(action) then
		;;; Includes closures
		;;; rc_active_window_object=>
		rc_async_apply(action, false);
	elseif islist(action) then
		if front(action) == "POPNOW" then
			;;; should no longer arise:
			'POPNOW action not expected '>< action =>
			back(action) -> action;
			procedure();
				dlocal vedediting = vedinvedprocess and isstring(rc_charout_buffer);

				lvars proc = recursive_valof(front(action));
				if isprocedure(proc) then
					;;; do it without deferring
					rc_async_apply(proc, false);
				else
					;;; This is generally unsafe with POPNOW!
					async_interpret_action(action)
				endif;
			endprocedure();
		else
			rc_async_apply(async_interpret_action(%action%), false)
		endif
	elseif isvector(action) and isstring(action(1) ->> real_action) then
		;;; vector containing string: treat as pop11 instruction to be
		;;; compiled and run
		rc_async_apply(pop11_compile(%stringin(real_action)%), false)
	elseif isvector(action) and islist(action(1) ->> real_action) then
		;;; treat list as procedure (or procedure name) plus args
		rc_async_apply(
					recursive_valof(front(real_action))(%
						explode(back(real_action))%),
					false)
	elseif isstring(action) then
		;;; treat as ved command
		
		rc_async_apply(veddo(%action,true%), false)
	else
		mishap('UNKNOWN ACTION TYPE IN ', [^action ^rc_active_picture_object])
	endif;

	if vedusewindows == "x" and not(vedinvedprocess) then
		;;; The next one sometimes causes an error
		;;; vedinput(rc_flush_everything);
		XptSetXtWakeup();
	else
		rc_flush_everything();
	endif;
enddefine;

define :method rc_rcbutton_1_down(pic:rc_action_button, x, y, modifiers);
	;;; Undo any previous selection in this window.
	rc_release_mouse_control();
	;;; do the action only when the pic is released.
	pic -> rc_selected_action_button;
	rc_setframe_draw_border(pic, rc_button_pressedcolour(pic));
enddefine;

define :method rc_rcbutton_1_down(pic:rc_invisible_action_button, x, y, modifiers);
	;;; Do the action only when the button is released.
	;;; Undo any previous selection in this window.
	rc_release_mouse_control();
	pic -> rc_mouse_selected(rc_active_window_object);
	pic -> rc_selected_action_button;
	;;; don't re-draw border
enddefine;

global vars
	rc_in_button_handler = false,
	rc_action_button_x, rc_action_button_y;


define vars do_rcbutton_1_up(pic, x, y, modifiers);
	;;; used in next two methods.

	if pic == rc_selected_action_button then
		;;; For deferred actions this information may be out of date
		x -> rc_action_button_x, y -> rc_action_button_y;

		;;; On previously selected button, so do the action.
		;;; Make sure VED utilities will work
		if vedbufferlist /== [] and vedinvedprocess then
			dlocal vedediting = true;
		endif;
		rc_do_button_action(pic);
	else
		;;; moved off the selected button. Do nothing, but
		;;; make sure exit_action works on the previously selected button
		;;; rc_selected_action_button -> pic;
		;;; was that a bug, should it have been this way round ???
		pic -> rc_selected_action_button
	endif;

enddefine;

define :method rc_rcbutton_1_up(pic:rc_action_button, x, y, modifiers);
	;;; This is the main "action" method for action buttons.

	lvars oldwin = rc_window, oldwin_obj = rc_current_window_object,
			exit_done = false;

	dlocal rc_in_button_handler = true;

	;;;; rc_current_window_object =>

	define lconstant exit_action();
		;;; Make sure button is redrawn even if there's an error
		;;; fix appearance if still on old window
		returnif(exit_done);

		;;;; [exiting 1 ^rc_current_window_object]=>
		lvars newwin_obj = rc_current_window_object, restored = false;

		;;; restore the old window if necessary so that the button
		;;; border can be redrawn
		if oldwin_obj and oldwin_obj /== rc_current_window_object
		and oldwin_obj /== newwin_obj
		and xt_islivewindow(rc_widget(oldwin_obj))
		then
			oldwin_obj -> rc_current_window_object;
			true -> restored;
			;;;;[restored old ^rc_current_window_object]=>
		endif;

		;;; If necessary restore the button's border
		if rc_window == oldwin	;;; redundant now?
		and pic and pic == rc_selected_action_button
		then
			rc_setframe_draw_border(pic, rc_button_bordercolour(pic));
		endif;

		if restored and newwin_obj and newwin_obj /== rc_current_window_object then
			newwin_obj -> rc_current_window_object;
			;;;; [newwin restored ^rc_current_window_object]=>
		endif;
		false -> rc_selected_action_button;
		;;; prevent repeated activation
		true -> exit_done;
	enddefine;
	
	;;; Re-enable events. Is this safe?
	dlocal rc_in_event_handler = false;

	dlocal 0 %, if dlocal_context < 3 then exit_action() endif%;

	;;;;[starting ^rc_current_window_object]=>
	;;; [doing pic ^pic]=>
	do_rcbutton_1_up(pic, x, y, modifiers);

enddefine;

define :method rc_rcbutton_1_up(pic:rc_invisible_action_button, x, y, modifiers);
	lvars oldwin = rc_window, oldwin_obj = rc_current_window_object,
			exit_done = false;

	dlocal rc_in_button_handler = true;

	define lconstant exit_action();
		;;; Make sure global set on exit.
		returnif(exit_done);
		false -> rc_selected_action_button;
		true -> exit_done;
		rc_release_mouse_control();
	enddefine;
	
	;;; Re-enable events. Is this safe?
	dlocal rc_in_event_handler = true;

	dlocal 0 %, if dlocal_context < 3 then exit_action() endif%;

	do_rcbutton_1_up(pic, x, y, modifiers);

	exit_action();
enddefine;


/*
define -- Facilities for display buttons
I.e. toggle and counter buttons
*/

define :method switch_rc_toggle_value(pic:rc_toggle_button);
	lvars
		item = rc_informant_value(pic);
		;
	lconstant tests = [^isword ^isident ^isboolean];
	check_item(item, tests, false);
	if isboolean(item) then
		not(item) -> rc_informant_value(pic)
	else ;;;; if isword(item) or isident(item) then
		not(valof(item)) -> valof(item)
	endif;

	rc_draw_linepic(pic);
enddefine;

define :method rc_rcbutton_1_down(pic:rc_toggle_button, x, y, modifiers);
	;;; Undo any previous selection in this window.
	rc_release_mouse_control();
	switch_rc_toggle_value(pic);
enddefine;


define :method rc_rcbutton_1_up(pic:rc_toggle_button, x, y, modifiers);
	if rc_selected_action_button then
		if rc_selected_action_button == pic then
			;;; should never happen
		else
			;;; this should invoke default button up method
			call_next_method(pic, x, y, modifiers)
		endif;
	endif;
enddefine;


/*
define -- Facilities for counter buttons
*/
define lconstant procedure stack_chars_from(item);
	;;; stack the characters from item's printed representation
	;;; If it is a string or word, explode it.
	dlocal pop_pr_quotes = false;

	if isstring(item) or isword(item) then
		explode(item)
	else
		dlocal cucharout = identfn;	;;; just stack characters
		sys_syspr(item)
	endif
enddefine;

define :method rc_draw_button(pic:rc_counter_button);
	lvars
		val = rc_informant_value(pic),
		brackets = rc_counter_brackets(pic),
		label = rc_button_label(pic),
		oldlabel = rc_original_label(pic),
		;
	;;; If original label has not been saved, save it

	unless oldlabel then label ->> oldlabel ->rc_original_label(pic) endunless;

	lconstant
		tests1 = [^isnumber ^isword ^isident],
		tests2 = [^isstring ^isword],
		tests3 = [^isnumber];

	check_item(val, tests1, false);
	check_item(label, tests2, false);

	lvars realval = DEREF(val);
	check_item(realval, tests3, false);

	;;;Veddebug(realval);
	consstring(#|
		stack_chars_from(oldlabel), `\s`, explode(brackets(1)),
		stack_chars_from(realval), explode(brackets(2)) |#) -> rc_button_label(pic);

	call_next_method(pic);
	;;; oldlabel -> rc_button_label(pic)
enddefine;

define lconstant restrict_to_range(val, minval, maxval) -> val;
	if minval then max(val, minval) -> val endif;
	if maxval then min(val, maxval) -> val endif;
enddefine;

define :method rc_increment_counter(pic:rc_counter_button, up);
	;;; up is a boolean. True for left button press, false for right button
	lvars
		inc = DEREF(rc_counter_inc(pic)),
		val = rc_informant_value(pic),
		realval = DEREF(val),
		newval;

	;;; [counter val ^val].Veddebug;
	if up then nonop + else nonop - endif(realval, inc) -> newval;
	;;; check constraints
	restrict_to_range(newval, rc_counter_min(pic), rc_counter_max(pic))
												-> rc_button_value(pic);
	rc_information_changed(pic);
enddefine;

define :method rc_rcbutton_1_down(pic:rc_counter_button, x, y, modifiers);
	rc_release_mouse_control();
	;;; decrement the counter
	rc_increment_counter(pic, false);
enddefine;

define :method rc_rcbutton_1_up(pic:rc_counter_button, x, y, modifiers);
	;;; do nothing;
enddefine;

define :method rc_rcbutton_3_down(pic:rc_counter_button, x, y, modifiers);
	rc_release_mouse_control();
	;;; increment the counter
	rc_increment_counter(pic, true);
enddefine;


/*
define -- Facilities for option buttons
*/


define :method rc_draw_button(pic:rc_option_button);
	;;; draw with a different label background if option selected
	lvars
		pic,
		oldground = rc_button_labelground(pic),
		newground = rc_chosen_background(pic),
		chosen = rc_informant_value(pic);
		dlocal 0 %, if chosen then oldground -> rc_button_labelground(pic) endif%;

	;;;[Drawing ^pic ^(rc_button_label(pic)) inf ^chosen old ^oldground new ^newground ].Veddebug;
	if chosen then
		newground -> rc_button_labelground(pic);
	endif;

	call_next_method(pic);

enddefine;

define :method rc_rcbutton_1_down(pic:rc_option_button, x, y, modifiers);
	;;; switch "chosen" state and redraw.
	not(rc_informant_value(pic)) -> rc_informant_value(pic);
	rc_draw_linepic(pic);
	rc_release_mouse_control();
	rc_information_changed(pic);	;;; May do nothing
enddefine;


define rc_button_with_label(item, buttonlist) -> button;
	;;; Check that item, usually a string, is one of the labels of
	;;; the buttons in the list. Return the button or false.
	lvars button;
	for button in buttonlist do
		if item = rc_button_label(button) then
			return()
		endif
	endfor;
	false -> button;
enddefine;


;;; used later
global vars rc_button_updating = '';		;;; unique empty string.

;;; defined later:
global vars procedure rc_set_button_defaults;

define rc_options_chosen_for(buttons, procedure proc) -> options;
	;;; buttons is a list of buttons
	;;; proc is either rc_button_label or rc_real_contents
	;;; Return the slot value corresponding to proc for all the
	;;; chosen options. Stop after first if it's
	;;; a radio button. If they are radio buttons and nothing is
	;;; found return false.
	lvars button, len = stacklength();
	for button in buttons do
		if rc_informant_value(button) then
			proc(button);
			unless isrc_someof_button(button) then
				;;; return only one thing
				-> options;
				return()
			endunless;
		endif
	endfor;
	lvars num = stacklength() - len;
	conslist(num) -> options;
enddefine;

define rc_options_chosen = rc_options_chosen_for(%rc_button_label%);
enddefine;

define rc_values_chosen = rc_options_chosen_for(%rc_real_contents%);
enddefine;


define updaterof rc_options_chosen(options, buttons);
	;;; find out what sorts of buttons they are
	lvars buttontype =
		if isrc_someof_button(hd(buttons)) then		
			"someof"
		else "radio"
		endif;
	;;; Now set the buttons. Warning: rc_current_window_object must have been set
	lvars wid = rc_informant_ident(hd(buttons));
	rc_set_button_defaults(buttons, wid, options, buttontype);
enddefine;



/*
define -- Facilities for radio buttons
*/

define :method rc_rcbutton_1_down(pic:rc_radio_button, x, y, modifiers);
	;;; switch "chosen" state, redraw, and update siblings
	lvars button;

	;;; Should this do anything if pic is already selected?

	;;; clear previously selected button

	for button in rc_radio_list(pic) do
		if rc_informant_value(button) then
			false -> rc_informant_value(button);
			rc_draw_linepic(button);
			rc_async_apply_action(button, rc_radio_deselect_action);
			quitloop();	;;; only one should have been set
		endif
	endfor;
	;;; Now indicate selected action and run the select procedure
	true -> rc_informant_value(pic);
	
	rc_draw_linepic(pic);
	;;; recursive_valof(rc_radio_select_action(pic))(pic);
	rc_async_apply_action(pic, rc_radio_select_action);

	rc_release_mouse_control();

	;;; now set identifier if appropriate
	lvars wid = rc_informant_ident(pic);
	if isword(wid) or isident(wid) then
		;;; This will create garbage, but presumably does not
		;;; happen often
		rc_options_chosen(rc_radio_list(pic)) -> valof(wid)
	endif;
	rc_information_changed(pic);	;;; May do nothing
enddefine;


define rc_set_radio_buttons(item, buttons);
	;;; Item is a button label, usually a string. Set the  button with that
	;;; label to be on, and the others off.
	;;; If item is "none" then unset all buttons

	dlocal rc_current_window_object;	

	lvars button;
	if isrc_button(item) then
		item -> button
	elseif item == "none" then
		;;; unset all buttons
	else
		;;; item should be a string that is the button label
		rc_button_with_label(item, buttons) -> button;
	endif;

	unless item == "none" or isrc_button(button) then
		mishap('Button or relevant label needed', [%item, buttons%])
	endunless;

	;;; make sure we find the window containing the buttons
	lvars container = rc_button_container(hd(buttons));
	;;; [container1 ^container]==>

	unless isrc_window_object(container) then
		;;; this library may be compiled before rc_control_panel
		if valof("isrc_panel_field")(container) then
			;;; make sure the container is the window
			valof("rc_field_container")(container) -> container;
		endif;
	endunless;
	;;; [container2 ^container]==>

	;;; make the button's window the current window object
	unless container == rc_current_window_object then
		container -> rc_current_window_object;
	endunless;

	if item == "none" then
		;;; unset all the buttons
		lvars b;
		for b in buttons do
			if rc_button_value(b) then
				false -> rc_button_value(b);
				rc_draw_linepic(b);
				;;;recursive_valof(rc_radio_deselect_action(b))(b);
				;;; now set identifier if appropriate
				lvars wid = rc_informant_ident(b);
				if isword(wid) or isident(wid) then
					;;;[setting valof ^wid undef] =>
					undef  -> valof(wid);
				endif;
				rc_information_changed(b);	;;; May do nothing
				return();
				quitloop();	;;; only one should have been set
			endif
		endfor
	else
		;;; button specified
		;;; now act as if the button had been clicked on
		rc_rcbutton_1_down(button, 0,0, nullstring);
	endif;
enddefine;



define rc_set_button_defaults(buttons, wid, def, buttontype);
	;;; Set the default button or buttons either on the basis
	;;; of the associated word or identifier wid, if set or the
	;;; default def, which may come from from a field in rc_control_panel
	;;; Let wid have the priority unless the value is undef, or an
	;;; undef instance.
	;;; buttontype is one of "radio" and "someof"

	;;; Warning: rc_current_window_object must have been set
	unless rc_redrawing_panel then rc_check_window_object(); endunless;

	lvars button, widval = undef;
	if isword(wid) or isident(wid) then
		valof(wid) -> widval
	endif;
	if def == undef then
		unless  widval == undef or isundef(widval) then
			;;; the identifier value then takes priority over def
			widval -> def;
		endunless;
	endif;

	unless def == undef or isundef(def) then
		if (isword(wid) or isident(wid)) and def /== widval then
			def -> valof(wid)
		endif;
		if buttontype == "someof" then
			if islist(def) then
				for button in buttons do
					;;; switch on listed buttons, and make sure others are
					;;; switched off
					if member(rc_button_label(button), def) then
						true -> rc_informant_value(button);
						unless rc_redrawing_panel then
							rc_draw_linepic(button);
							;;; recursive_valof(rc_radio_select_action(button))(button);
							rc_async_apply_action(button, rc_radio_select_action);
						endunless;
					;;;; elseif wid == rc_button_updating then
					else
						false -> rc_informant_value(button);
						unless rc_redrawing_panel then
						rc_draw_linepic(button);
						;;; recursive_valof(rc_radio_deselect_action(button))(button);
						rc_async_apply_action(button, rc_radio_deselect_action);
						endunless;
					endif;
				endfor;
			else
				mishap('LIST NEEDED FOR RADIO BUTTON DEFAULTS',
					[^def ^buttons])
			endif;
		else ;;; buttontype is "radio"

			lvars found = false;
			for button in buttons do
				;;; switch on listed buttons
				if rc_button_label(button) = def then
					true ->> found -> rc_informant_value(button);
					 if (isword(wid) or isident(wid)) then
						def -> valof(wid);
					endif;
					unless rc_redrawing_panel then
						rc_draw_linepic(button);
						;;; recursive_valof(rc_radio_select_action(button))(button);
						rc_async_apply_action(button, rc_radio_select_action);
					endunless
				elseif rc_informant_value(button) then
					false -> rc_informant_value(button);
					unless rc_redrawing_panel then
						rc_draw_linepic(button);
						;;;recursive_valof(rc_radio_deselect_action(button))(button);
						rc_async_apply_action(button, rc_radio_deselect_action);
					endunless;
				elseif wid == rc_button_updating then
					false -> rc_informant_value(button);
					unless rc_redrawing_panel then
						rc_draw_linepic(button);
						;;; recursive_valof(rc_radio_deselect_action(button))(button);
						rc_async_apply_action(button, rc_radio_deselect_action);
					endunless
				endif;
			endfor;
			unless found or wid == rc_button_updating or wid == undef then
				mishap('NO RADIO BUTTON MATCHES DEFAULT TO SWITCH ON',
					['Default:' ^def 'buttons:' ^buttons]);
			endunless;
		endif;
	endunless;
enddefine;


/*
define -- Facilities for someof buttons
*/

define :method rc_rcbutton_1_down(pic:rc_someof_button, x, y, modifiers);
	;;; switch "chosen" state, redraw, and update siblings
	lvars selected = rc_informant_value(pic);

	;;; Now indicate selected action and run the select procedure
	not(selected) -> rc_informant_value(pic);
	if selected then
		;;; deselect
		;;;recursive_valof(rc_radio_deselect_action(pic))(pic);
		rc_async_apply_action(pic, rc_radio_deselect_action);
	else
		;;; recursive_valof(rc_radio_select_action(pic))(pic);
		rc_async_apply_action(pic, rc_radio_select_action);
	endif;
	rc_draw_linepic(pic);

	rc_release_mouse_control();

	;;; now set identifier if appropriate
	lvars wid = rc_informant_ident(pic);
	if isword(wid) or isident(wid) then
		;;; This will create garbage, but presumably does not
		;;; happen often
		rc_options_chosen(rc_radio_list(pic)) -> valof(wid)
	endif;
	rc_information_changed(pic);	;;; May do nothing
enddefine;


define set_or_unset_someof_buttons_to(list, buttons, setting);
	;;; List is either empty, which means deselect all the buttons,
	;;; or a list of labels of buttons (usually strings). Select all the
	;;; buttons in list, leaving any others that were previously selected
	;;; still selected. If list is the world "all", then select every one.
	;;; If it is "none" unset all

	dlocal rc_current_window_object;	

	lvars item, items, button;
	if list == "all" then buttons -> items;
	;;; elseif list == [] then
	elseif setting == true and list == "none" then
		buttons -> items;
	else
 		;;; convert the list to a list of buttons
		[%
			for item in list do
				if isrc_button(item) then
					item
				else
					;;; item should be a string that is the button label
					rc_button_with_label(item, buttons)
				endif -> button;
				unless isrc_button(button) then
					mishap('Button or relevant label needed', [%item, list, buttons%])
				endunless;
				button
			endfor
		%] -> items;
	endif;

	;;; items =>
	;;; items should now be a list of buttons to be set "on"

	;;; make sure we find the window containing he buttons
	lvars container = rc_button_container(hd(buttons));
	;;; [container1 ^container]==>

	unless isrc_window_object(container) then
		;;; this library may be compiled before rc_control_panel
		if valof("isrc_panel_field")(container) then
			;;; make sure the container is the window
			valof("rc_field_container")(container) -> container;
		endif;
	endunless;
	;;; [container2 ^container]==>

	;;; make the button's window the current window object
	unless container == rc_current_window_object then
		container -> rc_current_window_object;
	endunless;

	if setting == true and list == "none" then

		;;; clear all the buttons
		for button in buttons do
			if rc_button_value(button) then
				;;; now act as if the button had been clicked on
				rc_rcbutton_1_down(button, 0,0, nullstring);
			endif;
		endfor;
	else
		;;; set the specified buttons
		for button in items do
			if setting == true then
				unless rc_button_value(button) then
					;;; now act as if the button had been clicked on
					rc_rcbutton_1_down(button, 0,0, nullstring);
				endunless;
			elseif setting == false then
				if rc_button_value(button) then
					;;; now act as if the button had been clicked on
					rc_rcbutton_1_down(button, 0,0, nullstring);
				endif;
				else
				;;; now act as if the button had been clicked on
				rc_rcbutton_1_down(button, 0,0, nullstring);
			endif;
		endfor;
	endif;

	if islist(items) then
		unless list == "all" or list == "none" then
			sys_grbg_list(items);
		endunless;
	endif;


enddefine;

define rc_set_someof_buttons = set_or_unset_someof_buttons_to(%true%)
enddefine;

define rc_unset_someof_buttons = set_or_unset_someof_buttons_to(%false%)
enddefine;

define rc_change_someof_buttons = set_or_unset_someof_buttons_to(%undef%)
enddefine;



/*
define -- Abbreviations for feature spec items

expand_button_spec_abbreviations({blobcol 'blue' height 10 textfg 'blue' reactor identfn})=>

expand_button_spec_abbreviations([{blobrad 5} {height 10 textfg 'blue'} {reactor identfn}])=>
*/

;;; User extendable property for abbreviations in button specs
define procedure rc_button_spectrans = newproperty(
	  [
		[height ^rc_button_height] 		 [width ^rc_button_width]
		[font ^rc_button_font] 			 [borderwidth ^rc_button_border]
		[textfg ^rc_button_stringcolour] [bordercol ^rc_button_bordercolour]
		[textbg ^rc_button_labelground]  [chosenbg ^rc_chosen_background]
		[blobrad ^rc_button_blobrad] 	 [blobcol ^rc_button_blobcolour]
		[labels ^rc_toggle_labels] 		 [constrain ^rc_constrain_contents]
		[ident ^rc_informant_ident] 	 [border ^rc_button_border]		
		[reactor ^rc_informant_reactor]],
		16, false, "perm");
enddefine;

define expand_button_spec_abbreviations(spec) -> spec;
	;;; Translate some shorthand specs

	;;; But not if the spec is false
	returnunless(spec);

	lvars item, n;
	if isvector(spec) then
		fast_for n from 1 by 2 to datalength(spec) do
			
			rc_button_spectrans(subscrv(n, spec)) -> item;
			if item then item -> subscrv(n, spec) endif
		endfor;
	elseif islist(spec) then
		;;; It should be a list. Recursively translate
		for item in spec do
			expand_button_spec_abbreviations(item) ->;
		endfor;
	else
		mishap('Spec should be vector or list', [^spec]);
	endif
enddefine;


/*
define -- Utilities for modifying buttons during creation
*/

;;; this is used if rc_popup_query is loaded
global vars procedure isrc_select_button;

define vars rc_update_button_mouse_limit(button, oldborder, oldheight, oldwidth);
	;;; after a modify_instance method has interpreted any "extra"
	;;; specs in the button description, it will typically be
	;;; necessary to update the mouse-sensitive region if the
	;;; height and width have changed
	lvars
		border = rc_button_border(button),
		width = rc_button_width(button),
		height = rc_button_height(button),
		;

	;;; Now update the sensitive area if necessary
	if height /== oldheight
	or width /== oldwidth
	or border /== oldborder
	then
		{%border/rc_xscale, border/rc_yscale,
			(width-border)/rc_xscale, (height-border)/rc_yscale%};
				-> rc_mouse_limit(button);
	endif;
enddefine;



define :method modify_instance(button:rc_button, contents, type);
	;;; Called by create_rc_button, after instance has been created

	;;; Default version simply stores the contents in the button.
	;;; More specific versions defined below do other things.

	contents -> rc_button_label(button);

enddefine;


define :method modify_instance(button:rc_action_button, contents, type);
	;;; called by create_rc_button, after instance has been created
	;;; also works for blob buttons and invisibile buttons.

	;;; additional newspecs may be in the contents (list or vector)
	lvars newspecs = false;

	;;; contents may be a word, string, vector, or list,
	if isstring(contents) or isword(contents) then
		contents, contents
	elseif islist(contents) and listlength(contents) == 1 then
		dup(contents(1))
	elseif islist(contents) then
		contents(1), contents(2);
		
		if listlength(contents) == 3 then
			;;; third item should be a featurespec vector
			contents(3) -> newspecs
		endif;
	elseif isvector(contents) then
		;;; first item would have been "action" or "blob"
		contents(1) -> type;
		contents(2), contents(3);
		if datalength(contents) == 4 then
			contents(4) -> newspecs
		endif;
	elseif isnumber(contents) and isrc_select_button(button) then
		contents, false
	else mishap('Word, list, vector or string expected for button', [^contents])
	endif -> (rc_button_label(button), rc_button_action(button));

	;;; if the action was false, make the contents the action
	;;; e.g. where the label is a VED enter command, e.g. 'teach lists'
	unless rc_button_action(button) then
		;;; this will be interpreted below
		rc_button_label(button) -> rc_button_action(button)
	endunless;

	lvars action = rc_button_action(button);

	;;; Where possible pre-compile the action code, with a useful
	;;; pdprops to indicate origin for debugging

	if islist(action) then
		lvars key = hd(action);
		if key == "POP11" or key == "INVED" or key == "POPNOW"
		then
			lvars pdr =
				pop11_compile([procedure(); ^^(tl(action)) endprocedure]);
			;;; give the proceure a useful name for debugging
			key sys_>< '_' sys_>< rc_button_label(button)
				-> pdprops(pdr);

			pdr	-> rc_button_action(button);
		elseif key == "DEFER" then
			;;; Changed 28 Feb 2000, to use rc_defer_apply, which will
			;;; run things outside the context of current window.
			;;; E.g. you can then do assignments to rc_current_window_object, etc.

			tl(action) -> action;
			lvars key = hd(action);
			if back(action) == [] then
				;;; there's just one item in the list, a procedure or its name
				;;; external_defer_apply(%recursive_valof(key)%)
				rc_defer_apply(%recursive_valof(key)%)
			else
				;;; Get rid of optional word POP11
				if key == "POP11" then tl(action) -> action endif;
				lvars pdr =
					pop11_compile([procedure(); ^^action endprocedure]);

				'DEFER_' sys_>< rc_button_label(button) -> pdprops(pdr);

				;;; external_defer_apply(%pdr%)
				;;;rc_async_apply(%pdr, true%)
				rc_defer_apply(%pdr%)
			endif -> rc_button_action(button);
			;;; rc_button_action(button) =>
		endif;
    endif;

	if (type == "blob" or type == rc_blob_button_key)
	and rc_button_blobrad(button) == 0
	then
		;;; adjust blob radius if necessary
		rc_button_default_blobrad -> rc_button_blobrad(button);
	endif;

	;;; Now run the specs to modify defaults, if necessary
	if newspecs then
		interpret_specs(button, expand_button_spec_abbreviations(newspecs));
	endif;

enddefine;

define :method modify_instance(button:rc_invisible_action_button, contents, type);
	;;; change the sensitive area to reflect height and width, with location still
	;;; at top left corner.
	lvars w = rc_button_width(button), h = rc_button_height(button);
	;;; This needs to be kept consistent with height and width
	{%0, 0, w/rc_xscale, h/rc_yscale%} -> rc_mouse_limit(button);

	;;; The specs may alter that default setting.
	call_next_method(button, contents, type);

enddefine;

define :method modify_instance(button:rc_display_button, contents, type);
	;;; Called by create_rc_button, after instance has been created

	;;; Do nothing, by default

enddefine;


define :method modify_instance(button:rc_toggle_button, contents, type);
	;;; Called by create_rc_button, after instance has been created

	lvars newspecs = false;

	if islist(contents) then
		if listlength(contents) >= 3 then
			contents(3) -> newspecs
		endif;
		;;; This version should never occur now
		contents(1), contents(2)
	elseif isvector(contents) then
		if datalength(contents) == 4 then
			contents(4) -> newspecs;
		endif;
		;;; label
		contents(2),
			;;; and value
			lvars buttonval = contents(3);
			if isword(buttonval) or isident(buttonval) then
				buttonval -> rc_informant_ident(button);
				valof(buttonval)
			else
				buttonval
			endif;
	else mishap('List or vector expected for button', [^contents])
	endif -> (rc_button_label(button), rc_informant_value(button));

	;;; rc_button_label(button) -> rc_informant_label(button);

	if isvector(newspecs) then
		;;; interpret the specs
		interpret_specs(button, expand_button_spec_abbreviations(newspecs));
	endif;

enddefine;

define :method modify_instance(button:rc_counter_button, contents, type);
	;;; called by create_rc_button, after instance has been created

	lvars inc, minval = false, maxval=false, newspecs = false;

	if islist(contents) then
		if listlength(contents) >= 4 then
			contents(4) -> newspecs
		endif;
		;;; This version should never occur now
		contents(1), contents(2), contents(3)
	elseif isvector(contents) then
		if datalength(contents) == 5 then
			contents(5) -> newspecs;
		endif;			
		contents(2), contents(3), contents(4)
	else mishap('List or vector expected for button', [^contents])
	endif -> (rc_button_label(button), rc_counter_value(button), inc);
	;;; rc_button_label(button) -> rc_informant_label(button);

	if isvector(inc) then
		if datalength(inc) == 2 then
			explode(inc) -> (inc, minval)
		elseif datalength(inc) == 3 then
			explode(inc) -> (inc, minval, maxval)
		else
			mishap('VECTOR OF LENGTH 2 OR 3 NEEDED IN COUNTER BUTTON', [^inc])
		endif;
		minval -> rc_counter_min(button);
		maxval -> rc_counter_max(button);
	endif;
	inc -> rc_counter_inc(button);

	;;; setup ident, if appropriate;
	lvars val = rc_counter_value(button);
	if isword(val) or isident(val) then
		val -> rc_informant_ident(button);
		valof(val) -> rc_informant_value(button);
	endif;

	if newspecs then
		;;; interpret the specs
		interpret_specs(button, expand_button_spec_abbreviations(newspecs));
	endif;
enddefine;

define :method modify_instance(button:rc_option_button, contents, type);
	;;; called by create_rc_button, after instance has been created

	lvars newspecs = false;

	;;; [contents ^contents].Veddebug;	
	if islist(contents) then
		;;; this should not occur
		contents(1), contents(2)
	elseif isvector(contents) then
		;;; this should not occur?
		if datalength(contents) == 4 then contents(4) -> newspecs endif;
		contents(2), contents(3);
	elseif isword(contents) or isstring(contents) then
		contents, contents
	elseif isnumber(contents) then
		contents sys_>< nullstring, contents
	else mishap('Wrong contents for someof button', [^contents])
	endif -> (rc_button_label(button), rc_real_contents(button));
	rc_button_label(button) -> rc_informant_label(button);

	;;; [new button ^(rc_button_label(button), rc_real_contents(button))].Veddebug;
	;;; default is to be unselected
	false -> rc_informant_value(button);


	;;;[modify_instance but ^button inf ^(rc_informant_value(button))].Veddebug;

	if newspecs then
		interpret_specs(button, expand_button_spec_abbreviations(newspecs));
	endif;
enddefine;


/*
define -- Utilities for creating new buttons
*/

;;; User extendable property
define procedure rc_button_type_key = newproperty(
		[
			[action rc_action_button_key]
			[invisible rc_invisible_action_button_key]
			[counter rc_counter_button_key]
			[toggle rc_toggle_button_key]
			[blob rc_blob_button_key]
			[option rc_option_button_key]
			[radio rc_radio_button_key]
			[someof rc_someof_button_key]
			;;; this one defined in rc_popup_query]
			[select rc_select_button_key]
		], 8, false, "perm");
enddefine;

define rc_button_key_of_type(type) -> key;
	;;; if the type is a word, find the corresponding key. If it is already
	;;; a key, return it
	if isword(type) then
		recursive_valof(rc_button_type_key(type)) -> key;
	elseif iskey(type) then type -> key
	endif;
	
	unless iskey(key) then
		mishap('Button type should be a key or a word',[^type])
	endunless;

enddefine;



define create_rc_button(x, y, width, height, contents, type, specs) -> button;
	;;; Type is either a recognised word, e.g. "toggle", "counter", "action"
	;;; or a class key. The location of the button is at x, y.
	;;; The specs can be used to override default slots. It is false
	;;; or a vector of form {field val field val field val....},
	;;; as described in REF * OBJECTCLASS/create_instance, * OBJECTCLASS/set_slots
	;;; or a list of such vectors, or a	list of lists, etc.

	rc_check_current_window('For create_rc_button');

	;;; [contents ^contents].Veddebug;	
	;;; This procedure creates and draws the button and adds it to the current window object
	;;; Unless the final argument is "nodraw"
	lvars nodraw;
	if specs = "nodraw" then
		(x, y, width, height, contents, type, specs) ->
			(x, y, width, height, contents, type, specs, nodraw)
	else
		false -> nodraw
	endif;
		

	if isvector(contents) then
		;;; The contents starts wtih the type word. Override the type argument
		rc_button_key_of_type(contents(1))
	elseif type then
		;;; could be a key or one of the type words
		rc_button_key_of_type(type)
	else
		mishap('No button type specified', [^contents ^type])
	endif -> type;
	;;; type should now be a class key

	dlocal
		rc_button_width_def, rc_button_height_def;

	;;; see if default height and width etc. are to be changed
	if width then
		;;; checkinteger(width, 1, false);
		width -> rc_button_width_def
	endif;

	if height then
		;;; checkinteger(height, 1, false);
		height -> rc_button_height_def;
	endif;

	create_instance(type, []) -> button;

	;;; record border, height, width, so that sensitive area can
	;;; be updated if they are changed by modify instance
	lvars
		border = rc_button_border(button),
		width = rc_button_width(button),
		height = rc_button_height(button),
	;

	(x,y) -> rc_coords(button);

	;;; Now override defaults if appropriate
	interpret_specs(button, expand_button_spec_abbreviations(specs));

	;;; prevent modify_instance causing drawing
	dlocal rc_creating_button;

	true -> rc_creating_button;

	;;; Now allow appropriate method to override defaults if appropriate

	;;; Veddebug([Creating ^button contents ^contents]);
	modify_instance(button, contents, type);

	;;; Veddebug([modified ^button inf_con ^(rc_informant_value(button)))]);


	;;; Now update the sensitive area if necessary
	rc_update_button_mouse_limit(button, border, height, width);

	unless nodraw then
	   	rc_draw_linepic(button);
	endunless;
    rc_add_pic_to_window(button, rc_current_window_object, true);
	rc_current_window_object -> rc_button_container(button);
enddefine;


/*
define -- Procedures for creating rows, columns and arrays of buttons
*/

define create_button_columns(x, y, width, height, spacing, columns, list, type, specs) -> buttons;
	checkinteger(spacing, 0, false);
	checkinteger(columns, 0, false);
	rc_check_current_window('For create_button_columns');

	lvars spec = false;

	if isvector(list) then
		subscrv(1, list), subscrv(2, list) -> (spec, list)
	endif;

	;;; combine the specs from the procedure argument and those in the
	;;; list, giving priority to the latter (interpret them later)
	if spec then [^specs ^spec] -> specs; endif;

	;;; interpret abbreviations
	expand_button_spec_abbreviations(specs) -> specs;

	if columns == 0 then
		listlength(list) -> columns
	endif;

	;;; If necessary set default height and width
	unless width then
		rc_button_width_def -> width;
	endunless;

	unless height then
		rc_button_height_def -> height;
	endunless;

	lvars
		xspacing = (spacing + width)/rc_xscale ,
		yspacing = (spacing + height)/rc_yscale;

	lvars item, column = 0, xstart = x;

	[%for item in list do
		if column == columns then
			1 -> column;
			xstart -> x;
			y + yspacing -> y;
		else
			column + 1 -> column;
		endif;
		create_rc_button(x, y, abs(width), abs(height), item, type, specs);
		x + xspacing  -> x;
	endfor %] -> buttons;

	if spec then sys_grbg_list(specs); [] -> specs endif;
enddefine;

define rc_inform_button_siblings(buttons);
	;;; Tell each button about all the others
	lvars button;
    for button in buttons do
        buttons -> rc_radio_list(button)
    endfor;
enddefine;


;;; for uses
global vars rc_buttons = true;

endsection;

nil -> proglist;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Feb 19 2004
		Removed this line:
			if isclosure(proc) then sys_grbg_closure(proc) endif;
	Added rc_options_chosen_for
		and used it to define these two
		define rc_options_chosen = rc_options_chosen_for(%rc_button_label%);

		define rc_values_chosen = rc_options_chosen_for(%rc_real_contents%);

--- Aaron Sloman, Feb 17 2004
		Updated index.
		Updated HELP rc_buttons
		Documented rc_real_contents
--- Aaron Sloman, Sep 16 2002
		Made "async_vedbuffer" a synonym for "rc_charout_buffer"
--- Aaron Sloman, Sep 14 2002
		Restored functionality of some action button formats
--- Aaron Sloman, Sep 11 2002
		Stopped rc_async_apply trying to reset active window when there isn't one.
--- Aaron Sloman, Sep 10 2002
		Several bits of tidying up following changes in rc_mousepic
--- Aaron Sloman, Sep  9 2002
		Changed compile_mode to -constr
--- Aaron Sloman, Sep  7 2002
	Arranged for busy cursor to be re-set in rc_async_apply

	Various other changes to rc_async_apply, e.g. to ensure printing
	always works as expected. Attempted to make printing go consistently
	to the same file if async_vedbuffer is a string, vedediting is true, etc.

	Made raising of XVed windows after actions depend on wvedalwaysraise

	Introduced rc_async_apply_action(pic:rc_button, action_type);
	and cleaned up various complications as a result of recent changes
	to event handling in LIB rc_mousepic
--- Aaron Sloman, Sep  6 2002
		Removed no longer necessary invocations of vedinput
		(See changes to LIB rc_mousepic)
--- Aaron Sloman, Aug 26 2002
		Made sure button labels are copied to rc_informant label(button)
--- Aaron Sloman, Aug 25 2002
		replaced rc_informant*_contents with rc_informant_value
		
--- Aaron Sloman, Aug 21 2002
	Improved printing for most types of buttons.
	Changed toggle buttons not to confuse contents with ident.
--- Aaron Sloman, Aug 13 2002
Added new print instance methods for
	rc_counter_button rc_toggle_button rc_radio_button rc_someof_button
--- Aaron Sloman, Aug 11 2002
		More changes to support rc_control_panel and these autoloadable
		facilities
	rc_get_panel_entity.p
	rc_set_panel_entity.p
	rc_set_radio_panelfield.p
	rc_set_someof_panelfield.p
	rc_unset_someof_panelfield.p

--- Aaron Sloman, Aug 10 2002
		
	Changed print_instance(button) to make pop_pr_quotes true instead of
	always adding string quotes: not appropriate when label is a word
		
--- Aug  8 2002
	Made rc_button_updating global to facilitate debugging.
		(probably not needed)
	Fixed rc_set_button_defaults for radio buttons
	Fixed updater of rc_button_value for radio and someof buttons.
	(may need fixing for others also).
	No longer uses slot RC_button_value;
	Extensive changes involve rc_button_value and rc_informant_value
	to remove anomalies.
	Introduced rc_release_mouse_control() instead of
		false -> rc_mouse_selected(rc_active_window_object);
		
--- Aaron Sloman, Aug  7 2002
	Changed to make informant contents of radio and someof buttons only
	boolean values. Generally made simpler and more consistent. Got rid
	of rc_button_value, except as equivalent to rc_informant_value

	Various consequential changes, e.g. to rc_ popup_query

	Made counter buttons use rc_informant_value rather than a special slot.

--- Aug  6 2002
	rc_creating_button  now exported to simplify recompilation of methods.
	Other changes to be documented concerned with accessing buttons, in panels.
	See HELP rclib_news, HELP rc_control_panel

--- Jul 31 2002

Autoloadable procedures
	rc_button_in_panelfield(label, fieldlabel, panel) -> button;

	rc_set_radio_panelfield(label, field, panel);
	;;; set the buttons in the field of the panel if they have the
	;;; label
	;;; If label == "none" then unset all of the buttons.

	rc_set_someof_panelfield(list, field, panel);
	;;; set the buttons in the field of the panel if they have the
	;;; labels in the list

	rc_unset_someof_panelfield(list, field, panel);
	;;; unset the buttons in the field of the panel if they have the
	;;; labels in the list

	rc_set_radio_buttons(item, buttons);
	;;; Item is a button label, usually a string. Set the  button with that
	;;; label to be on, and the others off.
	;;; If item is "none" then unset all buttons

	set_or_unset_someof_buttons_to("none", buttons, setting);
	;;; List is either empty, which means deselect all the buttons,
	;;; or a list of labels of buttons (usually strings). Select all the
	;;; buttons in list, leaving any others that were previously selected
	;;; still selected. If list is the world "all", then select every one.

	rc_set_someof_buttons = set_or_unset_someof_buttons_to(%true%)

	rc_unset_someof_buttons = set_or_unset_someof_buttons_to(%false%)

	rc_change_someof_buttons = set_or_unset_someof_buttons_to(%undef%)

--- Jul 30 2002
	extended rc_set_someof_buttons so that if first argument is "all" then
	all the buttons are turned on.

--- Jul 28 2002

	New procedures for updating button arrays:
	rc_set_radio_buttons(item, buttons);
	 Item is a button label, usually a string. Set the  button with that
	 label to be on, and the others off.

	rc_set_someof_buttons(list, buttons);
	 List is either empty, which means deselect all the buttons,
	 or a list of labels of buttons (usually strings). Select all the
	 buttons in list, leaving any others that were previously selected
	 still selected.
		
	Made rc_set_button_defaults invoke check for rc_current_window_object

	New procedure
	rc_button_with_label(item, buttonlist) -> button;
	;;; Check that item, usually a string, is one of the labels of
	;;; the buttons in the list. Return the button or false.

	rc_button_key_of_type(type) -> key;
	;;; Uses the table rc_button_type_key to compute the type for which
	;;; the key is an abbreviation

	Changed all the class and mixin definitions to use "vars" specification,
	to simplify debugging.

	Added new information to HELP rc_control_panel

--- Aaron Sloman, Aug 19 2000
	Added INVED action type, like POP11, but uses vedinput when
	in XVed.
--- Aaron Sloman, Jul 21 2000
		Changed default font to
		'-adobe-helvetica-bold-r-normal-*-10-*-*-*-p-*-*-*';
--- Aaron Sloman, Jun 15 2000
	Removed final argument from modify instance
--- Aaron Sloman, Jun 15 2000
	Much reorganisation of the file. May do some further regrouping
	Fixed rc_mouse_limit for big buttons.
--- Aaron Sloman, Jun 14 2000
	added rc_button_default_blobrad and did some more tidying and
	rationalising. (More to do).
--- Aaron Sloman, Jun 13 2000
	Made 'grey95' the default background for buttons.
	Fixed buttons not drawn properly for unusual scales.
	Introduced rc_undraw_button. May not yet work for all cases.

--- Aaron Sloman, Feb 28 2000
	Changed DEFER to use rc_defer_apply (defined in LIB RC_MOUSEPIC)
		Can be used for actions that run outside the context of current window
		and which set the global context
--- Aaron Sloman, Dec 26 1999
	Made the default colour for selected buttons slightly darker, grey75
--- Aaron Sloman, Oct 10 1999
	moved out rc_kill_panel and rc_hide_panel
--- Aaron Sloman, Oct  9 1999
	Changed to set rc_current_window_object to false, in more
		cases.
--- Aaron Sloman, Sep 16 1999
	Split the method rc_draw_button_background to work differently for
	rc_display_button
--- Aaron Sloman, Sep 15 1999
	Removed this from rc_do_button_acton
		vedinput(rc_flush_everything);

	Introduced new format with blob instead of border for toggle, counter,
	RADIO and SOMEOF buttons. (Based on discussions with Brian Logan).
	Introduced new method rc_draw_button_type, which is used to draw the
	type of indicator for the above types of buttons.
	Split rc_draw_button_string for rc_display_button and its sub-types,
	with text offset to make room for the indicator. This uses the new
	method rc_offset_print_button_label
--- Aaron Sloman, Sep 14 1999
	gave rc_async_apply an extra argument
--- Aaron Sloman, Sep 14 1999
	Corrected bug due to vedinput when vedinvedprocess was false
--- Aaron Sloman, Sep 13 1999
	Changed global declarations with define :rc_defaults
	Reduced default font size, and border width for buttons
--- Aaron Sloman, Sep  5 1999
	added refreshstatus to update_edit
--- Aaron Sloman, Sep  2 1999
	Made handling of action buttons with a procedure and with a list more
	consistent.
--- Aaron Sloman, Aug 17 1999
	fixed handling in Ved and Xved in rc_async_apply
--- Aaron Sloman, Aug 16 1999
	Some previous changes prevented second-level event handling. Now fixed
--- Aaron Sloman, Aug 11 1999
	Changed to work in Xved
--- Aaron Sloman, Jul 31 1999
	Replaced rc_hide_menu with rc_hide_panel, rc_kill_menu with rc_kill_panel)
	Make default to "defer" all actions associated with Action buttons.
	use POPNOW to make the action immediate.
	Is "DEFER" now redundant?
	;;; Make this false to prevent attempts to redirect output
	global vars async_vedbuffer = 'output.p';
	Introduced rc_async_apply
	These old autoloadable libraries are now not needed, but are left
		in case they are still used somewhere:
			rclib/auto/async_apply.p
			rclib/auto/async_compile.p
--- Aaron Sloman, Jul 30 1999
	Fixed problems connected with sliders with panels for blobs.
--- Aaron Sloman, Jul 29 1999
	Changed default value of async_vedbuffer from 'OUTPUT' to 'output.p'
	to avoid proliferation of files?
--- Aaron Sloman, May 25 1999
	Suppressed rc_move_to for action buttons.
--- Aaron Sloman, May 21 1999
	Fixed drawing of border for invisible buttons on exit
--- Aaron Sloman, May  4 1999
	Added rc_button_do_no_drag, specifically for invisible buttons
--- Aaron Sloman, May  1 1999
	added rc_action_button_x, rc_action_button_y
--- Aaron Sloman, Apr 30 1999
	Added class and methods for "invisible" action button
--- Aaron Sloman, Apr 18 1999
	Allowed optional extra specs in counter buttons and toggle buttons
	Allowed featurespec keys to be abbreviated, via the user updatable
	property rc_button_spectrans
--- Aaron Sloman, Apr 13 1999
	Added rc_counter_min rc_counter_max, and new counter button format
	to specify optional upper and lower bounds.
--- Aaron Sloman, Apr 11 1999
	Made updaterof rc_informant_value(val, button:rc_display_button);
	redraw the button, except when creating_button is true.
	Added updater for rc_options_chosen
--- Aaron Sloman, Apr  3 1999
	Added rc_set_button_defaults for setting defaults for radio or someof
	buttons. Used in rc_control_panel
--- Aaron Sloman, Mar 30 1999
	Made the reactors for radio and someof buttons set the values
	of the field identifiers, if they exist. Alter rc_polypanel
	to use this.
--- Aaron Sloman, Mar 29 1999
	Changes for new version of rc_informant_value
--- Aaron Sloman, Feb  8 1998
		Minor code cleanup
--- Aaron Sloman, Feb  6 1998
		Slightly increased spacing round blobs.
--- Aaron Sloman, Feb  4 1998
		Changed to use rc_draw_unscaled_blob for drawing blobs
--- Aaron Sloman, Feb  3 1998
	Changed default button length to 120, to be consistent with
	LIB * rc_control_panel
	Introduced global variable rc_in_button_handler set true when an
	action button is activated.

	May be needed for other buttons also.

--- Aaron Sloman, Nov  8 1997
	Revamped everything so that sizes and appearances of buttons are not affected
	by changes to rc_xscale and rc_yscale. All drawing is relative to the TOP LEFT
	corner of a button or a button array.

	Introduced new methods.
		rc_draw_button_background
		rc_draw_button_string
		rc_draw_border
		rc_draw_button

	Renamed all the default value strings to end in '_def' and added
		rc_toggle_labels_def
		rc_counter_brackets_def

--- Aaron Sloman, Nov  6 1997
		Did some rounding of line_widths

--- Aaron Sloman, Aug 10 1997
	Made rc_DRAWBUTTON take an argument
--- Aaron Sloman, Aug  2 1997
	relise method changed to make windows only button sensitive.
--- Aaron Sloman, Jul 22 1997
	pre-compiled button actions, for efficiency and easier debugging
--- Aaron Sloman, Jul 10 1997
	Added property rc_button_type_key
--- Aaron Sloman, Jul  8 1997
	replaced rc_button*_info with rc_informant_value
	introduced rc_information_changed
--- Aaron Sloman, Jul  5 1997
	Made rc_options_chosen stop after finding first radio button,
	and return a list for non radio buttons
--- Aaron Sloman, Jun 30 1997
	redefined select button as being of type option
	allowed several types of buttons to have separate label and info
	contents, where the label is a two element list or vector
--- Aaron Sloman, Jun 29 1997
	Extended facilities for someof_buttons, including rc_options_chosen

	Moved some inessentials to LIB * RC_BUTTON_UTILS

--- Aaron Sloman, Jun 28 1997
	
	Altered to allow extra feature spec option for individual
		buttons in list or vector.

	Added rc_inform_button_siblings
	Added "nodraw" option to create_rc_button
	Added slot rc_button_container for all buttons, and, for all buttons:
		rc_current_window_object -> rc_button_container(button);

--- Aaron Sloman, Jun 21 1997
	Attempted to sort out handling of postponed Ved actions.
	Changed to re-enable events in some button actions
	Also allowed action to be vector of form {[proc arg1 arg2 arg3 ...]}
--- Aaron Sloman, Jun 20 1997
	Added slot rc_*button_info
--- Aaron Sloman, Jun 15 1997
	removed some redundant create_... definitions.
--- Aaron Sloman, May  4 1997
	Added rc_kill_menu
--- Aaron Sloman, May  3 1997
	Added radio buttons
--- Aaron Sloman, May  1 1997
	Rationalised interpretation of button actions.
	Added rc_flush_everything
--- Aaron Sloman, Apr 25 1997
	Stopped error if mouse moves into action button with button down,
	and button is then released.
--- Aaron Sloman, Apr 22 1997
	Many changes, including feature specs, HELP RC_BUTTONS.
	Also allowed action button to have an ident as its action.
	Allowed rc_counter_inc to be an ident in a counter button.

--- Aaron Sloman, Apr 15 1997
	Changed to allow numbers as labels
--- Aaron Sloman, Apr 14 1997
	Radically re-written and generalised
--- Aaron Sloman, Mar 17 1997
	Changed rc_current_object to rc_active_picture_object
--- Aaron Sloman, Jan  8 1997
	Changed for new sensitive area. Also redefined default buttons
 */
/*
CONTENTS (define)

 define -- New class of window object (rc_button_window)
 define :class vars rc_button_window; is rc_window_object;
 define :method rc_realize_window_object(win_obj:rc_button_window);
 define -- Globals holding default values for button appearance
 define :rc_defaults;
 define -- rc_button and rc_display_button mixins
 define :mixin vars rc_button;
 define :mixin vars rc_display_button;
 define -- The main button classes: action, blob, toggle,etc.
 define :class vars rc_action_button; is rc_button;
 define :class vars rc_invisible_action_button; is rc_action_button;
 define :class vars rc_blob_button; is rc_action_button;
 define :class vars rc_toggle_button; is rc_display_button rc_button;
 define :class vars rc_counter_button; is rc_display_button rc_button;
 define :class vars rc_option_button; is rc_display_button rc_button;
 define :class vars rc_radio_button; is rc_option_button;
 define :class vars rc_someof_button; is rc_radio_button;
 define -- Utility methods
 define :method rc_move_to(pic:rc_button, x, y, trail);
 define -- generic button methods for values/contents, etc.
 define lconstant DEREF(item) -> item;
 define :method rc_button_value(pic:rc_display_button) -> val;
 define :method updaterof rc_button_value(val, pic:rc_display_button);
 define :method updaterof rc_button_value(val, pic:rc_radio_button);
 define :method rc_toggle_value(pic:rc_toggle_button);
 define :method updaterof rc_toggle_value(val, pic:rc_toggle_button);
 define :method rc_counter_value(pic:rc_counter_button);
 define :method updaterof rc_counter_value(val, pic:rc_counter_button);
 define :method rc_option_chosen(pic:rc_option_button);
 define :method updaterof rc_option_chosen(val, pic:rc_option_button);
 define :method updaterof rc_informant_value(val, button:rc_display_button);
 define :method updaterof rc_informant_value(val, button:rc_counter_button);
 define -- Some dummy methods for buttons with missing slots
 define :method updaterof rc_button_pressedcolour(x, pic:rc_button);
 define :method updaterof rc_button_blobcolour(x, pic:rc_button);
 define :method updaterof rc_button_blobrad(x, pic:rc_button);
 define :method updaterof rc_counter_brackets(x, pic:rc_button);
 define :method updaterof rc_toggle_labels(x, pic:rc_button);
 define :method updaterof rc_chosen_background(x, pic:rc_button);
 define :method updaterof rc_radio_select_action(x, pic:rc_button);
 define :method updaterof rc_radio_deselect_action(x, pic:rc_button);
 define -- Utility methods and procedures
 define :method print_instance(pic:rc_button);
 define :method print_instance(pic:rc_display_button);
 define :method print_instance(pic:rc_counter_button);
 define :method print_instance(pic:rc_toggle_button);
 define :method print_instance(pic:rc_radio_button);
 define :method print_instance(pic:rc_someof_button);
 define :method print_instance(pic:rc_action_button);
 define -- Drawing methods and procedures for buttons
 define lconstant DRAW_OB(x, y, xinc, yinc, width, height, border, radius, colour);
 define :method rc_draw_border_shape(pic:rc_button, x, y, width, height, border, halfborder, colour);
 define :method rc_draw_border(pic:rc_button, colour);
 define :method rc_draw_border(pic:rc_invisible_action_button, colour);
 define :method rc_setframe_draw_border(pic:rc_button, colour);
 define :method rc_setframe_draw_border(pic:rc_invisible_action_button, colour);
 define :method rc_draw_button_type(pic:rc_display_button, blobrad, height, colour);
 define :method rc_draw_button_type(pic:rc_radio_button, blobrad, height, colour);
 define :method rc_draw_button_type(pic:rc_someof_button, blobrad, height, colour);
 define :method rc_offset_print_button_label(pic:rc_button, stringx, stringy, label);
 define :method rc_offset_print_button_label(pic:rc_display_button, stringx, stringy, label);
 define :method rc_offset_print_button_label(pic:rc_invisible_action_button, stringx, stringy, label);
 define :method rc_string_offset(pic:rc_button, border, blob_rad) -> offset;
 define :method rc_string_offset(pic:rc_display_button, border, blob_rad) -> offset;
 define :method rc_draw_button_string(pic:rc_button, blob_rad, border, width, height);
 define :method rc_draw_border_or_blob(pic:rc_button);
 define :method rc_draw_button_blob(pic:rc_display_button);
 define :method rc_draw_border_or_blob(pic:rc_display_button);
 define :method draw_action_blob(pic:rc_button, mid, border, blob_rad);
 define :method rc_draw_button_background(pic:rc_button, mid, border, blob_rad, width, height);
 define :method rc_draw_button_background(pic:rc_display_button, mid, border, blob_rad, width, height);
 define :method rc_draw_button(pic:rc_button);
 define :method rc_draw_button(pic:rc_invisible_action_button);
 define :method rc_draw_button(pic:rc_toggle_button);
 define vars rc_DRAWBUTTON(pic);
 define -- Undrawing methods for buttons
 define :method rc_undraw_button_background(pic:rc_button, mid, border, blob_rad, width, height);
 define :method rc_undraw_button(pic:rc_button);
 define :method rc_undraw_linepic(pic:rc_button);
 define -- Mouse and motion methods for windows and buttons
 define :method rc_button_1_up(win_obj:rc_button_window, x, y, modifiers);
 define :method rc_mouse_exit(win_obj:rc_button_window, x, y, modifiers);
 define :method rc_button_do_nothing(pic:rc_button, x, y, modifiers);
 define :method rc_button_do_no_drag(pic:rc_button, x, y, modifiers);
 define :method rc_drag_invisible(pic:rc_invisible_action_button, x, y, modifiers);
 define :method rc_rcbutton_1_down(pic:rc_button, x, y, modifiers);
 define :method rc_rcbutton_1_up(pic:rc_button, x, y, modifiers);
 define -- Facilities for action buttons
 define rc_async_apply(proc, deferring);
 define :method rc_async_apply_action(pic:rc_button, action_type);
 define :method rc_do_button_action(pic:rc_action_button);
 define :method rc_rcbutton_1_down(pic:rc_action_button, x, y, modifiers);
 define :method rc_rcbutton_1_down(pic:rc_invisible_action_button, x, y, modifiers);
 define vars do_rcbutton_1_up(pic, x, y, modifiers);
 define :method rc_rcbutton_1_up(pic:rc_action_button, x, y, modifiers);
 define :method rc_rcbutton_1_up(pic:rc_invisible_action_button, x, y, modifiers);
 define -- Facilities for display buttons
 define :method switch_rc_toggle_value(pic:rc_toggle_button);
 define :method rc_rcbutton_1_down(pic:rc_toggle_button, x, y, modifiers);
 define :method rc_rcbutton_1_up(pic:rc_toggle_button, x, y, modifiers);
 define -- Facilities for counter buttons
 define lconstant procedure stack_chars_from(item);
 define :method rc_draw_button(pic:rc_counter_button);
 define lconstant restrict_to_range(val, minval, maxval) -> val;
 define :method rc_increment_counter(pic:rc_counter_button, up);
 define :method rc_rcbutton_1_down(pic:rc_counter_button, x, y, modifiers);
 define :method rc_rcbutton_1_up(pic:rc_counter_button, x, y, modifiers);
 define :method rc_rcbutton_3_down(pic:rc_counter_button, x, y, modifiers);
 define -- Facilities for option buttons
 define :method rc_draw_button(pic:rc_option_button);
 define :method rc_rcbutton_1_down(pic:rc_option_button, x, y, modifiers);
 define rc_button_with_label(item, buttonlist) -> button;
 define rc_options_chosen_for(buttons, procedure proc) -> options;
 define rc_options_chosen = rc_options_chosen_for(%rc_button_label%);
 define rc_values_chosen = rc_options_chosen_for(%rc_real_contents%);
 define updaterof rc_options_chosen(options, buttons);
 define -- Facilities for radio buttons
 define :method rc_rcbutton_1_down(pic:rc_radio_button, x, y, modifiers);
 define rc_set_radio_buttons(item, buttons);
 define rc_set_button_defaults(buttons, wid, def, buttontype);
 define -- Facilities for someof buttons
 define :method rc_rcbutton_1_down(pic:rc_someof_button, x, y, modifiers);
 define set_or_unset_someof_buttons_to(list, buttons, setting);
 define rc_set_someof_buttons = set_or_unset_someof_buttons_to(%true%)
 define rc_unset_someof_buttons = set_or_unset_someof_buttons_to(%false%)
 define rc_change_someof_buttons = set_or_unset_someof_buttons_to(%undef%)
 define -- Abbreviations for feature spec items
 define procedure rc_button_spectrans = newproperty(
 define expand_button_spec_abbreviations(spec) -> spec;
 define -- Utilities for modifying buttons during creation
 define vars rc_update_button_mouse_limit(button, oldborder, oldheight, oldwidth);
 define :method modify_instance(button:rc_button, contents, type);
 define :method modify_instance(button:rc_action_button, contents, type);
 define :method modify_instance(button:rc_invisible_action_button, contents, type);
 define :method modify_instance(button:rc_display_button, contents, type);
 define :method modify_instance(button:rc_toggle_button, contents, type);
 define :method modify_instance(button:rc_counter_button, contents, type);
 define :method modify_instance(button:rc_option_button, contents, type);
 define -- Utilities for creating new buttons
 define procedure rc_button_type_key = newproperty(
 define rc_button_key_of_type(type) -> key;
 define create_rc_button(x, y, width, height, contents, type, specs) -> button;
 define -- Procedures for creating rows, columns and arrays of buttons
 define create_button_columns(x, y, width, height, spacing, columns, list, type, specs) -> buttons;
 define rc_inform_button_siblings(buttons);

*/
