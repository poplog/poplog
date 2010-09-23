/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_control_panel.p
 > Purpose:         Create a control panel, with strings and buttons
 > Author:          Aaron Sloman, Jun 26 1997 (see revisions)
 > Documentation:	HELP * RC_CONTROL_PANEL, HELP * RCLIB
 > Related Files:	LIB * RCLIB and much of $poplocal/local/rclib/ *
 */

section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

uses rclib
uses rc_defaults
uses rc_window_object
uses rc_informant
uses rc_buttons
;;; uses rc_default_window_object
uses rc_text_area
uses rc_text_input
uses rc_slider
uses rc_opaque_slider
uses rc_scrolltext
uses rc_print_strings
uses rc_dial

;;; global variable to hold the latest control panel, especially for
;;; killing an incompletely finished one during debugging

global vars
	;;; The panel being constructed, or last panel constructed
	rc_current_panel,
	;;; the field currently being constructed. Do we need this???
	rc_current_panel_field;

/*
define -- Variables to control default fonts and colours on panel
*/

;;; global variables to control the control panel and message display
;;; NB rc_buttons has defaults for button fonts and colours, etc.

define :rc_defaults;
	;;; Main panel defaults
	rc_panel_font_def =
		'-adobe-helvetica-bold-r-normal-*-10-*-*-*-p-*-*-*';
		;;; could be '10x20';
	rc_panel_bg_def = 'grey40';
	rc_panel_fg_def = 'grey90';
	;;; minimum left right margin
	rc_field_offset_def = 3;
	rc_field_gap_def = 0;

	;;; Field defaults
	rc_field_font_def =
		'-adobe-helvetica-bold-r-normal-*-12-*-*-*-p-*-*-*';
		;;; or '10x20'
	rc_field_fg_def = false;	;;; can be redefined locally
	rc_field_bg_def = false;	;;; can be redefined locally
    rc_dial_field_bg_def = false;
	;;; text fields
	rc_text_field_font_def = rc_field_font_def;
		;;; or '10x20', or ...
	rc_text_field_bg_def = 'grey10';
	rc_text_field_fg_def = 'grey90';
	;;; default top bottom margin in text field
	rc_text_field_margin_def = 2;

	;;; Scrolltext fields

	rc_scroll_text_field_font_def = '6x13';
		;;; or '7x12';

	;;; slider fields
	rc_slider_offset_def = 15;
	rc_slider_field_radius_def = 6;
	rc_slider_field_width_def = 200;
	rc_slider_field_height_def = 35;
	rc_slider_field_font_def =
		'-adobe-helvetica-bold-r-normal-*-10-*-*-*-p-*-*-*';
		;;;; previously '8x13';
	;;; next two may not be needed
	rc_slider_field_bg_def = 'grey85';
	rc_slider_field_fg_def = 'grey10';
	rc_graphic_field_bg_def = 'grey40';
	rc_graphic_field_fg_def = 'grey90';
	rc_slider_field_blobcol_def = 'grey20';
	rc_slider_field_barcol_def = 'grey70';
	rc_slider_field_barframecol_def = false;
	rc_slider_field_barframewidth_def = 2;
	rc_slider_field_value_panel_def =
    ;;; {endnum bg     fg     font
        {2   'grey90' 'black' ^rc_slider_field_font_def
                                ;;; places px py length ht fx fy}
                                    2    15  0  70    16 12 -4};

	rc_slider_field_labelfont_def = false;

	;;; dial fields defaults. Others in LIB rc_constrained_pointer
	rc_dial_field_width_def = 60;
	rc_dial_field_height_def = 30;
	rc_min_dial_width = 60;
	rc_dial_offset_def = round(0.5*rc_min_dial_width);
	rc_dial_base_def = 10;

	;;; button fields (someof, radio, action)
	rc_buttons_field_font_def =
		'-adobe-helvetica-bold-r-normal-*-10-*-*-*-p-*-*-*';
		;;; previously '*lucida*-r-*sans-12*';
		;;; Other possibilities '9x15'; '8x13bold', etc.;
/*
	;;; not used yet. Perhaps never.
	rc_buttons_field_bg_def = 'grey10';
	rc_buttons_field_fg_def = 'grey90';
*/
	;;; Just inherit the last three from LIB * RC_BUTTONS
	rc_buttons_bordercol_def = rc_button_bordercolour_def;
	rc_buttons_pressedcolour_def = rc_button_pressedcolour_def;
	rc_buttons_field_borderwidth_def = rc_button_border_def;
	rc_field_override_specs_def = [];
enddefine;	

global vars
	;;; Use two defaults from LIB * RC_BUTTONS
	rc_button_width_def, 	;;; 120
	rc_button_height_def,	;;; 24
	;


/*
define -- The main class, containing window and other items
*/

define :class vars rc_panel is rc_button_window;
	;;;; define :class rc_panel is rc_window_object;
	;;; This will hold a list of field descriptors
	slot rc_panel_fields == [];
	;;; Colours and font
	slot rc_panel_bg = rc_panel_bg_def;
	slot rc_panel_fg = rc_panel_fg_def;
	slot rc_panel_font = rc_panel_font_def;
	slot rc_panel_xorigin = 0;
	slot rc_panel_yorigin = 0;
	slot rc_panel_xscale = 1;
	slot rc_panel_yscale = 1;
	slot rc_panel_offset = 0;
	slot rc_panel_objects == false;	;;; changed later
	slot rc_panel_width;
	slot rc_panel_height;
enddefine;

define :method rc_print_fields(panel:rc_panel, printlevel);
	dlocal
		pop_oc_print_level = 1,
		pop_pr_level = printlevel,
		pop_pr_quotes = true,
		;
    applist(rc_panel_fields(panel), pretty);
enddefine;

/*
define -- mixin for fields containing text, buttons, etc
*/

define :mixin vars rc_panel_field;
	slot rc_field_x == undef;
	slot rc_field_y == undef;
	slot rc_field_label == consundef("rc_field_label");	
	slot rc_field_ident == false; ;;; for classes with rc_informant_ident
	slot rc_field_gap = rc_field_gap_def;
	slot rc_field_offset = rc_field_offset_def;
	slot rc_field_font = rc_field_font_def;
	slot rc_field_spacing == 1;
	slot rc_field_aligned == "centre";
	slot rc_field_width == 0;
	slot rc_field_height == 0;
	slot rc_field_margin == 0;
	slot rc_field_cols == 0;
	slot rc_field_rows == 0;
	slot rc_field_fg = rc_field_fg_def;
	slot rc_field_bg = rc_field_bg_def;
	;;; This will have a list of specifications of the fields.
	;;; not strictly necessary, except for debugging?
	slot rc_field_specs == [];
	slot rc_field_override_specs = rc_field_override_specs_def ;
    ;;; These are the objects created from the specifications
    ;;;     e.g. a list of buttons, or strings, or sliders, etc.
	slot rc_field_contents == [];
	;;; used to fill rc_constrain_contents slot
	slot rc_field_constraint == identfn;
	;;; used to fill rc_informant_reactor slot (2-arg procedure or list)
	slot rc_field_reactor == erasenum(%2%);
	;;; The window object will go in here
	slot rc_field_container == 'NEW PANEL WINDOW';
enddefine;


/*
define -- Text, scrolltext, multiscrolltext textin, multitextin, slider and button field classes
*/

define :class vars rc_text_field is rc_panel_field;
	slot rc_field_font = rc_text_field_font_def;
	slot rc_field_bg = rc_text_field_bg_def;
	slot rc_field_fg = rc_text_field_fg_def;
	slot rc_font_h == 0;
	slot rc_field_margin = rc_text_field_margin_def;
enddefine;

define :class vars rc_scroll_text_field is rc_text_field;
	slot rc_field_text_fg == 'black';
	slot rc_field_text_bg == 'grey90';
	slot rc_field_font = rc_scroll_text_field_font_def;
			;;; previously '8x13';
	;;; The colour of the surround of a scrolltext field (where sliders are)
	slot rc_scroll_text_field_slidercol == 'grey85';
	;;; colour of the moving part of a slider
	slot rc_scroll_text_field_blobcol == 'grey50';
	slot rc_scroll_text_field_blobrad == 6;
	;;; not used for now
	slot rc_scroll_text_field_sliderframecol == 'black';
	;;; default no frame visible. No longer used??
	slot rc_scroll_text_field_sliderframewidth = 0;
	slot rc_scroll_text_field_acceptor == "rc_handle_accept" ;
	slot rc_scroll_text_field_slider_type == "blob";	;;; may become "panel" or "blob"
	slot rc_scroll_text_numrows;
	slot rc_scroll_text_numcols;
	slot rc_text_w == 0;
	slot rc_text_h == 0;
enddefine;

define :class vars rc_multiscroll_text_field is rc_scroll_text_field;

enddefine;

define :class vars rc_textin_field is rc_text_field;
	;;; field with a text input panel
	slot rc_field_aligned == "left";
	slot rc_field_spacing = 3 + rc_text_border_width_def;
	;;; next constants defined in LIB RC_TEXT_INPUT
	slot rc_textfield_width = rc_text_length_def;
	slot rc_textfield_height = rc_text_height_def;
	slot rc_field_font = rc_text_font_def;
	slot rc_field_borderwidth = rc_text_border_width_def;
	slot rc_field_bg = rc_text_input_bg_def;
	slot rc_field_fg = rc_text_input_fg_def;
	slot rc_textin_field_bg = rc_text_input_bg_def ;
	slot rc_textin_field_active_bg = rc_text_input_active_bg_def;
	slot rc_textin_field_fg = rc_text_input_fg_def;
	slot rc_field_labelstring == nullstring;
	slot rc_field_labelfont = rc_text_field_font_def;
	slot rc_field_labelcolour = rc_text_field_fg_def;
	;;; This may be replaced in number input files
	slot rc_field_creator = newrc_text_button;
enddefine;


define :class vars rc_multitextin_field is rc_textin_field;
	;;; used for multiple text or number input panels in one field
	slot rc_field_creator = newrc_text_button;
enddefine;


define :class vars rc_slider_field is rc_panel_field;
	slot rc_field_font = rc_slider_field_font_def;
	slot rc_field_bg = rc_slider_field_bg_def;
	slot rc_field_fg = rc_slider_field_fg_def;
	slot rc_slider_field_blobcol = rc_slider_field_blobcol_def;
	slot rc_slider_field_barcol = rc_slider_field_barcol_def;
	slot rc_slider_field_barframecol = rc_slider_field_barframecol_def;
	slot rc_slider_field_barframewidth = rc_slider_field_barframewidth_def;
	slot rc_field_margin = rc_slider_field_barframewidth_def;
	slot rc_field_offset = rc_slider_offset_def;
	;;; not really needed
	;;; slot rc_field_labels == [[{5 5 'MIN'}][{5 5 'MAX'}]];
	slot rc_field_cols == 1;
	slot rc_field_width = rc_slider_field_width_def;
	slot rc_field_height == 0;
	slot rc_field_type == false;
	slot rc_slider_field_height = rc_slider_field_height_def;
	slot rc_slider_field_radius = rc_slider_field_radius_def;
	slot rc_slider_field_step == false; ;;; don't change default
	slot rc_slider_field_value_panel = rc_slider_field_value_panel_def ;
	slot rc_slider_field_labelfont = rc_slider_field_labelfont_def;
	slot rc_slider_field_textin == true;
	slot rc_slider_convert_in == identfn;
	slot rc_slider_convert_out == identfn;
	slot rc_slider_field_places == false;
enddefine;

define :class vars rc_dial_field is rc_panel_field;
	;;; use some defaults from LIB rc_constrained_pointer
	slot rc_field_bg = rc_field_bg_def;
	slot rc_dial_field_bg = rc_dial_field_bg_def;
	slot rc_field_margin == 4;
	slot rc_field_offset = rc_dial_offset_def;
	slot rc_field_cols == 1;
	slot rc_field_width = rc_dial_field_width_def;
	slot rc_field_height = rc_dial_field_height_def;
	slot rc_dial_width = rc_min_dial_width;
	slot rc_dial_height = rc_min_dial_width*0.7;
	slot rc_dial_base = rc_dial_base_def;
	slot rc_dial_field_count == 0;
	slot rc_dial_field_places == false;
enddefine;


define :class vars rc_buttons_field is rc_panel_field;
	;;; General buttons field
	slot rc_field_font = rc_buttons_field_font_def;
	slot rc_field_bordercol = rc_buttons_bordercol_def;
	slot rc_field_pressedcolour = rc_buttons_pressedcolour_def;
	slot rc_field_borderwidth = rc_buttons_field_borderwidth_def;
	slot rc_button_width = rc_button_width_def;
	slot rc_button_height = rc_button_height_def;
	slot rc_field_text_fg = rc_button_stringcolour_def;
	slot rc_field_text_bg = rc_button_labelground_def;
enddefine;


/*
define -- -- Special buttons field sub-classes
*/

define :class vars rc_actions_field is rc_buttons_field;
	;;; field with actions buttons
enddefine;

define :class vars rc_radio_field is rc_buttons_field;
	;;; field with radio buttons
	slot rc_radio_select_action == false;
	slot rc_buttons_default == undef;
	slot rc_buttons_options == [];
	slot rc_chosen_background = rc_button_chosenground_def;
enddefine;

define :class vars rc_someof_field is rc_buttons_field;
	;;; field with someof buttons
	slot rc_radio_select_action == false;
	slot rc_radio_deselect_action == false;
	slot rc_buttons_default == undef;
	slot rc_buttons_options == [];
	slot rc_chosen_background = rc_button_chosenground_def;
enddefine;




/*
define -- graphic_field
*/

define :class vars rc_graphic_field is rc_panel_field;
	;;; General graphics field
	;;; field containing information to produce graphics
	slot rc_field_graphics == [];
	;;; slot rc_field_offset = 0;
	slot rc_field_aligned == "centre";
	;;; default offsets from top left corner of graphic field.
	slot rc_field_xorigin_offset == 0;
	slot rc_field_yorigin_offset == 0;
	slot rc_field_xscale == 1;
	slot rc_field_yscale == 1;
	slot rc_field_bg = rc_graphic_field_bg_def;
	slot rc_field_fg = rc_graphic_field_fg_def;
enddefine;


define interpret_graphic_spec(spec, field, x, y, aligned, width, height);
	;;; x and y specify coordinate origin for the picture

	;;; [GRAPHIC ^field ]=>
	;;; If the offsets are numbers use them to change the origin.
	lvars xorigin = rc_field_xorigin_offset(field),
		yorigin = rc_field_yorigin_offset(field);
	unless rc_field_aligned(field) == "panel" then

		dlocal
			rc_xorigin =
			if isnumber(xorigin) then x + xorigin else x endif,
			rc_yorigin =
			if isnumber(yorigin) then y + yorigin else y endif,
			rc_xscale = rc_field_xscale(field),
			rc_yscale = rc_field_yscale(field);

	endunless;

	if isword_or_ident(spec) then recursive_valof(spec)()
	elseif isprocedure(spec) then spec()
	elseif hd(spec) == "POP11" then
		pop11_compile(tl(spec))
	else recursive_valof(hd(spec))()
	endif
enddefine;

define :method rc_draw_graphic_field(field:rc_graphic_field, x, y, aligned, width, height);
	;;; x and y already scaled, etc.

	lvars
		fg = rc_field_fg(field), bg = rc_field_bg(field),
		panel = rc_field_container(field),
		x_offset = rc_field_offset(field),
		;;; middle of field
		half_height = height*0.5*sign(rc_yscale),
		y_offset = half_height,
		p_xorigin = rc_panel_xorigin(panel),
		p_yorigin = rc_panel_yorigin(panel),
		xscale = rc_panel_xscale(panel),
		yscale = rc_panel_yscale(panel),
		(oldxstart, oldystart) = rc_transxyout(x, y)
		;

	dlocal rc_xorigin,rc_yorigin;

	if aligned == "right" then
		oldxstart + width - x_offset -> rc_xorigin;
		oldystart  -> rc_yorigin;
		;;; (width*rc_xscale - x_offset) -> x_offset;
	elseif aligned == "left" then
		oldxstart + x_offset -> rc_xorigin;
		oldystart -> rc_yorigin;
		;;; 0 -> x_offset;
	elseif aligned == "centre" then
		round(oldxstart + (width div 2)) -> rc_xorigin;
		oldystart + half_height*rc_yscale -> rc_yorigin;
		;;; -(width div 2)*(rc_xscale) + x_offset -> x_offset;
	elseif aligned == "panel" then
		;;; keep the origin unchanged.
		;;; oldxstart + x_offset -> rc_xorigin;
		;;; 0 -> rc_yorigin;
	endif;
	

	dlocal %rc_foreground(rc_window)% = fg;

	lvars spec, field_specs = rc_field_specs(field);

	if isprocedure(spec) then spec()
	else
		for spec in field_specs do
			if spec == [] then
				;;; do nothing -- blank field
			elseif islist(spec) and hd(spec) == "DEFER" then
				rc_defer_apply(
					interpret_graphic_spec(%tl(spec), field, rc_xorigin, rc_yorigin, aligned, width, height%));
			else
				interpret_graphic_spec(spec, field, rc_xorigin, rc_yorigin, aligned, width, height);
			endif
		endfor
	endif;

enddefine;


/*
define -- Utility procedures and methods
*/

/* ;;; tests for rc_translate_panel_spec

vars vec1 = {cat dog reactor fred mouse bad};
rc_translate_panel_spec(vec1);
vec1=>
vars vec2 = [cat dog reactor fred mouse bad];
rc_translate_panel_spec(vec2);
vec2=>

*/


;;; Abbreviations for slot names for things like sliders,
;;; dials, etc.
;;; Maybe other abbreviations  will be useful later.
;;; Used by rc_translate_panel_spec

global vars
	rc_panel_abbreviations =
		[reactor ^rc_informant_reactor
		 ident ^rc_informant_ident
		 constrain ^rc_constrain_contents
		 constraint ^rc_constrain_contents
		];

define rc_translate_panel_spec(specs) -> specs;
	;;; replace items in rc_panel_abbreviations by their expansions
	lvars index, rest, slot, key;

	if isvector(specs) then
		for index from 1 by 2 to datalength(specs) - 1 do
			fast_subscrv(index, specs) -> key;
			if lmember(key, rc_panel_abbreviations) ->> rest then
				if listlength(rest) mod 2 == 0 then
					;;; key is an abbreviation so replace it
					fast_front(fast_back(rest)) -> fast_subscrv(index, specs)
				endif;
			endif;
		endfor;
	else
		;;; assume it is a list
		for index from 1 by 2 to listlength(specs) - 1 do
			fast_subscrl(index, specs) -> key;
			if lmember(key, rc_panel_abbreviations) ->> rest then
				if listlength(rest) mod 2 == 0 then
					;;; key is an abbreviation so replace it
					fast_front(fast_back(rest)) -> fast_subscrl(index, specs)
				endif;
			endif;
		endfor;
	endif;
enddefine;


define :method rc_field_coords(field:rc_panel_field) /* -> (x,y) */;
	rc_field_x(field);
	rc_field_y(field);
enddefine;

define :method updaterof rc_field_coords(field:rc_panel_field);
	-> rc_field_y(field);
	-> rc_field_x(field);
enddefine;

define :method print_instance(f:rc_panel_field);
	dlocal
		pop_oc_print_level = 1,
		pop_pr_level = 3,
		pop_pr_quotes = true,
		;
	;;; simplify printing of field instances
	dlocal pop_=>_flag = 'Contents: ';

	lvars
		label = rc_field_label(f),
		container = rc_field_container(f);;

	printf('<%P,(%P %P) Label: %P, In: %P,\n',
		[%class_dataword(datakey(f)),
			rc_field_coords(f),
			if isundef(label) then 'nolabel' else label endif,
			if isrc_window_object(container) then 			
		  			rc_window_title(container)
			else container
			endif%]);
		 rc_field_contents(f) =>
		 ;;; applist(rc_field_contents(f), npr);
	printf('>\n');
enddefine;


define :method rc_field_of_label(panel:rc_panel, label) -> field;
	;;; get the field which has the label, or if label is an integer N
	;;; get the Nth field from the panel
	lvars field;
	if isinteger(label) then
		rc_panel_fields(panel)(label)
	else
		for field in rc_panel_fields(panel) do
			if rc_field_label(field) = label then
				return();
			endif
		endfor;
		false -> field;
	endif;
enddefine;

define :method rc_fieldcontents_of(panel:rc_panel, label) -> list;
	;;; get the information content of the field
	;;; with the label
	rc_field_contents(rc_field_of_label(panel, label)) -> list;
enddefine;

define :method rc_field_item_of_name(panel:rc_panel, label, num) -> item;
	;;; Find the field of the panel named by the label, and get its contents,
	;;; a list or a text or number input field.
	;;; Returb the numth item from the list, or the contents if it's
	;;; a text input or number input field.
	lvars fieldcontents = rc_fieldcontents_of(panel, label);
	if num == 1 and isrc_text_input(fieldcontents)
		;;; or isrc_number_input(fieldcontents))
	then
		rc_text_value(fieldcontents)
	else
		rc_informant_value(fieldcontents(num))
	endif-> item;
enddefine;

define :method updaterof rc_field_item_of_name(item, panel:rc_panel, label, num);
	;;; Update the numth item from the list, or the contents if it's
	;;; a text input or number input field.

	;;; Set current window object
	dlocal rc_current_window_object;
	unless panel == rc_current_window_object then
		panel -> rc_current_window_object
	endunless;

	lvars
		field = rc_field_of_label(panel, label),
		fieldcontents = rc_field_contents(field),
		component = false;

	if islist(fieldcontents) and length(fieldcontents) <= num then
		fieldcontents(num) -> component
	endif;

	if isrc_text_input(fieldcontents) and num == 1 then
		item -> rc_text_value(fieldcontents)
	elseif isrc_slider_field(field) then
		dlocal rc_constrain_slider = true;
		item -> rc_informant_value(fieldcontents(num))
	elseif isrc_dial_field(field) then
		item -> rc_pointer_value(fieldcontents(num))
	elseif isrc_display_button(component) then
		item -> rc_button_value(component);
	else
		 item -> rc_informant_value(fieldcontents(num))
	endif;
enddefine;


define rc_update_field(val, panel, field, num, converter);
    ;;; This is like the updater of rc_field_item_of_name, except that the
    ;;; val argument is first transformed by the converter.
	;;; If the panel argument is "." then it is taken to be
	;;; the current panel.
	if panel == "." then
		rc_current_window_object -> panel
	endif;

	;;; In case panel is a word or identifier, dereference it.
	;;; recursive_valof does not work for active variables.
	if isword_or_ident(panel) then
		recursive_valof(valof(panel)) -> panel
	endif;
    recursive_valof(converter)(val) -> rc_field_item_of_name(panel, field, num)
enddefine;

define vars procedure rc_update_fields(val, veclist);
    ;;; veclist should be a list of three or four element vectors
	;;; If there are four elements in a vector they form the
	;;; panel, field, num and converter arguments for rc_update_field.
	;;; If the fourth element is missing it is taken to be identfn.
	;;; If the panel argument is "." then it is taken to be
	;;; the current panel.
    lvars vec;
    for vec in veclist do
        rc_update_field(val, explode(vec),
            if datalength(vec) == 3 then identfn endif)
    endfor
enddefine;

define panel_update(object, val, veclist);
	;;; Like previousl version but with one extra argument (object) so that by
	;;; partially applying this to veclist we can directly create reactor
	;;; procedures as shown in TEACH RC_CONSTRAINED_PANEL

	;;; Ignore the object.
	rc_update_fields(val, veclist);
enddefine;


define rc_increment_slider(panel, label, num, inc);
	;;; Increment or decrement a slider value of numth slider in the field
	dlocal rc_constrain_slider = true;
	lvars
		slider = rc_field_contents(rc_field_of_label(panel, label))(num),
		val = rc_slider_value(slider) + inc;

	if isinteger(inc) then round(val) else val endif ->
			rc_slider_value(slider);
enddefine;

define :method slider_value_of_name(panel:rc_panel, label, num) -> val;
	;;; get value of numth slider in the field
	rc_slider_value(rc_fieldcontents_of(panel, label)(num)) -> val;
enddefine;

define :method updaterof slider_value_of_name(panel, label, num);
	;;; Set current window object
	dlocal rc_current_window_object;
	unless panel = rc_current_window_object then
		panel -> rc_current_window_object
	endunless;

	;;; set value of numth slider in the field
	-> rc_slider_value(rc_fieldcontents_of(panel, label)(num));
enddefine;

define rc_increment_dial(panel, label, num, inc);
	;;; Increment or decrement a dial value of numth dial in the field
	lvars
		dial = rc_field_contents(rc_field_of_label(panel, label))(num),
		val = rc_pointer_value(dial) + inc;

	if isinteger(inc) then round(val) else val endif ->
			rc_pointer_value(dial);
enddefine;

define :method dial_value_of_name(panel:rc_panel, label, num) -> val;
	;;; get value of numth dial in the field
	rc_pointer_value(rc_fieldcontents_of(panel, label)(num)) -> val;
enddefine;

define :method updaterof dial_value_of_name(panel, label, num);
	;;; Set current window object
	dlocal rc_current_window_object;
	unless panel = rc_current_window_object then
		panel -> rc_current_window_object
	endunless;

	;;; set value of numth dial in the field
	-> rc_pointer_value(rc_fieldcontents_of(panel, label)(num));
enddefine;


define :method rc_field_info_of_label(panel:rc_panel, label)/* -> possible info */;
	;;; get the information content of the field
	;;; with the label
;;;	panel -> rc_current_window_object;
	lvars field_list = rc_fieldcontents_of(panel, label);
	if field_list == [] then []
	else
		lvars first = front(field_list);
		if isrc_option_button(first) then
			;;; radio or someof button should return a single
			;;; option or a list
			rc_options_chosen(field_list)
		elseif isrc_slider(first) then
			maplist(field_list, rc_slider_value)
		elseif isrc_constrained_pointer(first) then
			maplist(field_list, rc_pointer_value)
		endif
	endif
enddefine;


define rc_check_options_available(info, field_options, panel, label);
	;;; When updating a someof or radio field, check that no attempt is being
	;;; made to turn on a non-existent button.
	lvars not_found = [];
	if islist(info) then
		;;; someof field
		lvars item;
		[% for item in info do
		 	unless member(item, field_options) then item endunless;
			endfor;
		%] -> not_found;

	else
		;;; radio field
		 unless member(info, field_options) then
			[^info] -> not_found;
		endunless;
	endif;
	unless not_found == [] then
		mishap('BAD OPTION(S) FOR BUTTONS UPDATE IN RADIO OR SOMEOF FIELD',
			[%not_found, label, rc_window_title(panel)%])
	endunless;
enddefine;

define :method updaterof rc_field_info_of_label(info, panel:rc_panel, label);
	;;; Set the information content of the field
	;;; with the label. Must be a RADIO or SOMEOF field, or a SLIDERS
	;;; or DIALS field.
	lvars
		field_list = rc_fieldcontents_of(panel, label),
		field_options = rc_buttons_options(rc_field_of_label(panel, label));

	;;; Set current window object
	dlocal rc_current_window_object;
	unless panel == rc_current_window_object then
		panel -> rc_current_window_object
	endunless;

	rc_check_options_available(info, field_options, panel, label);

	if field_list == [] then
		mishap(
			'EMPTY FIELD CONTENTS LIST IN PANEL',
				[% label, rc_window_title(panel) %]);
	else
		if isrc_option_button(front(field_list)) then
			info -> rc_options_chosen(field_list);
		else
			mishap('UPDATER OF rc_field_info_of_label CANNOT COPE',
				[% label, rc_window_title(panel) %]);
		endif;
	endif
enddefine;

define PANELFIELD(label);
	;;; for accessing a field in the current panel
	;;; needs an updater? Maybe useful in action buttons, etc.
	rc_field_info_of_label(rc_active_window_object, label)
enddefine;


/*
define -- The global variable: rc_control_panel_keyspec

This defines the mapping from field property specifications to field
slot methods.
*/

global vars rc_control_panel_keyspec =

	[
        ;;; specify keys usable in GRAPHIC fields
		[[GRAPHIC]
			{xorigin rc_field_xorigin_offset}
			{yorigin rc_field_yorigin_offset}
			{xscale rc_field_xscale}
			{yscale rc_field_yscale}
		]
        ;;; specify keys usable in GRAPHIC or TEXT fields
		[[GRAPHIC TEXT]
			{width rc_field_width}
			{height rc_field_height}
		]
        ;;; specify keys usable in SLIDER fields
		[[SLIDERS PANELSLIDERS]
			;;; remove this option??? (temporary for backward compatibility)
			;;; {bg rc_slider_field_barcol}
        	;;; Set "bar" colour for a slider
			{barcol rc_slider_field_barcol}
        	;;; Set "bar frame" colour for a slider
			{framecol rc_slider_field_barframecol}
        	;;; Set "bar frame" width for a slider
			{framewidth rc_slider_field_barframewidth}
			{height rc_slider_field_height}
        	;;; Slider indicator radius
			{radius rc_slider_field_radius}
        	;;; Slider minimum step
			{step rc_slider_field_step}
        	;;; Converter procedure for input to the slider
			{convert_in rc_slider_convert_in}
        	;;; Converter procedure for output from the slider
			{convert_out rc_slider_convert_out}
        	;;; Colour of slider blob
			{blobcol rc_slider_field_blobcol}
			{width rc_field_width}
			{panel rc_slider_field_value_panel}
			{labelfont rc_slider_field_labelfont}
			{textin rc_slider_field_textin}
			{places rc_slider_field_places}
        	;;; How the type is used will depend on the sort of field. E.g.
        	;;; for sliders the value "square" can indicate that a square
        	;;; "thumb" should be used. Otherwise it can be a creation procedure
			{type rc_field_type}
		]
		;;; keys specific to dials
		[[DIALS]
			{dialbg rc_dial_field_bg}
			{dialwidth rc_dial_width}
			{dialheight rc_dial_height}
			{dialbase  rc_dial_base}
		]
        ;;; Specify keys usable in all button-type fields
		[[RADIO SOMEOF ACTIONS DIALS]
			{width rc_button_width}
			{height rc_button_height}
			{textfg rc_field_text_fg}
			{textbg rc_field_text_bg}
        	;;; A number to specify the number of columns in a buttons field.
        	;;; If 0 then make it the number of buttons, i.e. all buttons in
        	;;; one row.
			{cols rc_field_cols}
		]
		;;; Keys for pressable ACTIONS buttons
		[[ACTIONS]
        	;;; The default border colour for pressable buttons
			{bordercol rc_field_bordercol}
        	;;; The border colour for buttons when they are pressed
			{pressedcol rc_field_pressedcolour}
        	;;; The width of button borders
			{borderwidth rc_field_borderwidth}
		]

        ;;; Specify keys usable in RADIO and SOMEOF fields
		[[RADIO SOMEOF]
			{default rc_buttons_default}
        	;;; Used to associate actions with radio and someof buttons
			{select rc_radio_select_action}
			{chosenbg rc_chosen_background}
		]
		[[SOMEOF]
        	;;; Used to associate actions with someof buttons
			{deselect rc_radio_deselect_action}
		]
        ;;; Specify keys usable in TEXTIN and NUMBERIN fields
		[[TEXTIN NUMBERIN MULTITEXTIN MULTINUMBERIN]
			{width rc_textfield_width}
			{height rc_textfield_height}
			{labelstring rc_field_labelstring}
			{labelfont rc_field_labelfont}
			{labelcolour rc_field_labelcolour}
			{activebg rc_textin_field_active_bg}
			{textinbg rc_textin_field_bg}
			{textinfg rc_textin_field_fg}
		]
;;; 		[[TEXTIN NUMBERIN ]
;;; 			{labelstring rc_field_labelstring}
;;;		]

		[[SCROLLTEXT]
			{cols rc_field_cols}
			{rows rc_field_rows}
			{textfg rc_field_text_fg}
			;;; {text_fg rc_field_text_fg}
			{textbg rc_field_text_bg}
			;;; {text_bg rc_field_text_bg}
			{blobrad rc_scroll_text_field_blobrad}
            ;;; The next two are equivalent
			{slidercol rc_scroll_text_field_slidercol}
			{surroundcol rc_scroll_text_field_slidercol}
			{blobcol rc_scroll_text_field_blobcol}
			{sliderframecol rc_scroll_text_field_sliderframecol}
			{sliderframewidth rc_scroll_text_field_sliderframewidth}
			{slidertype rc_scroll_text_field_slider_type}
			{acceptor rc_scroll_text_field_acceptor}
		]
        ;;; Specify keys usable in ALL fields
        ;;; (some may actually be meaningless for some fields.)
		[[]	
        	;;; Set a label for the field which can be used to access
        	;;; the field later
			{[label fieldlabel] rc_field_label}
            ;;; This makes sense only for fields which can be associated
            ;;; with a changing value.
			{ident  set_field_ident}
			{constrain rc_field_constraint}
			{reactor rc_field_reactor}
        	;;; Specify margin to left and right of field contents
			{offset rc_field_offset}
        	;;; Specify top and bottom margin (e.g. above and below text)
			{margin rc_field_margin}
        	;;; Font for printing in the field.
			{font rc_field_font}
        	;;; Foreground colour for the field.  Should phase out "fg" and "bg"
			{[fg fieldfg] rc_field_fg}
			;;; to be used to force a background change
			{[bg fieldbg] rc_field_bg}
        	;;; Gap between this field and the previous one
			{gap rc_field_gap}
        	;;; Set minimum width for the field
			{fieldwidth rc_field_width}
        	;;; Height of field
			{fieldheight rc_field_height}
        	;;; Used to pass a featurespec in to the picture creation
        	;;; procedures, to override defaults (See HELP * FEATURESPEC
        	;;; and HELP * RC_BUTTONS/featurespec
			{spec rc_field_override_specs}
        	;;; An integer giving horizontal and vertical pixel spacing between
        	;;; buttons, or vertical spacing between strings
			{spacing rc_field_spacing}
        	;;; Value for "align"can be "left", "centre" "right"
        	;;; The default is centre.
        	;;; If it is a graphic field {align panel} is allowed. Then all
        	;;; coordinates used when graphic instructions are obeyed are
        	;;; relative to the whole panel's frame.
			{align set_field_aligned}

		]
	];

;;; Utilities to aid the interpretation of a keyspec
define updaterof set_field_ident(wid, field);
	;;; set the identifier of a field given a word or identifier.
	if isword(wid) then identof(wid) else wid endif
			-> rc_field_ident(field)
enddefine;

define updaterof set_field_aligned(val, field);
	;;; set the alignment of a field
	if val == "center" then "centre" -> val endif;

	;;; [SET field ^field] ==>

	if val == "panel" then
		if isrc_graphic_field(field) then
			val -> rc_field_aligned(field);
		else
			mishap('Cannot use {align panel} here',[^field])
		endif;
	else
		val -> rc_field_aligned(field)
	endif;
enddefine;


define vars procedure rc_interpret_field_spec(vec, field, type);
	;;; Interpret a two element vector in a field spec, e.g. things like
	;;; 	{align left} {fieldbg 'navyblue'} {fieldfg 'pink'}


	define lconstant find_key(key, val, specs, field)-> found;
		false -> found;
		lvars spec;
		for spec in specs do
			lvars (spectype, specprop) = explode(spec);
			if key == spectype or (ispair(spectype) and lmember(key, spectype)) then
				val -> recursive_valof(specprop)(field);
				true -> found;
				return()
			endif
		endfor;
		false -> found;
	enddefine;


	lvars speclist, (key, val) = explode(vec);
	for speclist in rc_control_panel_keyspec do
		lvars (types, specs) = destpair(speclist);
		if types == [] or lmember(type, types) then
			returnif(find_key(key, val, specs, field))
		endif
	endfor;
	mishap('Unsuitable key for field of type: '>< type,[^vec])

enddefine;

/*
;;; testing the above;
rc_interpret_field_spec({fieldfg 'red'},[],"TEXTIN")->;
rc_interpret_field_spec({ident xxx},[],"TEXTIN")->;
rc_interpret_field_spec({align panel},[],"GRAPHIC")->;

*/

/*

define -- Procedures for creating field records from specification lists

This should work out maximum expected width and height of the field.
Allow a margin if in doubt.
*/

define rc_num_rows_of_cols(len, cols) -> rows;
	;;; How many rows are needed to display a list of length len
	;;; in cols columns?
	len div cols + sign(len rem cols) -> rows
enddefine;

global vars rc_check_empty_panel_field = false;

define lconstant check_has_colon(list) -> rest;
	lmember(":", list) -> rest;
	if rest then
		if rc_check_empty_panel_field and back(rest) == [] then
			mishap('CONTROL PANEL FIELD SPEC INCOMPLETE', [^list])
		else
			back(rest) -> rest;
		endif;
	else
		mishap('CONTROL PANEL FIELD SPEC NEEDS A COLON', [^list])
	endif;
enddefine;

;;; First a procedure used in all field instance creator procedures.
;;; It interprets the header of the field description.

define parse_field_header(list, field_inst, type) -> list;
	;;; Read in header of field specifier analysing the two element
	;;; 	vectors as slot/value specifiers.
	;;; Stop when colon ":" is reached.
	;;; Return the rest of the list for further analysis later
	lvars item, prop;
	for prop on list do
		front(prop) -> item;
		if item == ":" then
			;;; got to end of qualifiers
			back(prop) ->> list ->rc_field_specs(field_inst);
			return();
		elseif isvector(item) and datalength(item) == 2 then
			rc_interpret_field_spec(item, field_inst, type);
		elseif islist(item) then
			;;; it's a shared list of properties. Just recurse
			parse_field_header(item, field_inst, type) ->;
		else
			mishap('Unrecognised PanelField property item', [^item in ^type field])
		endif;
	endfor;
enddefine;

define text_field_instance(list, type) -> field;
	;;; Given a list containing specifications of strings to be
	;;; displayed or buttons, create an instance and attempt to
	;;; store relevant values in its slots.

	check_has_colon(list) -> ;

	newrc_text_field() -> field;

	parse_field_header(list, field, type) -> list;

	lvars
		len = listlength(list),
		cols = rc_field_cols(field),
		font = rc_field_font(field),
		spacing = rc_field_spacing(field),
	;
	;;; store the spec as contents. Will change
	list -> rc_field_contents(field);

	;;; find number of rows and number of columns
	if cols == 0 then
		len ->> cols -> rc_field_cols(field)
	endif;

	lvars rows = len;

	rows -> rc_field_rows(field);

	lvars
		(widths, w, font_h, ) = rc_text_area(list, font);

	sys_grbg_list(widths);	;;; not needed

	font_h -> rc_font_h(field);
	w+2 -> rc_field_width(field);
	max(
		rc_field_height(field),
		rows * (font_h + spacing) - spacing + 1) -> rc_field_height(field);

enddefine;

define getscrolltext_details(field, list) -> (text_w, text_h, cols, rows);
	lvars
		cols = rc_scroll_text_numcols(field),
		rows = rc_scroll_text_numrows(field),
		contents = front(list),
		vec;

	;;; extract the vector of strings
	if ispair(contents) then
		lvars item = fast_front(contents);

		if isword_or_ident(item) then
			item -> rc_field_ident(field);
			front(back(contents)) -> front(list);
			[] -> back(list);
		endif;
	endif;

	front(list) -> vec;

	if rows = 0 then
		min(rc_scroll_rows_max, datalength(vec))
			->> rows ->> rc_field_rows(field)
				-> rc_scroll_text_numrows(field);
	endif;

	if cols = 0 then
		min(rc_scroll_columns_max, max_string_length(vec))
			->> cols ->> rc_field_cols(field)
				->rc_scroll_text_numcols(field);
	endif;

	;;; [SLIDER  ^field]==>
	lvars
		slider_w = 2*rc_scroll_text_field_blobrad(field),
		slider_frame_w = 2*rc_scroll_text_field_sliderframewidth(field),
		font = rc_field_font(field),
		(font_w, font_h, font_a, _) = rc_font_dimensions(font, 'W');

		;;; extra font_h and slider_w as a precaution
		(rows)*(font_h) + (slider_w + slider_frame_w)*2 + font_a + 3
					->> text_h -> rc_text_h(field);

		1 + cols*font_w + font_w div 2 + 3*(slider_w + slider_frame_w)
					->> text_w  -> rc_text_w(field);
	
enddefine;

define multiscroll_text_field_instance(list, type) -> field;
	;;; Given a list containing specifications of strings to be
	;;; displayed, create an instance and attempt to
	;;; store relevant values in its slots.

	check_has_colon(list) -> ;

	newrc_multiscroll_text_field() -> field;

	parse_field_header(list, field, type) -> list;

	rc_field_rows(field) -> rc_scroll_text_numrows(field);
	rc_field_cols(field) -> rc_scroll_text_numcols(field);
	
	lvars
		offset = rc_field_offset(field),
		spacing = rc_field_spacing(field),
		align = rc_field_aligned(field),
		field_width = rc_field_width(field),
		len = listlength(list);

		len -> rc_field_rows(field);
	;;; list is now a list of scrolltext panel field_specs.

	lvars
		scroller,
		(text_w, text_h, cols, rows) = getscrolltext_details(field, hd(list));

	;;; height of whole field
	max(
		rc_field_height(field),
			len * (text_h + spacing) - spacing + 1) -> rc_field_height(field);

	;;; width of whole field
	max(text_w, rc_text_w(field)) ->> text_w -> rc_text_w(field);

    if align == "centre" then
		max(text_w + 2, field_width) -> rc_field_width(field);
	else
		max(offset + text_w + 2, field_width)-> rc_field_width(field);
	endif;

	;;; will be changed after instance is created
	undef -> rc_field_contents(field);

enddefine;


define scroll_text_field_instance(list, type) -> field;
	;;; Given a list containing specifications of strings to be
	;;; displayed, create an instance and attempt to
	;;; store relevant values in its slots.

	;;; Test if it is a "multi" type. This wll start with a list after the
	;;; colon
	lvars
		after_colon = check_has_colon(list),
		first_item = hd(after_colon);

	if islist(first_item) then
		;;;; It must be a "multi" type field, so
		multiscroll_text_field_instance(list, type) -> field;
		return()
	endif;

	;;; It's not a multi type

	newrc_scroll_text_field() -> field;

	parse_field_header(list, field, type) -> list;

	rc_field_rows(field) -> rc_scroll_text_numrows(field);
	rc_field_cols(field) -> rc_scroll_text_numcols(field);

	;;; will be changed after instance is created
	list -> rc_field_contents(field);

	lvars
		vec = front(list), 		;;; vector of strings
		(text_w, text_h, cols, rows) = getscrolltext_details(field, list);

	;;; store the vector of strings as the contents of the field
	;;; will be changed later.
	vec -> rc_field_contents(field);

	max(text_w, rc_field_width(field)) -> rc_field_width(field);
	max(text_h, rc_field_height(field)) -> rc_field_height(field);
enddefine;


define multitextin_field_instance(list, type) -> field;
	;;; Given a list containing a specification of multitextinput or
	;;; multinumber input field, create an instance  of the field and
	;;;  store relevant values in its slots, for use when the panel
	;;; instances are created
	
	check_has_colon(list) -> ;

	newrc_multitextin_field() -> field;

	if type == "MULTINUMBERIN" or type == "NUMBERIN" then
		;;; The field will contain number input buttons
		newrc_number_button -> rc_field_creator(field)
	endif;

	parse_field_header(list, field, type) -> list;

	lvars
		offset = rc_field_offset(field),
		spacing = rc_field_spacing(field),
		align = rc_field_aligned(field),
		field_width = rc_field_width(field);


	;;; list is now a list of text/number input panel field_specs.

	;;; go through finding out lengths of labels
	
	lvars
		font = rc_field_font(field),
		labelfont = rc_field_labelfont(field),
		;;; the number of panels
		rows = listlength(list),
		spacing = rc_field_spacing(field),
		item, label, label_len, text, textlen;

		rows -> rc_field_rows(field);

	;;; [MULTI rows ^rows [list ^list]] ==>

	define lconstant field_string(list) -> string;

		;;; second item of the list is the field's contents
		lvars item=hd(tl(list));
		if isstring(item) then item -> string
		else
			item sys_>< nullstring -> string
		endif;

	enddefine;

	;;; get a list of labels and a list of strings
	lvars
		labels = maplist(list, hd),
		strings = maplist(list, field_string);

	;;;[labels ^labels strings ^strings ^labelfont] ==>

	lvars
		;;; strings
		(l_widths, l_width, l_font_h, ) = rc_text_area(labels, labelfont),
		;;;(l_widths, l_width, l_font_h, ) = rc_text_area(labels, '12x24'),
		;;; labels
		(s_widths, s_width, s_font_h, ) = rc_text_area(strings, font),
		;;; maximum possible width
		w = l_width + s_width + 10,
		;;; maximum font height
		font_h = max(l_font_h+6, max(s_font_h+6, rc_textfield_height(field)));

		font_h ->> rc_font_h(field) -> rc_textfield_height(field);
	
	;;; [l_width ^l_width	 s_width ^s_width] =>
	;;; adjust width and height of the field, ensuring that
	;;; font height can be accommodated

	;;; height
	max(
		rc_field_height(field),
			rows * (font_h + spacing) - spacing + 1) -> rc_field_height(field);

	;;; width
	max(s_width+20, rc_textfield_width(field)) ->> w -> rc_textfield_width(field);

    if align == "centre" then
		max(w + 2*(l_width+4), rc_field_width(field)) -> rc_field_width(field);
	else
		max(offset, l_width + 4) -> rc_field_offset(field);
		max(rc_field_offset(field) + w +4, field_width)-> rc_field_width(field);
	endif;

	sys_grbg_list(labels);
	sys_grbg_list(strings);

enddefine;


define textin_field_instance(list, type) -> field;
	;;; Given a list containing specification of textinput or
	;;; number input field, create an instance and
	;;; store relevant values in its slots.
	;;; If the first item after the colon is a list, assume it is a
	;;; multitextin field

	;;; Test if it is a "multi" type. This wll start with a list after the
	;;; colon
	lvars
		after_colon = check_has_colon(list),
		first_item = hd(after_colon);

	if islist(first_item) and listlength(first_item) > 1
	and isstring(first_item(1))
	and (isstring(first_item(2)) or isnumber(first_item(2)))
	;;; and type /== "NUMBERIN"
	then
		;;;; It must be a "multi" type field, so
		multitextin_field_instance(list, type) -> field;
		return()
	endif;

	;;; It's not a multi type
	newrc_textin_field() -> field;

	if type == "NUMBERIN" then
		;;; The field will contain a number input button
		newrc_number_button -> rc_field_creator(field)
	endif;

	parse_field_header(list, field, type) -> list;

	;;; [NUMBERIN field ^field] ==>

	lvars
		offset = rc_field_offset(field),
		align = rc_field_aligned(field),
		field_width = rc_field_width(field),
		contents = front(list),
	;


	if ispair(contents) then
		lvars item = fast_front(contents);

		if isword_or_ident(item) then
			item -> rc_field_ident(field);
			back(contents) -> front(list);
		endif;
	endif;

	;;; store as the contents of the field
	list -> rc_field_contents(field);

	lvars first = recursive_front(list);
	[% if isstring(first) then first else first sys_>< nullstring endif %]
			-> first;

	lvars
		;;; The string
		(, s_width, s_font_h, ) = rc_text_area(first, rc_field_font(field)),
		;;; The label
		(, l_width, l_font_h,) =
			rc_text_area([%rc_field_labelstring(field)%],rc_field_labelfont(field)),
		;;; maximum possible width
		w = l_width + s_width + 10,
		;;; get maximum font height
		font_h = max(l_font_h+6, max(s_font_h+6, rc_textfield_height(field)));

	;;; [^TYPE s_width ^s_width field ^(rc_field_width(field))]=>

	font_h ->> rc_font_h(field) -> rc_textfield_height(field);

	;;; adjust width and height of the field, ensuring that
	;;; font height can be accommodated

	;;; fix height
	max(rc_field_height(field), font_h) -> rc_field_height(field);

	max(s_width+20, rc_textfield_width(field)) ->> w -> rc_textfield_width(field);
	;;; fix width
	;;; adjust offset so that it can accommodate the label
    if align == "centre" then
		max(w + 2*(l_width+4), rc_field_width(field)) -> rc_field_width(field);
	else
		max(offset, l_width + 4) -> rc_field_offset(field);
		max(rc_field_offset(field) + w + 4, field_width)-> rc_field_width(field);
	endif;

enddefine;

define slider_field_instance(list, type) -> field;
	;;; Given a list containing specifications of sliders,
	;;; create an instance of a slider field (with one or more
	;;; sliders

	check_has_colon(list) -> ;

	newrc_slider_field() -> field;

	parse_field_header(list, field, type) -> list;

	if type == "PANELSLIDERS" then "panel" -> rc_field_type(field);
	endif;

	lvars
		len = listlength(list),
		cols = 1,	;;; sliders can't be in multiple columns???
	;
	;;; Leave this code in case we later want to have
	;;; horizontally aligned sliders
	;;; find number of rows and number of columns
	if cols == 0 then
		len ->> cols -> rc_field_cols(field)
	endif;

	lvars
		rows = rc_num_rows_of_cols(len, cols),
		spacing = rc_field_spacing(field),
		slider_height = rc_slider_field_height(field),
		;
	rows -> rc_field_rows(field);

	rows * (slider_height + spacing) +
		2 * rc_slider_field_barframewidth(field) -> rc_field_height(field);

enddefine;

define dial_field_instance(list, type) -> field;
	;;; Given a list containing specifications of sliders,
	;;; create an instance of a slider field (with one or more
	;;; sliders

	check_has_colon(list) -> ;

	newrc_dial_field() -> field;

	parse_field_header(list, field, type) -> list;

	lvars
		len = listlength(list),
		cols = 0,
	;
	;;; number of dials to be align horizontally
	len -> rc_dial_field_count(field);

	;;; Leave this code in case we later want to have
	;;; horizontally aligned dials
	;;; find number of rows and number of columns
	if cols == 0 then
		len ->> cols -> rc_field_cols(field)
	endif;

	lvars
		rows = rc_num_rows_of_cols(len, cols),
		spacing = rc_field_spacing(field),
		dial_w = rc_dial_width(field),
		;
	rows -> rc_field_rows(field);

	;;; guess minimum field width required.
	max(rc_field_width(field),
		 len*(dial_w + spacing) - spacing ) -> rc_field_width(field);

	max(rc_dial_height(field) + rc_dial_base(field) + 2, rc_field_height(field))
			-> rc_field_height(field);

	;;;; dial_height -> rc_field_height(field);

enddefine;


define buttons_field_instance(list, newproc, type) -> field;
	;;; Generic buttons_field creator. Used by specific buttons
	;;; field creator procedures below.
	;;; newproc is the procedure to create an instance of the appropriate
	;;; button type

	check_has_colon(list) -> ;

	newproc() -> field;

	parse_field_header(list, field, type) -> list;

	lvars
		len = listlength(list),
		cols = rc_field_cols(field),
	;
	;;; find number of rows and number of columns
	if cols == 0 then
		len ->> cols -> rc_field_cols(field)
	endif;

	lvars
		rows = rc_num_rows_of_cols(len, cols),
		spacing = rc_field_spacing(field);

	rows -> rc_field_rows(field);

	cols*(rc_button_width(field)+spacing) - spacing -> rc_field_width(field);
	rows*(rc_button_height(field)+spacing) -spacing + 1 -> rc_field_height(field);
enddefine;

define actions_field_instance(list, type) -> field;
	buttons_field_instance(list, newrc_actions_field, type) -> field;
enddefine;

define someof_field_instance(list, type) -> field;
	buttons_field_instance(list, newrc_someof_field, type) -> field;
enddefine;

define radio_field_instance(list, type) -> field;
	buttons_field_instance(list, newrc_radio_field, type) -> field;
enddefine;

define graphic_field_instance(list, type) -> field;
	newrc_graphic_field() -> field;
	parse_field_header(list, field, type) -> list;
	;;; list -> rc_field_specs(field);
enddefine;

/*
define -- Create the field instances from a user specification list

;;; This procedure will use one of the above to create the instance,
;;; depending on the type of field. At this stage only the dimensions
;;; of the field will be computed, as part of the process of computing
;;; the dimensions of the whole panel containing the field.
;;; The actual contents of the field will not be created until the
;;; panel window has been created.
*/

define vars rc_list_to_field(field, title) -> field;
	;;; Title is the title of the panel
	;;; traceable procedure, for debugging, or user definition to
	;;; extend field types
	lvars type;
	dest(field) -> (type, field);
	;;; select procedure to apply to field
	if type == "TEXT" then
		text_field_instance
	 elseif type == "SCROLLTEXT" then
		scroll_text_field_instance
	elseif type == "TEXTIN" or type == "NUMBERIN" then
		textin_field_instance
	elseif type == "MULTITEXTIN" or type == "MULTINUMBERIN" then
		multitextin_field_instance
	elseif type == "SLIDERS" or type == "PANELSLIDERS" then
		slider_field_instance
	elseif type == "DIALS" then
		dial_field_instance
	elseif type == "ACTIONS" then
		actions_field_instance
	elseif type == "SOMEOF" then
		someof_field_instance
	elseif type == "RADIO" then
		radio_field_instance
	elseif type == "GRAPHIC" then
		graphic_field_instance
/*
;;; may add this for user-defined types of fields
			elseif isprocedure(type) then
				type
		*/
	else
		mishap('Unknown field type', [^type])
	endif(field, type) -> field;

	;;; fix margins
	rc_field_height(field) + 2 * rc_field_margin(field)
		-> rc_field_height(field);

	;;; At this stage just put in the title of the control panel.
	;;; Later the panel will be inserted, after it has been created.
	title -> rc_field_container(field);
enddefine;

define fields_from_descriptors(fields, title) -> fields;
	;;; fields is a list of lists, where each list specifies a field,
	;;; e.g. a text field, or one of several types of buttons fields.

	lvars descriptor;
	[%
		for descriptor in fields do
			rc_list_to_field(descriptor, title)
		endfor
	%] -> fields;
enddefine;

global vars rc_redrawing_panel = false;


define lconstant redraw_old(panel, panel_objects, redrawing);
	;;; If it is not first time, then redraw them
	if redrawing then
		applist(panel_objects, rc_undraw_linepic);
		applist(panel_objects, rc_draw_linepic);

		;;; now draw things that are not part of the control panel
		;;; but may have been added later
		lvars item,
			list = rev(rc_window_contents(panel));

		for item in list do
			unless lmember(item, panel_objects) then
				rc_undrawn(item);
				rc_draw_linepic(item);
			endunless;
		endfor;
		;;; it is a temporary list, so return to heap
		sys_grbg_list(list);
	endif;
enddefine;

define :method rc_redraw_panel(panel:rc_panel);
	;;; Display text button and other  fields

	define lconstant save_it(panel, oldpanel, context);
		;;; context is dlocal_context in dlocal expression.
		if context < 3 then panel -> rc_current_window_object endif
	enddefine;

	define updaterof lconstant save_it(panel, oldpanel, context);
		;;; context is dlocal_context in dlocal expression.
		if context < 3 then oldpanel -> rc_current_window_object endif
	enddefine;


	dlocal rc_panel_slider_blob;

	lvars old_type = rc_panel_slider_blob;

	;;; Prevent scaling of slider field size newspecs
	dlocal rc_slider_scaled_def = false;

	dlocal rc_slider_blob_bar_ratio = 1;	;;; in case scales are strange

	;;; suppress triggering of reactors while panel is being
	;;; constructed. See rc_information_changed in LIB RC_INFORMANT
	;;; Maybe this should be user controllable?
	dlocal rc_reactor_depth = 1000;

	procedure();
		;;; we need an extra level of procedure calls to use panel
		;;; in the dlocal expression. See HELP DLOCAL

		;;; This will set xorigin, yorigin, xscale, yscale
		;;; dlocal rc_current_window_object = panel;
		dlocal 0% save_it(panel, rc_current_window_object, dlocal_context)%;

		unless panel == rc_current_window_object then
			panel -> rc_current_window_object;
		endunless;

		lvars
			window_w = rc_panel_width(panel),
			new_window_w = (window_w  - rc_panel_offset(panel))/abs(rc_xscale),
			field,
			next_y = -rc_yorigin/rc_yscale,
			y_mid,
			panel_offset = (rc_panel_offset(panel)-rc_xorigin)/abs(rc_xscale),
			xsign = sign(rc_xscale),
			panel_objects = rc_panel_objects(panel),
			;

		dlocal rc_redrawing_panel = panel_objects;	;;; false first time

		abs(window_w/rc_xscale) -> window_w;
		unless panel_objects then
			;;; first time, so initialise everything, creating objects.
			;;; using the rc_panel_fields list.

			[] -> panel_objects;
		endunless;
			
		for field in rc_panel_fields(panel) do
			;;; Re-set global variable for use in field code

			old_type -> rc_panel_slider_blob;

			;;; not sure this is needed
			dlocal
				rc_current_panel_field = field;

			;;; Tell it about the panel containing it
			panel -> rc_field_container(field);

			;;; [DRAWING field ^field]==>

			lvars
				fg = rc_field_fg(field),
				bg = rc_field_bg(field),
				font = rc_field_font(field),
				buttontype = false,
				buttons = false,	;;; set true for button fields
				x_offset = rc_field_offset(field) /abs(rc_xscale),
				field_w = rc_field_width(field),
				field_h = abs(rc_field_height(field)/rc_yscale),
				margin = rc_field_margin(field)/rc_yscale,
				gap = rc_field_gap(field)/rc_yscale,
				aligned = rc_field_aligned(field),
				spacing = rc_field_spacing(field),
				constrain = rc_field_constraint(field),
				reactor = rc_field_reactor(field),
				field_id = rc_field_ident(field),
				;;; original list field contents descriptions
				field_specs = rc_field_specs(field),
			;;; See if a feature spec has been provided, to override
			;;; default slot values. See HELP * FEATURESPEC
			;;; translate abbreviations here
				newspecs = rc_translate_panel_spec(rc_field_override_specs(field)),	
				contents = rc_field_contents(field),
				;

			dlocal %rc_foreground(rc_window)%;
			if fg then fg -> rc_foreground(rc_window) endif;

			;;; field_w could be "panel"
			if isnumber(field_w) then abs(field_w/rc_xscale) -> field_w endif;

			;;;; no longer needed???
			lvars height_adjust = 0;

			;;; updated beginning of next field.
			next_y + gap ->> next_y -> rc_field_y(field);
			;;; find mid line of field
			next_y +
			(field_h + height_adjust  )/(2.0*sign(rc_yscale)) -> y_mid;

        	x_offset + panel_offset -> rc_field_x(field);

			if isrc_actions_field(field) then
				"action" -> buttontype;
			elseif isrc_someof_field(field) then
				"someof" -> buttontype;
			elseif isrc_radio_field(field) then
				"radio" -> buttontype;
			endif;

			if buttontype or isrc_text_field(field)
				;;; includes TEXT SCROLLTEXT TEXTIN and NUMBERIN
				;;; MULTITEXTIN MULTINUMBERIN
			then
				;;; work out new x_offset
				if aligned == "centre" then
					if isrc_textin_field(field) then
						rc_textfield_width(field) -> field_w;
					endif;
					if isnumber(field_w) then
						(new_window_w  - field_w)*0.5
					else x_offset
					endif
				elseif aligned == "right" then
					if isnumber(field_w) then
						(new_window_w - field_w - x_offset)
					else
						(new_window_w - x_offset)
					endif
				elseif aligned == "left" and isrc_scroll_text_field(field) then
					x_offset + 1
				else
					x_offset
				endif  -> x_offset;
				;;; no longer needed. Drawing sub-routines are scale independent
				;;; spacing/abs(rc_yscale) -> spacing;
			endif;

			unless field_h == 0 or bg == false
			or bg == rc_panel_bg(rc_current_panel)
			then
				;;; draw bar to form background of the appropriate colour.
				rc_draw_bar(
					panel_offset,
					y_mid , field_h,
					xsign*new_window_w, bg);
			endunless;

			if isrc_multiscroll_text_field(field) then
				;;; Multiple SCROLLTEXT panels
					;;; this must come BEFORE isrc_scroll_text_field, as it is a subclass

			  if rc_redrawing_panel then
					;;; fields already created so just draw them
					applist(contents, rc_undraw_linepic);
					applist(contents, rc_draw_linepic);
			  else
				;;; create the scrolling text panels
				lvars content, yloc = next_y + margin;
				[%for content in field_specs do
						;;; content should be a list
						;;; run creator in a sub-procedure because of dlocal expression
				    	lvars scr;
				  		procedure();
        					dlocal
								rc_scroll_slider_default_type = rc_scroll_text_field_slider_type(field);

							lvars rad = rc_scroll_text_field_blobrad(field);

							create_scroll_text(
								'scrolltext',
								;;; temporary
								content,
								panel,
								xsign*(panel_offset + x_offset + 4),
								yloc + 4 + rad*2,
								rc_scroll_text_numrows(field),
								rc_scroll_text_numcols(field),
								rc_field_text_fg(field),
								rc_field_text_bg(field),
								rc_field_font(field),
								rad,
								rc_scroll_text_field_slidercol(field),
								rc_scroll_text_field_blobcol(field),
								false, ;;; rc_scroll_text_field_sliderframecol(field),
								0 ;;; rc_scroll_text_field_sliderframewidth(field),
							)

						endprocedure() -> scr;



						;;;XXXX next bit must change.
        				reactor -> rc_informant_reactor(scr);
						rc_scroll_text_field_acceptor(field) -> rc_accept_action(scr);

						;;; now set identifier if appropriate
						lvars wid = rc_informant_ident(scr);
						if isword_or_ident(wid) then
							rc_informant_value(scr) ->  valof(wid);
						endif;
						;;; get next y value
						yloc + rc_text_h(field)*rc_yscale + spacing -> yloc;
						scr ;
					endfor %] -> rc_field_contents(field);
			  endif;

			elseif isrc_scroll_text_field(field) then
				;;; single SCROLLTEXT
				;;; This is left in for backward compatibility.
				;;; this must come BEFORE isrc_text_field, as it is a subclass

				lvars content = rc_field_contents(field);
              	if rc_redrawing_panel then
					;;;created previously -- just redraw
					rc_undraw_linepic(content);
					rc_draw_linepic(content);
				else
					if isvector(content) then
						;;; run creator in a sub-procedure because of dlocal expression
				    	lvars scr;
				  		procedure();
        					dlocal
								rc_scroll_slider_default_type = rc_scroll_text_field_slider_type(field);

							lvars rad = rc_scroll_text_field_blobrad(field);

							create_scroll_text(
								'scrolltext',
								content,
								panel,
								xsign*(panel_offset + x_offset + 4),
								next_y + margin + 4 + rad*2,
								rc_scroll_text_numrows(field),
								rc_scroll_text_numcols(field),
								rc_field_text_fg(field),
								rc_field_text_bg(field),
								rc_field_font(field),
								rad,
								rc_scroll_text_field_slidercol(field),
								rc_scroll_text_field_blobcol(field),
								false, ;;; rc_scroll_text_field_sliderframecol(field),
								0, ;;; rc_scroll_text_field_sliderframewidth(field),
								if rc_field_ident(field) then rc_field_ident(field) endif,
							)

						endprocedure() -> scr;

						;;; XXXX fix
        				reactor -> rc_informant_reactor(scr);

						;;; save single object as field contents
						;;; for backward compatibility.
						scr -> rc_field_contents(field);
						rc_scroll_text_field_acceptor(field) -> rc_accept_action(scr);

						;;; now set identifier if appropriate
						lvars wid = rc_informant_ident(scr);
						if isword_or_ident(wid) then
							rc_informant_value(scr) ->  valof(wid);
						endif;
                    else
						mishap('Vector of strings required in SCROLLTEXT', [^field]);
					endif;
				endif;
			elseif isrc_multitextin_field(field) then
				;;; MULTITEXTIN or MULTINNUMBERIN
				;;; this must come BEFORE isrc_text_field, and before
				;;; isrc_textin_field as it is a subclass of both
				
				procedure();
					dlocal
						rc_text_input_bg_def = rc_field_bg(field),
					;;; rc_text_input_active_bg_def = ????,
						rc_text_input_fg_def = rc_field_fg(field);

					;;; creator may create text input or number input button
					lvars
						constructor = rc_field_creator(field),
						field_w = rc_textfield_width(field),
						field_h = rc_textfield_height(field),
						yloc = next_y + margin + 1/rc_yscale,

						;


					;;; [MULTITEXTIN ^constructor ^field_specs x_off ^x_offset
					;;;		panel ^panel_offset width ^field_w]=>
				if rc_redrawing_panel then
				else
            		[%
						lvars item;
						for item in field_specs do

							;;; [TEXTIN item ^item]==>
							lvars
								spec = false,
								label = hd(item),
								contents = back(item),
								textin;
							

							define lconstant fix_textin_panel(textin) -> textin;
								;;; create textin or numberin field.
								constrain -> rc_constrain_contents(textin);
								reactor -> rc_informant_reactor(textin);
								label -> rc_label_string(textin);
								rc_field_labelcolour(field) -> rc_label_colour(textin);
								rc_field_labelfont(field) -> rc_label_font(textin);
								rc_textin_field_bg(field) -> rc_text_input_bg(textin);
								rc_textin_field_active_bg(field) -> rc_text_input_active_bg(textin);
								rc_textin_field_fg(field) -> rc_text_input_fg(textin);
							enddefine;
							/*
							create_text_input_field(
							x, y, width, height, text, extendable, font, creator) -> field;
							*/

							create_input_field(
								xsign*(panel_offset + x_offset),
								yloc,
								field_w*rc_xscale, field_h*rc_yscale,
								contents, 	;;;.dup.Veddebug,
								false,
								rc_field_font(field),
								fix_textin_panel) -> textin;
							textin;
							;;; location for next button
							yloc + field_h*rc_yscale + spacing -> yloc;
                		endfor
					%] -> rc_field_contents(field);
				  endif;
				endprocedure();

			elseif isrc_textin_field(field) then
				;;; TEXTIN or NUMBERIN
				;;; left in for backward compatibility
				;;; this must come BEFORE isrc_text_field, as it is a subclass
				
				procedure();
					dlocal
						rc_text_input_bg_def = rc_field_bg(field),
					;;; rc_text_input_active_bg_def = ????,
						rc_text_input_fg_def = rc_field_fg(field);

					;;; creator may create text input or number input button
					lvars
						constructor = rc_field_creator(field),
						field_w = rc_textfield_width(field),
						field_h = rc_textfield_height(field),
						yloc = next_y + margin + 1/rc_yscale,
						;

					;;; [TEXTIN ^constructor ^field_specs x_off ^x_offset
					;;;		panel ^panel_offset width ^field_w]=>

					define lconstant make_field() -> textin;
						;;; create textin or numberin field.
						constructor() -> textin;
						constrain -> rc_constrain_contents(textin);
						reactor -> rc_informant_reactor(textin);
						rc_field_labelstring(field) -> rc_label_string(textin);
						rc_field_labelcolour(field) -> rc_label_colour(textin);
						rc_field_labelfont(field) -> rc_label_font(textin);
						rc_textin_field_bg(field) -> rc_text_input_bg(textin);
						rc_textin_field_active_bg(field) -> rc_text_input_active_bg(textin);
						rc_textin_field_fg(field) -> rc_text_input_fg(textin);
						if isword_or_ident(field_id) then
							field_id -> rc_informant_ident(textin);
						endif;
					enddefine;

					create_text_input_field(
						xsign*(panel_offset + x_offset),
						yloc,
						field_w*rc_xscale, field_h*rc_yscale,
						if islist(field_specs) and listlength(field_specs) > 1 then
							field_specs
						else
							if islist(field_specs) then hd(field_specs) else field_specs endif
						endif,
						false,
						rc_field_font(field),
						make_field) -> rc_field_contents(field);
					;;;constructor) -> rc_field_contents(field);
					
				endprocedure();

			elseif isrc_text_field(field) then
				;;; change this default. Use explicit offsets instead.
				dlocal rc_print_strings_offset = 0;

				rc_print_strings(
					xsign*(panel_offset + x_offset),
					next_y + margin,
					field_specs,
					spacing,
					aligned,
					rc_field_font(field),
					;;; background already drawn
					false,
					rc_field_fg(field)) -> (,);

				;;; save the list of strings as the field contents
				field_specs -> rc_field_contents(field);

			elseif isrc_slider_field(field) then
				lvars
					slider,
					type = rc_field_type(field),
					text_panel = rc_slider_field_value_panel(field),
					labelfont = rc_slider_field_labelfont(field),
					textin = rc_slider_field_textin(field),
					places = rc_slider_field_places(field),
					blobcol = rc_slider_field_blobcol(field),
					barcol = rc_slider_field_barcol(field),
					barframecol = rc_slider_field_barframecol(field),
					barframewidth = rc_slider_field_barframewidth(field),
					stepval = rc_slider_field_step(field),
					radius = rc_slider_field_radius(field),
					slider_h = rc_slider_field_height(field)/rc_yscale,
					y_offset = margin + (barframewidth -2.0*radius)/rc_yscale,
					wid,
					contents = rc_field_contents(field);
				
				if contents == [] then
					;;; sliders not yet created
		  			[%
						for slider in field_specs do

							;;; see if slider spec starts with an identifier or word
							if isword_or_ident(front(slider)) then
								fast_front(slider) -> wid;
								fast_back(slider) -> slider;
							else
								field_id -> wid	;;; could be false
							endif;

							y_offset + spacing/rc_yscale + slider_h -> y_offset;


							lvars
								spec = false,
								range, doround = false, labels,
								value_panel = rc_slider_field_value_panel(field),
								gap_on_right =
								if value_panel then abs((value_panel(6)+value_panel(8))/rc_xscale),
								else 0 endif,
								len = listlength(slider),
								;

							explode(slider) ->
							if len == 4 then
								;;; featurespec included
								(range, doround, labels, spec)
							elseif len == 3 then
								(range, doround, labels)
							else
								(range, labels)
							endif;

							if field_w == "panel" then
								new_window_w - x_offset - 3 -> field_w
							endif;

			 				;;; if wid then
			 				if type == "panel" then
								rc_panel_slider
			 				else
								rc_opaque_slider
							endif(
				  				xsign*(panel_offset + x_offset),
								next_y + y_offset,
								xsign*(panel_offset + x_offset + field_w - gap_on_right),
								next_y + y_offset,
				    			range, radius, barcol, blobcol, labels,
								[%
									newspecs,
									{%rc_informant_ident, field_id,
										rc_slider_convert_out,
										if doround == "round" or doround == round then
											round else identfn
										endif,
					    				rc_slider_value_panel, value_panel,
										rc_constrain_contents,
											if doround == "round" or doround == round then
												round else constrain
											endif,
										rc_informant_reactor, reactor,
										if barframecol then
											rc_slider_barframe, conspair(barframecol, barframewidth)
										endif,
										if isstring(labelfont) then
											rc_slider_labels_font, labelfont,
										endif,
										rc_slider_value_panel, text_panel,
										rc_slider_textin, textin,
										if isinteger(places) then rc_slider_places, places endif,
										if spec then explode(rc_translate_panel_spec(spec)) endif,
										%},
                    			%],

								if type == "square" then
									useslib("rc_opaque_slider");
									valof("newrc_square_opaque_slider");
								elseif type == "panel" then
									;;; rc_panel_slider
									;;; no extra argument needed
								elseif isprocedure(recursive_valof(type)) then
									recursive_valof(type)
								else
									;;; nothing needed
									;;; newrc_slider
								endif,
								if wid then wid endif).dup -> slider;

							if stepval then
								stepval -> rc_slider_step(slider);
							endif;
						endfor %] -> rc_field_contents(field);
          		else
					;;; sliders exist, so redraw them. But first undraw movable bits.
					applist(contents, rc_undraw_linepic);
					applist(contents, rc_draw_slider);
				endif;

			elseif isrc_dial_field(field) then
				lblock;
					lvars
						dial,
						places = rc_dial_field_places(field),
						y_offset,
						wid,
						count = rc_dial_field_count(field),
						dial_w = rc_dial_width(field),
						dial_h = rc_dial_height(field),
						dial_base = rc_dial_base(field),
						dial_bg = rc_dial_field_bg(field),
						;

					;;; rc_redrawing_panel = false
					if contents == [] then
						;;; not yet drawn, so create dials, and draw them.
						x_offset + round(dial_w*0.5) -> x_offset;
						margin + dial_h -> y_offset;
		  				[%
							for dial in field_specs do

								;;; see if dial spec starts with an identifier or word
								if isword_or_ident(front(dial)) then
									fast_front(dial) -> wid;
									fast_back(dial) -> dial;
								else
									field_id -> wid	;;; could be false
								endif;

								lvars
									range, doround = false, labels,
									;

								;;; destpair(dial) -> (range, dial);
								;;; dial should be a list of possible arguments for
								;;; rc_dial, i, e.
								;;; x and y relative to the panel location
    							;;; orient, angwidth, range, len, width, colour, bg
							;;; and possible optional arguments, e.g. for labels

								lvars dx, dy;
								destpair(destpair(dial)) -> (dx, dy, dial);

								rc_dial(
				  					xsign*(dx + panel_offset + x_offset),
									dy + y_offset+ next_y,
									;;; hand remaining arguments to rc_dial
									explode(dial),

									{%
										;;; rc_opaque_bg, dial_bg,
										explode(newspecs),
										rc_informant_ident, field_id,
										;;; rc_pointer_convert_out,
										;;;if doround == "round" or doround == round then
										;;;	round else identfn
										;;;endif,
										rc_informant_reactor, reactor,
										if isinteger(places) then rc_informant_places, places endif,
										if dial_bg then rc_opaque_bg, dial_bg endif,
                    					%},

									;;; include word or identifier if provided
									if wid then wid endif).dup -> dial;
                            	x_offset + dial_w + spacing -> x_offset;
							endfor %] -> rc_field_contents(field);
          			else
						;;; dials exist, so redraw them. But first undraw movable bits.
						;;; applist(contents, rc_undraw_dial);
						;;; draw bar to refresh background. Not strictly necessary
						rc_draw_bar(
							panel_offset,
							y_mid , field_h,
							xsign*new_window_w, bg);
						;;; redraw dials
						applist(contents, rc_redraw_linepic);
					endif;
				endlblock;
			elseif isrc_graphic_field(field) then
				;;; ignore margin?
				
				max(abs(new_window_w*rc_xscale), abs(field_w*rc_xscale))
					->> field_w -> rc_field_width(field);

				;;; collect a list of all objects created, to be added to the picture
				;;; objects at thend
        		lvars newobjects =
					[%rc_draw_graphic_field(field, panel_offset, next_y, aligned, field_w, abs(field_h))%];
					newobjects nc_<> panel_objects -> panel_objects;

			elseif buttontype then

				;;; create the list of buttons if it does not already exist
				contents -> buttons;
				;;; rc_redrawing_panel = false
				if buttons == [] then
					lvars
						fg = rc_field_text_fg(field),
						bg = rc_field_text_bg(field);

					create_button_columns(
						xsign*(panel_offset + x_offset),
						next_y + margin + 1/rc_yscale,
						rc_button_width(field),
						rc_button_height(field),
						round(spacing),
						rc_field_cols(field),
						;;; the list of button specifications
						field_specs,
						buttontype,
						[%newspecs,
							
							{%
								lvars
									chosenbg = false,
									selector = false,
									deselector = false;

								if isrc_someof_field(field) then
									rc_chosen_background(field) -> chosenbg;
									rc_radio_select_action(field) -> selector;
									rc_radio_deselect_action(field) -> deselector;
								elseif isrc_radio_field(field) then
									rc_chosen_background(field) -> chosenbg;
									rc_radio_select_action(field) -> selector;
								endif,
								if selector then
									rc_radio_select_action, selector
								endif;
								if deselector then
									rc_radio_deselect_action, deselector
								endif;
								if chosenbg then
									rc_chosen_background, chosenbg
								endif,
								rc_constrain_contents, constrain,
								rc_informant_reactor, reactor,
								if font then
									rc_button_font, font
								endif,
								if fg then rc_button_stringcolour, fg endif,
								if bg then rc_button_labelground, bg endif,
								%}
						%])
						;;; Give the field access to the buttons it contains
							->> buttons -> rc_field_contents(field);

					;;; Tell each button about the field containing it
					;;; From the field the whole panel can be fetched.
					lvars button, iswid = isword_or_ident(field_id);
					for button in buttons do
						if iswid then
							field_id -> rc_informant_ident(button);
						endif;
						field -> rc_button_container(button);
					endfor;
					unless buttontype == "action" then
						lvars def = rc_buttons_default(field);
						if iswid then def -> valof(field_id) endif;
						rc_inform_button_siblings(buttons);
						rc_set_button_defaults(
							buttons,
							field_id,
							def,
							buttontype);
						;;; make a list of the options
						maplist(buttons, rc_button_label)
							-> rc_buttons_options(field);
					endunless;
				else
					;;; rc_redrawing_panel = true
					applist(buttons, rc_undraw_linepic);
					applist(buttons, rc_draw_linepic);
				endif;
			else
				mishap('Unrecognised item in list of fields', [^field])
			endif;

			next_y + field_h*sign(rc_yscale) -> next_y;
		endfor;

		;;; Save objects which need to be redrawn.
		panel_objects -> rc_panel_objects(panel);


		;;; If it is not first time, then redraw them
		if rc_redrawing_panel then
			redraw_old(panel, panel_objects, true);
		endif;

	endprocedure();

enddefine;

define :method rc_redraw_window_object(panel:rc_panel);
	
	XpwClearWindow(rc_widget(panel));
	rc_redraw_panel(panel);

enddefine;



define global vars rc_control_panel(x, y, fields, title) -> panel;

	lvars
		old_win = rc_current_window_object;

	;;; Set an exit action
	dlocal 0%  , if dlocal_context < 3 then old_win -> rc_current_window_object endif% ;


	lvars container = false, window_constructor = false;

	ARGS x, y, fields, title, &OPTIONAL container:isrc_window_object, window_constructor:isprocedure;

	lvars
		field,
		default_w = 0,
		default_h = 0,
		window_w = 0,
		;;; accumulated window height (may decrease because of negative gaps)
    	window_h = 0,
		;;; Non-decreasing accumulated minimum required window height.
		min_window_h = 0,
		events = false,
		panel_xorigin = 0, panel_yorigin = 0,
		panel_xscale = 1, panel_yscale = 1,
		vec,
		fg = false, bg = false, font = false, panel_offset = false,
		resizable = false;
		;

	;;; Check defaults at front of list. Allow
	;;; {bg <colour> {fg <colour>} {font <font>}
	;;; {height <num>}{width <num>}

	while fields /== [] and isvector(hd(fields) ->> vec) do
    	lvars key = subscrv(1, vec), val = subscrv(2, vec);
		if key = "bg" then val -> bg
		elseif key = "fg" then val -> fg
		elseif key = "font" then val -> font
		elseif key = "width" then val -> default_w
		elseif key = "height" then val -> default_h
		elseif key = "events" then val -> events
		elseif key = "offset" then val -> panel_offset
		elseif key = "xorigin" then val -> panel_xorigin
		elseif key = "yorigin" then val -> panel_yorigin
		elseif key = "xscale" then val -> panel_xscale
		elseif key = "yscale" then val -> panel_yscale
		elseif key = "resize" then
			lmember(val, #_<[true on yes ^true] >_#) -> resizable
		else
			mishap('Unrecognized panel default', [^vec])
		endif;
		tl(fields) -> fields;
	endwhile;

	;;; Get a collection of field instances.
	lvars descriptors = fields_from_descriptors(fields, title);

	;;; Now scan them to work out window size and height
	for field in descriptors do

		;;; ['new field' % datakey(field) %]=>
		lvars
			align = rc_field_aligned(field),
			offset = rc_field_offset(field),
			field_w = rc_field_width(field);

		if align== "centre" then 2 * offset -> offset endif;

		max(window_w, if isnumber(field_w) then field_w else 0 endif + offset)
					-> window_w;

		;;; Increment window height accumulator
		window_h + rc_field_gap(field) + rc_field_height(field)
				-> window_h;


		if isrc_text_field(field) or isrc_textin_field(field) then
			;;; do nothing more

		elseif isrc_slider_field(field) then
			lvars bar_offset = 2*rc_slider_field_barframewidth(field);
			rc_field_height(field) + bar_offset -> rc_field_height(field);
			window_h + bar_offset -> window_h;
		elseif isrc_graphic_field(field) then
			;;; do something about panel_offset?
		endif;
		max(window_h, min_window_h) -> min_window_h;
		;;;[^(dataword(field)) window_w ^window_w window_h ^window_h default_h ^default_h] =>
	endfor;

	max(default_w, window_w) -> window_w;
	;;; as a precaution, add 1 to window_h
	max(default_h, max(window_h,min_window_h) + 2) -> window_h;
	max(window_w, panel_xorigin) -> window_w;
	max(window_h, panel_yorigin) -> window_h;
	;;; [window_w ^window_w window_h ^window_h default_h ^default_h] =>

	if panel_offset then window_w + panel_offset -> window_w endif;

	;;; create the window object
	rc_new_window_object(
		x, y, window_w, window_h,
		{^panel_xorigin ^panel_yorigin ^panel_xscale ^panel_yscale},
			if window_constructor then window_constructor else newrc_panel endif,
				title,
				if container then container endif)
				->> panel -> rc_current_panel;
	panel_xorigin -> rc_panel_xorigin(panel);
	panel_yorigin -> rc_panel_yorigin(panel);
	panel_xscale -> rc_panel_xscale(panel);
	panel_yscale -> rc_panel_yscale(panel);
	window_w -> rc_panel_width(panel);
	window_h -> rc_panel_height(panel);

    rc_sync_display();
	;;; rc_current_window_object=>	

	if events then
		rc_mousepic(rc_current_panel, events)
	else
		;;; make it sensitive to all events except resize by default
		rc_mousepic(rc_current_panel)
	endif;

	;;; rc_current_window_object=>	
    rc_sync_display();

	if panel_offset then
		panel_offset -> rc_panel_offset(rc_current_panel)
	endif;

	;;; Save the descriptors for use by rc_redraw_panel
	descriptors -> rc_panel_fields(panel);

	lvars
		win = rc_widget(panel);

	;;; Set window defaults. Currently only fg bg and font
	if font then font -> rc_panel_font(panel) endif;
	if fg then fg -> rc_panel_fg(panel) endif;
	if bg then bg -> rc_panel_bg(panel) endif;
	rc_panel_font(panel) -> rc_font(win);
	rc_panel_bg(panel) -> rc_background(win);
	rc_panel_fg(panel) -> rc_foreground(win);

	rc_redraw_panel(panel);

	if resizable then rc_set_resize_handler(panel) endif;
	
enddefine;

endsection;

nil -> proglist;


/*
CONTENTS

 define -- Variables to control default fonts and colours on panel
 define :rc_defaults;
 define -- The main class, containing window and other items
 define :class vars rc_panel is rc_button_window;
 define :method rc_print_fields(panel:rc_panel, printlevel);
 define -- mixin for fields containing text, buttons, etc
 define :mixin vars rc_panel_field;
 define -- Text, scrolltext, multiscrolltext textin, multitextin, slider and button field classes
 define :class vars rc_text_field is rc_panel_field;
 define :class vars rc_scroll_text_field is rc_text_field;
 define :class vars rc_multiscroll_text_field is rc_scroll_text_field;
 define :class vars rc_textin_field is rc_text_field;
 define :class vars rc_multitextin_field is rc_textin_field;
 define :class vars rc_slider_field is rc_panel_field;
 define :class vars rc_dial_field is rc_panel_field;
 define :class vars rc_buttons_field is rc_panel_field;
 define -- -- Special buttons field sub-classes
 define :class vars rc_actions_field is rc_buttons_field;
 define :class vars rc_radio_field is rc_buttons_field;
 define :class vars rc_someof_field is rc_buttons_field;
 define -- graphic_field
 define :class vars rc_graphic_field is rc_panel_field;
 define interpret_graphic_spec(spec, field, x, y, aligned, width, height);
 define :method rc_draw_graphic_field(field:rc_graphic_field, x, y, aligned, width, height);
 define -- Utility procedures and methods
 define rc_translate_panel_spec(specs) -> specs;
 define :method rc_field_coords(field:rc_panel_field) /* -> (x,y) */;
 define :method updaterof rc_field_coords(field:rc_panel_field);
 define :method print_instance(f:rc_panel_field);
 define :method rc_field_of_label(panel:rc_panel, label) -> field;
 define :method rc_fieldcontents_of(panel:rc_panel, label) -> list;
 define :method rc_field_item_of_name(panel:rc_panel, label, num) -> item;
 define :method updaterof rc_field_item_of_name(item, panel:rc_panel, label, num);
 define rc_update_field(val, panel, field, num, converter);
 define vars procedure rc_update_fields(val, veclist);
 define panel_update(object, val, veclist);
 define rc_increment_slider(panel, label, num, inc);
 define :method slider_value_of_name(panel:rc_panel, label, num) -> val;
 define :method updaterof slider_value_of_name(panel, label, num);
 define rc_increment_dial(panel, label, num, inc);
 define :method dial_value_of_name(panel:rc_panel, label, num) -> val;
 define :method updaterof dial_value_of_name(panel, label, num);
 define :method rc_field_info_of_label(panel:rc_panel, label)/* -> possible info */;
 define rc_check_options_available(info, field_options, panel, label);
 define :method updaterof rc_field_info_of_label(info, panel:rc_panel, label);
 define PANELFIELD(label);
 define -- The global variable: rc_control_panel_keyspec
 define updaterof set_field_ident(wid, field);
 define updaterof set_field_aligned(val, field);
 define vars procedure rc_interpret_field_spec(vec, field, type);
 define -- Procedures for creating field records from specification lists
 define rc_num_rows_of_cols(len, cols) -> rows;
 define lconstant check_has_colon(list) -> rest;
 define parse_field_header(list, field_inst, type) -> list;
 define text_field_instance(list, type) -> field;
 define getscrolltext_details(field, list) -> (text_w, text_h, cols, rows);
 define multiscroll_text_field_instance(list, type) -> field;
 define scroll_text_field_instance(list, type) -> field;
 define multitextin_field_instance(list, type) -> field;
 define textin_field_instance(list, type) -> field;
 define slider_field_instance(list, type) -> field;
 define dial_field_instance(list, type) -> field;
 define buttons_field_instance(list, newproc, type) -> field;
 define actions_field_instance(list, type) -> field;
 define someof_field_instance(list, type) -> field;
 define radio_field_instance(list, type) -> field;
 define graphic_field_instance(list, type) -> field;
 define -- Create the field instances from a user specification list
 define vars rc_list_to_field(field, title) -> field;
 define fields_from_descriptors(fields, title) -> fields;
 define lconstant redraw_old(panel, panel_objects, redrawing);
 define :method rc_redraw_panel(panel:rc_panel);
 define :method rc_redraw_window_object(panel:rc_panel);
 define global vars rc_control_panel(x, y, fields, title) -> panel;
 define -- Revisions

define -- Revisions
*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 19 2002
		Fixed case of sliders with "round" feature. The constraint is now set
		I.e. the value in rc_constrain_contents,
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 25 2002
    replaced rc_informant_contents with rc_informant_value

	Allowed {fieldlabel <label>} as an alternative to
	{label <label>}. "fieldlabel" is less ambiguous, and contrasts
	with "itemlabel"

--- Aaron Sloman, Aug 24 2002
	Allowed multiple scrolltext fields and also allowed individual
	scrolltext panels to have associated featurespec vectors.

	Allowed more field components to have individual labels

--- Aaron Sloman, Aug 23 2002
	Moved isword_or_ident to rc_informant

--- Aaron Sloman, Aug  9 2002
		 added rc_check_empty_panel_field = false;

--- Aaron Sloman, Aug  7 2002
		Added is*word_or_ident
		Various other changes to cope with rc_buttons changes.

	Allowed multiple text/number input panels.
	the sub-fields of a multitextin are automatically treated as TEXTIN or
	NUMBERIN but actually they can be mixed.

--- Aug  4 2002
	changed rc_field_of_label(panel:rc_panel, label)
	To use "=" not "==" for its test, so as to work on other things
	than words.

--- Jul 28 2002
	made the main mixin and class use "vars"
		

--- 27 Jul 2002

	New slots in rc_panel class
	slot rc_panel_width;
	slot rc_panel_height;
	Added
		method rc_redraw_window_object(panel:rc_panel);
		Added {resize true} to panel options
		rc_control_panel now does this after creation of panel
			if resizable then rc_set_resize_handler(panel) endif;
		made rc_redraw_panel draw panel items first, then other objects
		in the window. Also even if the panel has been resized it uses
		the original panel width when redrawing panel objects specified
		in rc_control_panel


--- Aaron Sloman, Jul 26 2002
		Removed global lconstant procedures. Made some old ones accessible
		to users.
		rc_check_options_available(info, field_options, panel, label);
		rc_num_rows_of_cols(len, cols) -> rows;


--- Aaron Sloman, Mar 17 2001
		Introduced dialbg to specify dial colour

--- Aaron Sloman, Mar 11 2001
		Fixed redrawing of dials,using rc_redraw_linepic

--- Aaron Sloman, Mar  9 2001
		Introduced rc_translate_panel_spec, to allow more abbreviations
			in featurespecs
		Introduced global variable rc_panel_abbreviations

		Fixed handling of specs in dials field to allow reactors
		to work. May need further fixing.

		Also allowed slider fields to have an additional featurespec
		vector.

--- Sept 2000 Added dials to rc_control_panel

--- Aaron Sloman, Jul 23 2000
	Had to change the scroll text font from 6x12 to 6x13. I don't know why.

--- Aaron Sloman, Jul 22 2000
	Introduced this for RADIO and SOMEOF fields
		{chosenbg rc_chosen_background}
	Added slots rc_field_text_bg rc_field_text_fg for button fields and
		renamed the slots for scrolltext fields.
	Introduced
			{textfg rc_field_text_fg}
			{textbg rc_field_text_bg}
	for button types as well as scrolltext types.
--- Aaron Sloman, Jul 21 2000
	Allowed {labelfont <string>} to be used for sliders for font for
	end labels.
	Added rc_slider_field_font_def
	Added rc_scroll_text_field_font_def
	and changed some other defaults to use helevetica
--- Aaron Sloman, Jul  4 2000
	Changed for new format rc_scrolltext
--- Aaron Sloman, Jul  3 2000
	Changed to use opaque sliders by default
--- Aaron Sloman, Jul  3 2000
	Changed to use opaque square sliders when square specified
	Changed to use "blob" sliders rather than panel sliders by default for
	scrolltext fields (because opaque sliders are now available).
	Changed some default grey levels
--- Aaron Sloman, Jun 14 2000
	Removed get_*font_specs(font). Use rc_font*_dimensions instead.
--- Aaron Sloman, Jun  9 2000
	Made rc_panel_offset no longer lvars slot. Fixed redrawing of scrolltext
	fields and sliders.
--- Aaron Sloman, Sep 15 1999
	Fixed formatting of panels with width "panel"
--- Aaron Sloman, Sep 13 1999
	Made global variable declarations use define :rc_defaults
	Allowed {font <string>} to work for actions buttons, etc.
--- Aaron Sloman, Aug  5 1999
	Extended rc_control_panel to allow an optional extra argument which is
	newXXX procedure for creating a window object. This is then passed on
	to the call of rc_new_window_object
--- Aaron Sloman, Jul 28 1999
	Corrected the list rc_control_panel_keyspec : the "type" abbreviation
	was in the wrong place. Considerably improved HELP RC_CONTROL_PANEL
--- Aaron Sloman, Jul 27 1999
	Fixed rc_redraw panel to handle {select ...} {deselect ...}
		properly.
--- Aaron Sloman, Jun 25 1999
	Fixed bug with dlocal in rc_redraw_panel
--- Aaron Sloman, May 29 1999
	problems solving sub-panels...
	Fixed in rc_window_object. Also transferred handling of symbolic
	coordinates, and extending window to rc_window_object
--- Aaron Sloman, May 23 1999
	Allowed location in container panel to be specified symbolically
	as well as numerically.
--- Aaron Sloman, May 21 1999
	Made panels sensitive to all event types by default
--- Aaron Sloman, May 20 1999
	Changed rc_control_panel to allow empty list of fields, i.e. just
	size, foreground and background specification, etc.
	Also by default it should be mouse and keyboard sensitive.
--- Aaron Sloman, May 19 1999
	Allowed optional container argument for parent rc_window_object
--- Aaron Sloman, May 16 1999
	Fixed width, and cases where rows==0 or cols==0, for scrolltex
--- Aaron Sloman, May 14 1999
	Fixed reactor for scrolltext
--- Aaron Sloman, May 11 1999
	Added this for SCROLLTEXT
			{acceptor rc_scroll_text_field_acceptor}
--- Aaron Sloman, May  9 1999
	Set rc_print_strings_offset to 0.
--- Aaron Sloman, May  8 1999
	Allowed a bit more vertical space for TEXTIN and NUMBERIN
--- Aaron Sloman, May  8 1999
	Allowed scrolltext fields to have cols=0 or rows=0.
--- Aaron Sloman, May  4 1999
	Moved label stuff from text field to texin field where it belonged.
	added SCROLLTEXT
--- Aaron Sloman, Apr 17 1999
	Added rc_update_field, rc_update_fields, and panel_update demonstrated
	in teach rc_constrained_panel
		added new {reactor <veclist> } syntax for invoking it.
	Made updaterof rc_field_item_of_name always update the informant_contents,
	not the contents. The previous definition was an aberration.
	Improved some of the comments.
--- Aaron Sloman, Apr 16 1999
	Fixed problem of negative gap reducing height of window.
--- Aaron Sloman, Apr 11 1999
	defined updater for
		rc_field_info_of_label(info, panel:rc_panel, label);
	to handle RADIO and SOMEOF fields.

	Made updater of rc_field_item_of_name handle display buttons properly.
		(Needed for TEACH rc_constrained_panel example.)
--- Aaron Sloman, Apr  8 1999
	Added {places ...} option for sliders.
--- Aaron Sloman, Apr  5 1999
	Replaced rc_pressedcolour with rc_field_pressedcolour
	Make the list of allowable field keys a list of specifications held in
	the global variable: rc_control_panel_keyspec. Rewrote
	rc_interpret_field_spec to use this.
	Revised HELP RC_CONTROL_PANEL
--- Aaron Sloman, Apr  3 1999
	Allowed "default" and value of ident variable to set defaults for
	radio and someof buttons, using rc_set_button_defaults
	
--- Aaron Sloman, Mar 30 1999
	Made to set ident field for someof and radio buttons.
	Used rc_reactor_depth to prevent reactors running while panels
	are being built.
--- Aaron Sloman, Mar 29 1999
	Added rc_field_reactor
--- Aaron Sloman, Mar 26 1999
	Added rc_field_constraint
--- Aaron Sloman, Mar 26 1999
	Sorted out {align centre} for TEXTIN and NUMBERIN, and allowed
	{activegb ...} property for them.
--- Aaron Sloman, Mar 23 1999
	Extended support for TEXTIN and NUMBERIN fields, by allowing
	specifiers labelstring, labelfont, and labelcolour, and making
	sure the offset can accommodate the labelstring.
	Also allowed {ident nnn} to make the textin or number in
	field automatically update the variable nnn.
--- Aaron Sloman, Feb 25 1999
	Fixed bugs in handling of TEXTIN and NUMBERIN fields
	Made rc_interpret_field_spec user definable (and renamed it)
--- Aaron Sloman, Feb 24 1999
	Added {step <number>} as a specifier for slider fields. The
	number then becomes the value of rc_slider_step for each
	slider in the field.
--- Aaron Sloman, Feb 24 1998
	Added rc_panel_objects(panel), allowing [GRAPHIC ...] fields which
		create objects to know about them.

	Added rc_redrawing_panel. Made true after first time panel is redrawn.

	Fixed re-drawing of sliders in rc_redraw_panel

	Moved command to prevent scaling of slider field size specs
	to rc_redraw_panel
--- Aaron Sloman, Feb  6 1998
	Altered to make slider width refer to total width after offset
	including label on right.
	Allowed {width panel}
	Fixed to cope with negative xscale
	Previous fixes had stopped {spacing <int>} working, now fixed
	Background now drawn in uniform way for all fields.
	Height of background corrected for text fields and other cases.
	Removed confusion of rc_field_label in slider field
	dlocalised rc_foreground in loop drawing fields.

--- Aaron Sloman, Feb  3 1998
	Changed to make margin work on sliders. Default field-bg is false.
	Handled field_bg uniformly for all fields.

--- Aaron Sloman, Jan 30 1998
	Changed rc_field_gap_def to have default 0, not 4. Also changed
	"==" to "=" in default slots with _def variables.

	Prevented drawing of horizontal line for graphic field with height
	== 0.

--- Aaron Sloman, Nov 17 1997
	New syntax for sliders in a slider field, allowing identifier
	or word as first element of the list.

--- Aaron Sloman, Nov 16 1997
	Allowed a slider or other field to have an informant_ident

	Allowed the slider type to be a creator procedure
--- Aaron Sloman, Nov 14 1997
	Fixed to handle {align panel} properly in a graphic field.

--- Aaron Sloman, Nov 11 1997
	Generalised margin field. Needed for sliders.
--- Aaron Sloman, Nov  6 1997
	Changed to handle offsets, and cleared up alignment and origina and
	scale options in graphical fields.
--- Aaron Sloman, Nov  5 1997
	replaced rc_field_*centred with rc_field_aligned
--- Aaron Sloman, Nov  4 1997
	Introduced these slots and their default values,
		rc_slider_field_barframecol, rc_slider_field_barframewidth
	and new options for slider properties.
		framecol framewidth
	Gave rc_field_item_of_name an updater

--- Aaron Sloman, Nov  3 1997
	Introduced rc_slider_field_barcol rc_slider_field_barcol_def
	rc_field_override_specs rc_field_override_specs_def

--- Aaron Sloman, Aug 15 1997
	removed uses rc_default*window_object

--- Aaron Sloman, Aug  6 1997
	Allowed GRAPHIC fields to have "bg" and "fg" specifications.
	Other miner fixes
	Introduced rc_current_panel_field

--- Aaron Sloman, Aug  3 1997
	Changed to use "square" sliders

--- Aaron Sloman, Aug  2 1997
	Replaced rc_slider_*height with rc_slider_field_height
--- Aaron Sloman, Jul 24 1997
	Removed formatting bug due to adding margin for graphic fields.
	Allowed graphic fields to have origin at top left of panel.

--- Aaron Sloman, Jul 21 1997
	changed to use "align" instead of "centre", and to allow a
	list of field properties

--- Aaron Sloman, Jul 18 1997
	Added GRAPHIC type fields

--- Aaron Sloman, Jul 15 1997
	Allowed panel specification to indicate minimum height and width

	Allowed a field to have {centre right} or {center right} to be
	right justified.
--- Aaron Sloman, Jul  9 1997
	added updaterof slider_value_of_name(pane, name, num);

--- Aaron Sloman, Jul  7 1997
	Added rc_current_panel, and various utilities
	rc_field_of_label rc_fieldcontents_of
	rc_field_item_of_name
	rc_increment_slider slider_value_of_name
	rc_field_info_of_label
	PANELFIELD(label);
--- Aaron Sloman, Jul  5 1997
	Made rc_field_contents work for all types of fields.

	Generalised rc_field_of_label to allow a field to be specified by
	number.
--- Aaron Sloman, Jul  4 1997
	Fixed bug in spacing of sliders
--- Aaron Sloman, Jul  3 1997
	Added sliders
	Fixed bug in spacing
 */
