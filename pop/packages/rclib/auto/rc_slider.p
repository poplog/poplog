/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_slider.p
 > Purpose:			Make a slider
 > Author:          Aaron Sloman, Jul  1 1997 (see revisions)
 > Documentation:   HELP RC_SLIDER, HELP RCLIB
 > Related Files:	LIB RC_CONTROL_PANEL, LIB RC_SQUARE_SLIDER
 */

/*

rc_kill_window_object(win1);
vars win1 = rc_new_window_object( 750, 20, 350, 350, true, 'win1');
vars win1 = rc_new_window_object( 650, 20, 500, 500, {250 250 2 -2}, 'win1');

vars ss1 = rc_slider(0, 0, -50, -50, 100, 9, 'red','black',
	['6x13bold' [{0 -20 'LO'}][{-20 10 'HI'}]],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
		;;; where p=panel, f=font (i.e. string)
	{rc_constrain_contents ^round
;;;		rc_slider_step 5
		rc_slider_barframe ^(conspair('black', 3))
;;;		rc_slider_barframe ^(conspair('black', 0))
	 	rc_slider_value_panel
		;;; panel info
		;;; {endnum bg    fg      font   px  py  length ht}
			{1   'grey90' 'black' '8x13' 12  10  40    15}});

untrace slider_value_from_coords, slider_coords_from_value;
ss1.rc_slider_step =>
rc_slider_value(ss1) =>
rc_informant_value(ss1) =>
20 -> rc_slider_step(ss1);
10 -> rc_slider_step(ss1);
34.99 -> rc_slider_value(ss1);
35.22 -> rc_slider_value(ss1);
39.25 -> rc_slider_value(ss1);
vars rc_constrain_slider = true;
330 -> rc_slider_value(ss1);
61 -> rc_informant_value(ss1);
rc_move_by(ss1, -5, -5, true); ss1.rc_coords =>
rc_move_by(ss1, 5, 5, true); ss1.rc_coords =>
rc_move_to(ss1, -10, -10, true); ss1.rc_coords =>
rc_move_to(ss1, -15.0, -15.0, true); ss1.rc_coords =>
ss1.rc_line_length =>

vars ss1a = rc_slider(-100, 100, 0, -100, 100, 9, 'red','black',
	['10x20bold' [{0 -20 'LO'}][{-20 10 'HI'}]],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
		;;; where p=panel, f=font (i.e. string)
	{rc_slider_convert_out ^identfn
		rc_slider_step 5
		rc_slider_barframe ^(conspair('black', 2))
		rc_slider_textin ^false
	 	rc_slider_value_panel
		;;;{endnum bg    fg      font   px py  length ht}
		   {1   'grey90' 'black' '8x13' 12  10  60    15}});

rc_start();

vars ss1b = rc_slider(50, 50, -50, 50, 100, 8, 'red','yellow',
	[[{0 -20 'LO'}][{-20 10 'HI'}]],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
		;;; where p=panel, f=font (i.e. string)
	{rc_constrain_contents round
		rc_slider_step 5
		rc_slider_barframe ^(conspair('black', 2))
		rc_slider_textin ^false
	 	rc_slider_value_panel
		;;; {endnum bg    fg      font   px py length ht}
			{1   'grey90' 'black' '8x13' 12 0  35    15}});

vars ss1b = rc_slider(-50, 65, 50, 65, 100, 9, 'red','black',
	['12x24' [{0 -20 'LO'}][{-20 10 'HI'}]],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
		;;; where p=panel, f=font (i.e. string)
	{rc_slider_convert_out ^identfn
		;;; rc_slider_places 0
		rc_slider_step 5
		rc_slider_textin ^false
		rc_slider_barframe ^(conspair('black', 2))
	 	rc_slider_value_panel
		;;; {endnum bg    fg      font places px py length ht fx fy}
			{2   'grey90' 'black' '8x13'  0   12 0  50    15  2  -4}});


;;; Now do the same with an extra argument "sliderval"
;;; This will define a variable to be kept in step with the slider.
vars sliderval = 55;

vars ss2 = rc_slider(0, 30, -50, 80, 100, 9, 'red','black',
	[[{-20 -14 'LO'}][{-10 10 'HI'}]],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
	{rc_constrain_contents ^round
		rc_slider_barframe ^(conspair('black', 2))
	 	rc_slider_value_panel
		;;; panel info {endnum bg fg font    places px py length ht fx fy}
					   {1 'grey90' 'black' '8x13' 0 12 0 35 15 2 -4}},
		"sliderval");

ss2.rc_informant_ident =>
ss2 =>
sliderval =>
ss2.rc_slider_value =>
ss2.rc_informant_value =>
25 -> ss2.rc_informant_value;
sliderval, ss2.rc_slider_value, ss2.rc_informant_value =>

30 -> ss2.rc_slider_value;
sliderval, ss2.rc_slider_value =>

vars ss3 =
    rc_slider(-65, 65, -50, -25, {-500 500 100},
		6, 'white', 'gray10', [[{5 5 'MIN'}] [{-35 0 'MAX'}]],
			{rc_slider_convert_out round
					rc_slider_barframe ^(conspair('red', 2))});

vars ss3a =
    rc_slider(-80, -65, 60, -65, {-500 500 100},
		6, 'white', 'gray10', [[{5 10 'MIN'}] [{-10 10 'MAX'}]],
			{rc_slider_convert_out ^round
					rc_slider_barframe ^(conspair('red', 2))});

vars ss3b =
    rc_slider(-80, -95, 80, -95, {-500 500 100},
		6, 'white', 'gray10', [[{5 10 'MIN'}] [{-10 10 'MAX'}]],
			{rc_slider_convert_out ^round
				rc_slider_textin ^false
					rc_slider_barframe ^(conspair('red', 2))});



;;; repeat with identifier

cancel sliderval;

vars sliderval = 66;

;;; slider should take on value of sliderval
vars ss4 =
    rc_slider(-85, 65, -75, -45, {-500 500},
		6, 'white', 'gray10', [[{5 5 'MIN'}] [{-25 -5 'MAX'}]],
			{rc_slider_convert_out ^round
				rc_slider_step 0
					rc_slider_barframe ^(conspair('red', 2))},
						ident sliderval);

sliderval =>


sliderval, ss4.rc_slider_value, ss4.rc_informant_value =>
123.5 -> rc_slider_value(ss4);
vars x; for x from -500 by 5 to 500 do x -> rc_slider_value(ss4); endfor;

;;; Try again after:
20-> rc_slider_step(ss4);
	
rc_kill_window_object(win1a);
vars win1a = rc_new_window_object( 650, 20, 350, 350, true, 'win1');
vars ss1 = rc_slider(0, 0, -100, -100, 100, 7, 'red','black',
	[[{-10 10 'LO'}][{10 -10 'HI'}]],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
	{rc_slider_convert_out ^round
	 	rc_slider_value_panel
		;;; panel info {endnum bg fg font    places px py length ht fx fy}
					   {1 'grey90' 'black' '8x13' 0 8 10 35 15 2 -6}});

5 -> rc_slider_value(ss1);


;;; Use this to clear the picture if needed
rc_start();
rc_event_types(win1) =>
;;; Optional test - change background
;;; 'pink' -> rc_background(rc_widget(win1));

;;; rc_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;
;;; with optional spec at end

vars ss1 = rc_slider(0, 0, -100, -100, 100, 7, 'red','black',[],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
	{rc_slider_convert_out ^round
	 	rc_slider_value_panel
		;;; panel info {endnum bg fg font    places px py length ht fx fy}
					   {1 'grey90' 'black' '8x13' 0 8 10 40 15 2 -6}});

22.345 -> rc_slider_value(ss1);
ss1 =>
ss1.rc_line_length =>
ss1.rc_slider_value =>
ss1.rc_informant_value=>
rc_move_by(ss1, -2,0, true);
vars x; for x from 0 to 100 do x -> rc_slider_value(ss1); syssleep(1) endfor;

vars ss2 =
    rc_slider(-130, 130, -100, -50, {-500 500 0},
		6, 'white', 'gray10', [[{5 5 'MIN'}] [{-35 0 'MAX'}]],
			{rc_slider_convert_out ^round
					rc_slider_barframe ^(conspair('red', 2))});

500 -> ss2.rc_slider_value;
-500 -> ss2.rc_slider_value;
0 -> ss2.rc_slider_value;

vars ss2a =
    rc_slider(-130, 130, 100, -50, {-50 50 0},
		8, 'white', 'blue', [[{5 10 'MIN'}] [{5 10 'MAX'}]],
			{rc_slider_barframe ^(conspair('red', 2))});


rc_start();
define rc_slider_square(s);
	;;; for non-circular blobs. Compare LIB RC_SQUARE_SLIDER
	lvars r = rc_slider_blobradius(s);
	rc_draw_centred_square(0, 0, 2*r + 2, 'blue', 2);
	rc_drawline(0,r,0,-r);
enddefine;

vars ss3 =
	rc_slider(-100, 120, 100, 120, {0 1 0.25}, 8,
		'black', 'red', [[{-5 10 'lo'}] [{-5 10 'hi'}]],
			{rc_draw_slider_blob ^rc_slider_square});

vars ss3a =
	rc_slider(-100, 120, 100, 120, {0 1 0.25}, 8,
		'black', 'red', [[{-5 10 'lo'}] [{-5 10 'hi'}]],
			{rc_draw_slider_blob ^rc_draw_hor_slider_blob});


vars ss3b =
	rc_opaque_slider(-150, 130, -150, -130, {0 1 0.25}, 8,
		'grey80', 'red', [[{8 0 'lo'}] [{-15 0 'hi'}]],
			{rc_slider_barframe ^(conspair('blue', 2))
			rc_draw_slider_blob ^rc_draw_vert_slider_blob});

vars ss3b =
	rc_slider(-150, 130, -150, -130, {0 1 0.25}, 8,
		'grey80', 'red', [[{8 0 'lo'}] [{-15 0 'hi'}]],
			{rc_slider_barframe ^(conspair('blue', 2))
			rc_draw_slider_blob ^rc_draw_vert_slider_blob});

rc_start();


2 -> rc_slider_places(ss3);
ss3 =>
rc_move_by(ss3, 3, 0, true); ss3.rc_slider_value =>
rc_move_by(ss1, 3, 0, true);

vars ss4 = rc_slider(120, 105, -95, -120, 10, 6, 'grey85', 'grey10', false);
round -> rc_slider_convert_out(ss4);

rc_start();

uses rc_square_slider;
vars ss5 = create_rc_slider(
	40, -40, -40, 40, 8, 8, 'blue', 'red',[],
		{rc_slider_square_thickness 3}, newrc_square_slider);


;;; ratio of blob width to bar width, default 1.5
1->	rc_slider_blob_bar_ratio;

vars ss5a = rc_square_slider(
	125, -140, -130, 40, 8, 6, 'blue', 'red',[],
		{rc_slider_square_thickness 3});

0.6 ->	rc_slider_blob_bar_ratio;
vars ss5b = rc_square_slider(
	-135, 5, 100, 5, {-8 8 0}, 4, 'blue', 'red',[],
		{rc_slider_square_thickness 3});

1.5 ->	rc_slider_blob_bar_ratio;
vars ss6 = rc_slider(-125, -30, 100, -30, {-10 10 3}, 4, 'blue', 'yellow', false);
3-> rc_slider_places(ss6);
ss6=>
1.5 ->	rc_slider_blob_bar_ratio;

vars ss6a = rc_slider(
	-125, -60, 100, -60, {-10 10 3}, 4, 'blue', 'yellow', false,
		{rc_slider_barwidth 10});

applist([%ss1, ss2, ss3, ss4, ss5, ss6%], rc_slider_value) =>
rc_slider_value(ss6)=>
applist([%ss1, ss2, ss3, ss4, ss5, ss6%], npr);

*/

section;
compile_mode :pop11 +varsch +defpdr -lprops -constr +global
                        :popc -wrdflt -wrclos;

uses rclib
uses rc_informant
uses rc_constrained_mover
uses rc_text_input
uses rc_buttons
uses rc_defaults

define :rc_defaults;

	rc_panel_slider_blob = false;

	;;; ratio of blob width to bar width, default 1.5
	rc_slider_blob_bar_ratio = 1.5;

	;;; default for slider value panel (rc_slider_value_panel)
	rc_slider_value_panel_def =
    ;;; {endnum bg     fg     font   places px py length ht fx fy}
        {2   'grey80' 'black' '8x13' 2      10  0  55    15 2  -4};

	;;; Default number of decimal places to print
	rc_slider_places_def = 2;

	;;; default sensitive area for the slider blob
	rc_mouse_limit_def = 5;
	rc_slider_blobradius_def = 5;
	rc_slider_blobcol_def = 'red';
	rc_slider_barwidth_def = 5;
	rc_slider_barcol_def = 'black';
	rc_slider_barframe_def = false;
	rc_slider_scaled_def = true;

	;;; Two procedures for converting values when going in and out
	;;; They default to identfn, which leaves values unchanged.
	rc_slider_convert_in_def = identfn;
	rc_slider_convert_out_def = identfn;

	;;; default font for end labels is current font
	rc_slider_labels_font_def = false;

enddefine;

define :class vars rc_slider_blob_window; is rc_window_object rc_point_constrained_mover ;
	;;; windows that can act as blobs for sliders.
	slot rc_slider_of == false;
	slot rc_slider_radius == false;
	slot rc_exit_handler == false;
	slot rc_entry_handler == false;
enddefine;



;;; If this is true, keep slider within bounds, otherwise report
;;; error if it goes beyond the bounds
global vars rc_constrain_slider = false;

define :mixin vars rc_slider_frame;
    is rc_informant;
	;;; A line with a movable "blob" plus some strings.
	;;; The default blob is circular and filled in, but other types
	;;; are possible.

	;;; The blob is a mouse sensitive instance of rc_linepic.
	;;; The slider's  rc_picx/y values are those of the blob,
	;;; and rc_move_to and rc_draw_linepic etc.
	;;; when applied to a slider affect only the blob

	;;; The stored internal value, mapped onto blob location
	;;; default value may be given
	slot rc_slider_default == false;
	;;; default for pop_pr_places when the value is printed
	slot rc_slider_places = rc_slider_places_def;
	;;; default sensitive area for the slider blob
	slot rc_mouse_limit = rc_mouse_limit_def;
	;;; This is a drawing procedure
	slot rc_draw_slider_blob == "rc_draw_slider_blob_def";
	;;; so is this
	slot rc_pic_lines == "rc_draw_slider_mover";
	slot rc_slider_blobradius = rc_slider_blobradius_def;
	slot rc_slider_blobcol = rc_slider_blobcol_def;
	slot rc_slider_barwidth = rc_slider_barwidth_def ;
	slot rc_slider_barcol = rc_slider_barcol_def ;
	slot rc_slider_barframe = rc_slider_barframe_def;
	
	;;; any string label will move with the blob.
	slot rc_pic_strings == [];

	;;; range is a pair with upper and lower bounds
	slot rc_slider_range == conspair(0,100);
	;;; minimal amounts by which to increase or decrease value
	slot rc_slider_step == 0;
	slot rc_slider_convert_in = rc_slider_convert_in_def ;
	slot rc_slider_convert_out = rc_slider_convert_out_def ;
	;;; associate each end with a set of strings in vector format
	;;; {dx dy <string>} for rc_print_at
	slot rc_slider_end1strings = [];
	slot rc_slider_end2strings = [];
	;;; default font for end labels is current font
	slot rc_slider_labels_font = rc_slider_labels_font_def;
	;;; Value of this slot is a vector used by the value drawing
	;;; method
	slot rc_slider_value_panel = rc_slider_value_panel_def ;
		;;; above is {endnum bg fg font places px py length ht fx fy}
	slot rc_slider_active_button == false;
	slot rc_informant_reactor == "rc_slider_reactor";
	;;; make the following false to prevent slider dimensions being scaled.
	slot rc_slider_scaled = rc_slider_scaled_def;
	;;; by default include a number input panel
	slot rc_slider_textin = true;
	slot rc_slider_blob == false;
	slot rc_slider_startloc == false;
enddefine;

define :class vars rc_slider;
    is rc_slider_frame rc_selectable rc_point_constrained_mover ;
enddefine;

define :class vars rc_slider_panel; is rc_number_input;
	;;; The panel where the slider value is shown

	;;; slot for the slider holding the panel
	slot rc_numberin_slider == false;
enddefine;

define :class vars rc_slider_panel_noinput; is rc_number_input;
	;;; The panel where the slider value is shown, allowing no input
	;;; slot for the slider holding the panel
	slot rc_numberin_slider == false;
enddefine;

define :class vars rc_slider_bar; is rc_invisible_action_button;
	slot rc_slider_of == false;
enddefine;

rc_slider_bar_key -> rc_button_type_key("slider_bar");

define :method rc_handle_text_input(pic:rc_slider_panel_noinput, x, y, modifier, key);
	;;; do nothing at all
enddefine;

define :method rc_button_1_down(pic:rc_slider_panel_noinput, x, y, modifiers);
	;;; do nothing
enddefine;

/*
define -- Methods for creating text input panel and invisible button
*/


lconstant panelerror = 'SLIDER PANELINFO VECTOR SHOULD HAVE 8 or 11 elements';

;;; This is used to suppress recursive updates
lvars updating_level = 0;

define :method create_slider_panel(slider:rc_slider_frame, panelinfo) -> numberin;

	;;; suppress chains of updates during construction
	dlocal updating_level = 2;

	lvars
	  	endnum, bg, fg, font, places, px, py, len, ht, fx, fy;

	if datalength(panelinfo) == 11 then
		;;; For backward compatibility. Some components now ignored
		explode(panelinfo) ->
	  		(endnum, bg, fg, font, places, px, py, len, ht, fx, fy);
	elseif datalength(panelinfo) == 8 then
		explode(panelinfo) ->
	  		(endnum, bg, fg, font, px, py, len, ht);
	else
		mishap(panelerror, [^panelinfo])
	endif;

	;;; ignore places, fx, fy.
	lvars
		(x, y) =
			explode(if endnum==1 then rc_pic_end1 else rc_pic_end2 endif(slider));

	lvars activebg = false;
	if ispair(bg) then destpair(bg) ->(bg, activebg) endif;

	;;; adjust for scale
	px/rc_xscale -> px;
	- py/rc_yscale -> py;
	
	;;; Adjust for width of bar
	lvars adjust = 0.5*max(ht, rc_slider_barwidth(slider));

	py - adjust/rc_yscale -> py;

	rc_slider_places(slider) -> places;

	create_text_input_field(x+px, y+py, len, ht,
		[%rc_informant_value(slider),
		if bg then {bg ^bg} endif,
		if fg then {fg ^fg} endif,
		if activebg then {activebg ^activebg} endif,
		{places ^places}%],
		false, font,
			if rc_slider_textin(slider) then
				newrc_slider_panel
			else
				newrc_slider_panel_noinput
			endif) -> numberin;

	;;; Link up slider and panel
	slider -> rc_numberin_slider(numberin);
	numberin -> rc_slider_value_panel(slider);

enddefine;

define lconstant move_button_slider(slider);
	rc_move_to(slider, rc_action_button_x, rc_action_button_y, true)
enddefine;

constant procedure rc_slider_ends; 	;;; defined below

/*
;;; tests
in_rectangle(-20, 0,  0,0,0, 0, -100, 0, 100, 200, 10)=>
in_rectangle(-18, 0,  0,0,0, 0, -100, 0, 100, 200, 10)=>
in_rectangle(-14, 0,  0,0,0, 0, -100, 0, 100, 200, 10)=>
in_rectangle(-10, 100, 0,0,0, 0, -100, 0, 100, 200, 10)=>
in_rectangle(-1, 100, 0,0,0, 0, -100, 0, 100, 200, 10)=>
in_rectangle(10, 100, 0,0,0, 0, -100, 0, 100, 200, 10)=>
in_rectangle(-5, 109, 0,0,0, 0, -100, 0, 100, 200, 10)=>
in_rectangle(-5, 108, 0,0,0, 0, -100, 0, 100, 200, 10)=>
in_rectangle(20, 20,  0,0,0, 0, 0, 200, 200, 282.843, 10)=>
in_rectangle(25, 20,  0,0,0, 0, 0, 200, 200, 282.843, 10)=>
in_rectangle(50, 61,  0,0,0, 0, 0, 100, 100, 141.421, 6)=>
in_rectangle(25, 30,  0,0,0, 0, 0, 50, 50, 70.7107, 3)=>

rc_distance(0,0,100,100)=>
rc_distance(0,0,50,50)=>
*/
define lconstant in_rectangle(x, y, picx, picy, slider, x1, y1, x2, y2, dist, width) -> boolean;
	;;; A crude hack to decide whether x, y is in the rectangle
	;;; defined by the line joining mid ends x1, y1, x2, y2, of
	;;; width 2*width, where dist is the length of the rectangle, and the
	;;; and rectangle sticks out at each end by about widht.

	;;; picx, picy, and slider are dummy arguments, to do with how
	;;; rc_mouse_limit is used in lib rc_mousepic

	;;; [d1 ^d1 d2 ^d2 ratio ^ratio mult ^(0.6 - sqrt(sqrt(ratio))*0.5)]=>

	if	abs(x1 - x2) < width then
		;;; roughly vertical rectangle -- easy
		if y1 > y2 then y1, y2 -> (y2, y1) endif;
		rc_between(y, y1-width, y2+width) and abs(x - x1) <= width  -> boolean
	elseif abs(y1 - y2) < width then
		;;; roughly horizontal rectangle -- easy
		if x1 > x2 then x1, x2 -> (x2, x1) endif;
		rc_between(x, x1-width, x2+width) and abs(y - y1) <= width -> boolean
	else
		lvars
			d1 = rc_distance(x, y, x1, y1),
			d2 = rc_distance(x, y, x2, y2);
		if d1 < width or d2 < width then
			true -> boolean
		else
			lvars ratio = abs(d1 - d2)/dist;
			d1 + d2 < dist + (1/dist + ratio)*width*0.5 -> boolean;
		endif;
	endif;
enddefine;

global vars rc_slider_selected = false;

define :method rc_button_1_down(pic:rc_slider, x, y, modifiers);
	call_next_method(pic, x, y, modifiers);
	pic -> rc_slider_selected;
enddefine;

define :method rc_sliderbutton_1_down(pic:rc_slider_bar, x, y, modifiers);
	;;; Button down in "invisible" action button covering slider bar
	;;; Immediately move the slider to this location.
	lvars slider = rc_slider_of(pic);
	slider -> rc_slider_selected;
	rc_move_to(slider, x, y, true);
	slider -> rc_mouse_selected(rc_active_window_object);
	slider -> rc_selected_action_button;
enddefine;

define :method rc_sliderbutton_1_drag(pic:rc_slider_bar, x, y, modifiers);
	;;; if pic == rc_selected_action_button then
	lvars current_selected = rc_mouse_selected(rc_active_window_object);
	returnif(current_selected and pic /== current_selected);
	if pic == rc_slider_selected or rc_slider_of(pic) == rc_slider_selected then
		;;; move the button to the location, and leave it "active"
		;;; rc_rcbutton_1_up(pic, x, y, modifiers);
		;;; rc_sliderbutton_1_down(pic, x, y, modifiers);
		rc_move_to(rc_slider_of(pic), x, y, true);
		;;; pic -> rc_selected_action_button;
		;;; pic -> rc_mouse_selected(rc_active_window_object);
	endif;
enddefine;


define :method create_slider_button(slider:rc_slider_frame, rad);
	;;; Create invisible action button with sensitive area approximately
	;;; located over the slider bar, of width 2*rad

	lvars (x1,y1,x2,y2) = rc_slider_ends(slider);

	lvars button;

	create_rc_button(x1, y1,
		;;; width and height irrelevant.
		0,0,
		;;; Action: move blob to mouse location
		[^nullstring {[^move_button_slider ^slider]}],
		"slider_bar",false) ->> button -> rc_slider_active_button(slider);

	slider -> rc_slider_of(button);

	;;; Alter the default sensitive area specification
	in_rectangle(%x1, y1, x2, y2, rc_distance(x1,y1,x2,y2),rad%)
		-> rc_mouse_limit(button);

	;;; allow dragging handler to move the slider blob
	{rc_sliderbutton_1_down ^false ^false} -> rc_button_down_handlers(button);
	{rc_sliderbutton_1_drag ^false ^false} -> rc_drag_handlers(button);

enddefine;

/*

define -- Drawing utilities for sliders and their parts

*/

define :method rc_draw_slider_blob_def(s:rc_slider_frame);
	;;; Default procedure for drawing slider blobs.
	;;; This can be redefined for different forms of slider
	;;; default is a blob, but it could be a rectangle, etc.

	lvars
		scaled = rc_slider_scaled(s),
		scale =
			if scaled then max(abs(rc_xscale), abs(rc_yscale))+0.0
			else 1
			endif,
		rad = rc_slider_blobradius(s)*scale,
		col = rc_slider_blobcol(s);

	;;;Veddebug('about to draw blob');

	unless rc_panel_slider_blob then
		rc_draw_unscaled_blob(0, 0, round(rad), col);
	endunless

enddefine;

define :method rc_draw_vert_slider_blob(s:rc_slider);
	;;; Draw a slider blob for vertical slider
	;;; A square with a horizontal line across middle

	lvars rad = rc_slider_blobradius(s);

	dlocal
		%rc_line_width(rc_window)% = 2,	;;; Is that a good default?
		%rc_foreground(rc_window)% = rc_slider_blobcol(s);

	rc_draw_centred_rect(0, 0, (rad*2 -1 ), (rad*2 - 1), false, false);
	rc_drawline(-rad, 0, rad, 0);
enddefine;

define :method rc_draw_hor_slider_blob(s:rc_slider);
	;;; Draw a slider blob for horizontal slider
	;;; Use a square with vertical line down middle

	lvars rad = rc_slider_blobradius(s);

	dlocal
		%rc_line_width(rc_window)% = 2,	;;; Is that a good default?
		%rc_foreground(rc_window)% = rc_slider_blobcol(s);

	rc_draw_centred_rect(0, 0, (rad*2 - 1), (rad*2 -1), false, false);
	rc_drawline(0, -rad, 0, rad);
enddefine;


define rc_draw_slider_mover(pic);
	;;; draw the moving blob, but make it easy to set different shapes
	;;; for individual instances
	recursive_valof(rc_draw_slider_blob(pic))(pic);
enddefine;

define :method rc_setup_slider_barwidth(slider:rc_slider, radius);

	;;; work out bar ratio: 1 when the blob is a panel
	lvars ratio =
		if rc_panel_slider_blob then 1 else rc_slider_blob_bar_ratio endif;

	round(radius * 2 / ratio) -> rc_slider_barwidth(slider);

enddefine;



define :method rc_draw_slider_bar(s:rc_slider_frame);
	lvars
		scaled = rc_slider_scaled(s),
		scale =
			if scaled then max(abs(rc_xscale), abs(rc_yscale))+0.0,
			else abs(rc_yscale) endif,
		(x1,y1,x2,y2) = rc_slider_ends(s),
		width = rc_slider_barwidth(s),
		frame = rc_slider_barframe(s),
		barcol = rc_slider_barcol(s);

	returnunless(barcol);
	if scaled then width*scale else width endif -> width;

	;;; draw the slider barframe, if appropriate
	;;;Veddebug('about to draw background '><[frame ^frame]);
	if frame then
		if isprocedure(recursive_valof(frame)) then
			recursive_valof(frame(s))
		elseif ispair(frame) then
			;;; thickness and colour
			lvars (framecol, thick) = fast_destpair(frame);
			if thick == 0 then false -> thick endif;
			if thick then
				if scaled then thick*scale else thick endif -> thick;
				;;;Veddebug('drawing blobs '><framecol >< [thick ^thick width ^width]);
				;;; do end1 as a circle: It will become a semi-circle
				rc_draw_unscaled_blob(x1, y1, round(width  div 2 + thick), framecol);
			endif;
			rc_draw_unscaled_blob(x1, y1, round(width  div 2) , barcol);
			;;;Veddebug('left blobs done');
			;;; Now end2
			if thick then
				rc_draw_unscaled_blob(x2, y2, round(width div 2 + thick), framecol);
			endif;
			rc_draw_unscaled_blob(x2, y2, round(width div 2), barcol);
			;;;Veddebug('right blobs done');
			if thick then
				rc_drawline_relative(x1,y1,x2,y2, framecol, (width + 2*thick)/abs(rc_yscale));
			endif;
			;;;Veddebug('line done');
		else
			mishap('EXPECTING PAIR FOR BARFRAME', [^s ^frame])
		endif
	endif;
	;;; draw the slider bar
	;;;Veddebug('about to draw bar '><[width ^width col ^barcol]);
	rc_drawline_relative(x1,y1,x2,y2, barcol, width/abs(rc_yscale));

enddefine;

define rc_draw_slider_strings(x, y, strings, scaled);
	;;; draw strings represented in the list as a vector of triples,
	;;; {dx dy string}. Draw them relative to x y.
	lvars vec, dx, dy, string;
	for vec in strings do
		explode(vec) -> (dx, dy, string);
		unless scaled then
			dx/rc_xscale -> dx;
			-dy/rc_yscale -> dy;
		endunless;
		;;; [print_at ^x ^dx ^y ^dy ^string]=>
		rc_print_at(x+dx, y+dy, string)
	endfor
enddefine;

define :method rc_draw_slider_labels(s:rc_slider_frame);
	;;; Draw the strings associated with each end of the slider
	lvars
		scaled = rc_slider_scaled(s),
		font = rc_slider_labels_font(s),
		(x1,y1,x2,y2) = rc_slider_ends(s);

	dlocal %rc_font(rc_window)%;

	if font then font -> rc_font(rc_window) endif;

	rc_draw_slider_strings(x1, y1, rc_slider_end1strings(s), scaled);
	rc_draw_slider_strings(x2, y2, rc_slider_end2strings(s), scaled);
enddefine;

define :method rc_draw_slider_value(slider:rc_slider_frame, val);
	;;; Draw a simple panel, and print the value on it
	;;; Make all values independent of scale

	lvars
		panelinfo = rc_slider_value_panel(slider);
	returnunless(panelinfo);

	lvars
		scaled = rc_slider_scaled(slider),
		(minval,maxval) = destpair(rc_slider_range(slider));

	if isvector(panelinfo) then
		;;; Text input panel net yet initialised. Make one
		create_slider_panel(slider, panelinfo) -> panelinfo;
		val -> rc_informant_value(panelinfo);
	endif;

	rc_draw_linepic(rc_slider_value_panel(slider));

enddefine;

/*

define :method rc_draw_slider_value_noinput(s:rc_slider_frame, val);
	;;; Draw a simple panel, and print the value on it
	;;; Make all values independent of scale
	lvars
		scaled = rc_slider_scaled(s),
		panelinfo = rc_slider_value_panel(s),
		(minval,maxval) = destpair(rc_slider_range(s));

	if panelinfo then
		;;; unpack the 8 element or 11 vector with drawing instructions.
		lvars
	  		endnum, bg, fg, font, places, px, py, len, ht, fx, fy;

	    if datalength(panelinfo) == 11 then
		    ;;; For backward compatibility. Some components now ignored
		    explode(panelinfo) ->
	  		    (endnum, bg, fg, font, places, px, py, len, ht, fx, fy);
	    elseif datalength(panelinfo) == 8 then
		    explode(panelinfo) ->
	  		    (endnum, bg, fg, font, px, py, len, ht);
				2 -> places;
				2 -> fx;
				-4 -> fy;
	    else
		    mishap(panelerror, [^panelinfo])
	    endif;

		lvars
			(x, y) =
				explode(if endnum==1 then rc_pic_end1 else rc_pic_end2 endif(s));

		unless places then rc_slider_places(s) -> places endunless;

		;;; work out where to draw the background for the number panel
		;;; (ought to check string size requirements for the font).
		px/rc_xscale -> px;
		- py/rc_yscale -> py;
		len/rc_xscale -> len;
		ht/abs(rc_yscale) -> ht;

		;;; clear the backround panel
		rc_drawline_relative(
				x + px, y + py, x + px + len, y + py, bg, ht);

		;;; draw the number,  but first set defaults
		dlocal
			%rc_font(rc_window)%,
			%rc_foreground(rc_window)%,
			pop_pr_places,
			pop_pr_quotes = false;

		if font then font -> rc_font(rc_window) endif;

		if fg then fg -> rc_foreground(rc_window) endif;

		if places and places /== 0 then `0` << 16 || places -> pop_pr_places endif;

		;;; see if space is needed for a '-' sign
		if minval < 0 or maxval < 0 then
			max(4, fx) -> fx
		endif;

		;;; And finally,
		fx/rc_xscale -> fx;
		-fy/rc_yscale -> fy;

		rc_print_at(
			x + px + fx, y + py + fy,
			   if val >= 0 then space else nullstring endif >< val);
	endif;
enddefine;

*/


define :method rc_draw_slider(s:rc_slider_frame);

	rc_draw_slider_bar(s);
	;;;Veddebug('About to do labels');
	rc_draw_slider_labels(s);
	rc_draw_slider_value(s, rc_informant_value(s));

	;;; draw the blob after the bar and strings, in case they overlap
	lvars blob = rc_slider_blob(s);
	unless isrc_window_object(blob) then
		;;; If it's a panel, don't do anything
		rc_draw_linepic(s);
	endunless;

enddefine;

/*
define :method rc_undraw_linepic(s:rc_slider);
	;;; needed for re-drawing moving blob.
	lvars blob = rc_slider_blob(s);
	if isrc_window_object(blob) then
		;;;it's a panel, don't do anything
	elseif blob then
		rc_undraw_linepic(blob);
	endif;
enddefine;
*/

/*

define -- Some utilities for sliders

*/

define rc_slider_ends(slider) /* ->( x1, y1, x2, y2) */;
	;;; return coordinates of ends
	explode(rc_pic_end1(slider));
	explode(rc_pic_end2(slider));
enddefine;

define constrain_between(val, v1, v2) -> val;
	;;; ensure val is between v1 and v2
	max(min(v1,v2), val) -> val;
	min(max(v1,v2), val) -> val;
enddefine;

define slider_value_from_coords(s, x, y) -> val;
	;;; Find the value corresponding to current location
	;;; Divide distance of slider point from start by slider length
	;;; and multiply by range
	lvars
		(x1, y1, x2, y2) = rc_slider_ends(s),
		line = rc_line_orientation(s),
		(rangestart, rangeend) = destpair(rc_slider_range(s)),
		rangedist = rangeend - rangestart;
	
	rc_project_point(x, y, x1, y1, explode(line)) -> (x,y);
	if rc_constrain_slider then
		constrain_between(x, x1, x2) -> x;
		constrain_between(y, y1, y2) -> y;
	endif;

	(rangedist*rc_distance(x, y, x1, y1))
					/rc_line_length(s) + rangestart -> val;

	recursive_valof(rc_slider_convert_out(s))(val) -> val;
enddefine;

define slider_value_from_blob_coords(blob, s, x, y) -> val;
	rc_container_xy(blob, x, y) -> (x, y);
	slider_value_from_coords(s, x, y) -> val;
enddefine;

define lconstant check_value_constrained(val, low, high, s) -> val;
	if rc_constrain_slider then
		constrain_between(val, low, high) -> val;
	elseif val < low or val > high then
		mishap('Slider value out of range', [^val in ^s])
	endif;
enddefine;

define lconstant slider_coords_from_value(s, val) -> (x, y);
	;;; Find coordinates corresponding to new value of slider

	;;; First get the constrained value
	recursive_valof(rc_constrain_contents(s))(val) -> val;

	unless isnumber(val) then
		mishap('Constrained slider value not a number',
			[%val, s%])
	endunless;

	;;; check that the value is within limits
	lvars
		(rangestart, rangeend) = destpair(rc_slider_range(s)),
		rangedist = rangeend - rangestart;

	check_value_constrained(val, rangestart, rangeend, s) -> val;

	;;; Now convert to internal value
	rc_slider_convert_in(s)(val) -> val;

	;;; Find distance from end1 and work out location
	lvars
		dist = ((val - rangestart)*rc_line_length(s))/rangedist,
		(linecos, linesin) = explode(rc_line_orientation(s)),
		(x1, y1) = explode(rc_pic_end1(s));

	x1 + dist*linecos -> x;
	y1 + dist*linesin -> y;
enddefine;

define slider_blob_coords_from_value(blob, s, val) -> (x, y);
	slider_coords_from_value(s, val) -> (x, y);
	;;; may need further transformation???	
enddefine;

define lconstant adjust_step_value(s, val) -> val;
	;;; Given a value, find the nearest stepped point
	lvars
		(rangestart, rangeend) = destpair(rc_slider_range(s)),
		stepval = rc_slider_step(s);

	if stepval /== 0 then
		dlocal popdprecision = true;
		round((val - rangestart)/stepval) * stepval + rangestart -> val;
	endif;
enddefine;

/*
define -- Printing methods
*/

define :method print_instance(s:rc_slider_frame);
	;;; pad places with 0s
	dlocal pop_pr_places;

	lvars places = rc_slider_places(s);

	if places and places /== 0 then
		`0` << 16 || places -> pop_pr_places
	endif;

	printf('<slider (%P,%P) (%P,%P) value: %P>',
				[^(rc_slider_ends(s)) ^(rc_informant_value(s))])
enddefine;

define :method print_instance(p:rc_slider_panel);
	printf('<SLIDER_PANEL at(%P,%P) value: %P>',
			[%rc_coords(p), rc_informant_value(p)%])
enddefine;

/*
define -- Methods for getting or updating the value
*/

define :method rc_slider_value(s:rc_slider_frame) -> val;
	;;; Ignore current location, just return stored value
	rc_informant_value(s) -> val;
enddefine;


vars	in_rc_slider_updater = false;

define :method updaterof rc_slider_value(newval, s:rc_slider_frame);

	returnif(in_rc_slider_updater);

	lvars
		old_win = rc_current_window_object,
		slider_win = rc_informant_window(s);

	if slider_win and slider_win /== old_win then
		slider_win -> rc_current_window_object
	endif;
	
	;;; Now convert to internal value
	rc_slider_convert_in(s)(newval) -> newval;

	lvars oldval = rc_informant_value(s);

	;;; First get the constrained value
	recursive_valof(rc_constrain_contents(s))(newval) -> newval;

	if newval = undef then oldval -> newval; return(); endif;

	;;; run step adjuster
	adjust_step_value(s, newval) -> newval;

	;;; check that it is within range
	check_value_constrained(newval, destpair(rc_slider_range(s)), s) -> newval;

	if newval /= oldval then
		;;; Update the location of the slider blob
		;;; Use this to prevent excessive recursion
		dlocal in_rc_slider_updater = true;

		;;; store revised version (Could violate constraint!!)
		newval -> rc_informant_value(s);

		lvars (x, y) = slider_coords_from_value(s, newval);

		;;; Moving the blob will update the internal value store
		rc_move_to(s, x, y, true);
		rc_draw_slider_value(s, newval);
		rc_information_changed(s);
	endif;
	if old_win /== rc_current_window_object then
		old_win -> rc_current_window_object;
	endif;
enddefine;


define :method rc_information_changed(s:rc_slider_frame);
	;;; make sure that the control variables are re-set before
	;;; propagating effects
	dlocal
		in_rc_slider_updater = false,
		updating_level = updating_level - 1;
	call_next_method(s);
enddefine;

define :method updaterof rc_informant_value(val, s:rc_slider_frame);
	;;; get constrained contents and update slider

	if in_rc_slider_updater then
		call_next_method(val, s);
	else
		val -> rc_slider_value(s);
	endif;
	returnif(updating_level > 1);
	lvars panel = rc_slider_value_panel(s);
	if isrc_number_input(panel) then
		;;; don't use val, use possibly constrained version
		rc_slider_value(s) -> rc_informant_value(panel)
	endif;
enddefine;

define :method updaterof rc_informant_value(val, numberin:rc_slider_panel);
	dlocal updating_level = updating_level + 1;
	unless updating_level > 1 then
		lvars slider = rc_numberin_slider(numberin);
		
		dlocal rc_constrain_slider = true;
		val -> rc_slider_value(slider);
		;;; Get value subject to slider constraints
		rc_slider_value(slider) -> val;
	endunless;
	;;; finally set the number panel
	call_next_method(val, numberin);
enddefine;




define :method rc_slider_reactor(s:rc_slider_frame, val);
	;;; default value of rc_informant_reactor. User definable
	rc_informant_reactor_def(s, val);
	;;; [new value of ^s is ^val] =>
enddefine;

define :method rc_move_to(s: rc_slider, x, y, trail);

	dlocal rc_constrain_slider = true;
	lvars
		(x1,y1,x2,y2) = rc_slider_ends(s),
		old_win = rc_current_window_object,
		slider_win = rc_informant_window(s);

	if slider_win and slider_win /== old_win then
		slider_win -> rc_current_window_object
	endif;
	constrain_between(x, x1, x2) -> x;
	constrain_between(y, y1, y2) -> y;

	if in_rc_slider_updater then
		;;; This will redraw the moving blob
		lvars blob = rc_slider_blob(s);
		if blob then
			rc_move_to(blob, x, y, trail);
		else
			call_next_method(s, x, y, trail);
		endif;
	else
		slider_value_from_coords(s, x, y) -> rc_informant_value(s);
	endif;
	if old_win /== rc_current_window_object then
		old_win -> rc_current_window_object;
	endif;
enddefine;


/*

define -- Creating sliders

*/

define :method setup_blob(blob:rc_slider_blob_window);

	define rc_drag_blob(pic, x, y, modifiers);
		lvars xscale,yscale,container = rc_window_container(pic);
		lvars
			slider= rc_slider_of(blob);

		rc_container_xy(blob, x, y) -> (x,y);

		;;; make sure the slider panel is redrawn in the parent window
		container -> rc_current_window_object;
		rc_move_to(slider, x, y, true);
	enddefine;

	rc_drag_blob -> rc_drag_handlers(blob)(1);
enddefine;


define create_rc_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, type) -> slider;
	;;; This is the most general slider creation procedure.
	;;; rc_slider handles special cases
	;;; type can be a class key, a "new" procedure or a class name

	;;; Convert type argument to procedure
	if iskey(type) then class_new(type) -> type
	elseif isword(type) then valof(consword('new' sys_><type)) -> type
	endif;

	unless isprocedure(type) then
		mishap('UNRECOGNIZED SLIDER TYPE', [^type])
	endunless;

	;;; See if separate end1 strings and end2 strings have been provided
	;;; and possibly a string representing a font at the front of the list

	lvars strings1, strings2, labelfont = false;

	if strings == [] or not(strings) then [], []
	elseunless(islist(strings)) then
		mishap('List(s) of vectors needed for slider strings',[^strings])
	else
		if isstring(front(strings)) then
			;;; font specified
			destpair(strings) ->(labelfont, strings);
		endif;

		if islist(front(strings)) then
			if listlength(strings) == 2 then
				strings(1), strings(2)
			else
				mishap('Two lists of vectors needed for slider strings',[^strings])
			endif	
		else
			;;; only strings for end1
			strings, []
		endif;
	endif -> (strings1, strings2);

	;;; See if range is a number or a pair, or a vector with a default
	;;; value
	lvars default = false, stepval = false;

	if isnumber(range) then
		conspair(0, range) -> range;
		0 -> default;
	elseif isvector(range) then
		lvars len = datalength(range);
		if len == 2 then conspair(explode(range)) -> range;
			fast_front(range) -> default;
		elseif len == 3 then conspair(explode(range) -> default) -> range
		elseif len == 4 then
			conspair(explode(range) -> (default, stepval) ) -> range
		else mishap('Inappropriate slider range specification', [^range])
		endif
	endif;

	;;; invoke slider instance creator
	type() -> slider;

    x1 -> rc_picx(slider);
    y1 -> rc_picy(slider);

	max(radius, 10/rc_xscale) -> rc_mouse_limit(slider);

	;;; work out bar ratio: 1 when the blob is a panel
	rc_setup_slider_barwidth(slider, radius);

	linecol -> rc_slider_barcol(slider);
	slidercol -> rc_slider_blobcol(slider);
	radius -> rc_slider_blobradius(slider);
	range -> rc_slider_range(slider);
	conspair(x1, y1) -> rc_pic_end1(slider);
	conspair(x2, y2) -> rc_pic_end2(slider);
	strings1 -> rc_slider_end1strings(slider);
	strings2 -> rc_slider_end2strings(slider);

	rc_current_window_object -> rc_informant_window(slider);

    if spec then
		 interpret_specs(slider, spec);
	endif;

	;;; This may override the default in spec
	if labelfont then labelfont -> rc_slider_labels_font(slider); endif;

	if isnumber(stepval) then stepval -> rc_slider_step(slider) endif;
	
	;;; set up line and orientation information
	rc_initialise_mover(slider);
	
	;;; prevent drawing when this assignment runs
	dlocal in_rc_slider_updater = true;
	default -> rc_informant_value(slider);

	if isinteger(default) and isinteger(stepval)
	or recursive_valof(rc_constrain_contents(slider)) == round
	or recursive_valof(rc_slider_convert_out(slider)) == round
	or recursive_valof(rc_slider_convert_in(slider)) == round
	then
		0 -> rc_slider_places(slider)
	endif;

	lvars (x, y) = slider_coords_from_value(slider, default);

	(x, y) -> rc_coords(slider);

	if rc_panel_slider_blob then
		;;; create new moving panel for slider blob
		
		lvars
			old_win = rc_current_window_object,
			side = round(2*radius) - 1,
			blob =
				rc_new_window_object(x, y, side, side, true,
					newrc_slider_blob_window, rc_current_window_object);

		slidercol -> rc_background(rc_widget(blob));
		blob -> rc_slider_blob(slider);
		slider -> rc_slider_of(blob);
		radius -> rc_slider_radius(blob);
		rc_pic_end1(slider) -> rc_pic_end1(blob);
		rc_pic_end2(slider) -> rc_pic_end2(blob);
		;;; set up line and orientation information
		rc_initialise_mover(blob);

		rc_mousepic(blob, [button motion]);
		setup_blob(blob);
		rc_sync_display();
		if old_win /== rc_current_window_object then old_win -> rc_current_window_object endif;
	endif;

	rc_draw_slider(slider);

	;;; [places ^(rc_slider_places(slider)) ^(rc_pr_places(rc_slider_value_panel(slider)))]=>

	unless lmember("motion", rc_event_types(rc_current_window_object)) then
		rc_mousepic(rc_current_window_object, #_< [motion button] >_#)
	endunless;

	;;; Create invisible action button located over bar
	create_slider_button(slider, radius);

	;;; do this last, so that slider blob takes precedence over the
	;;; invisible button
    rc_add_pic_to_window(slider, rc_current_window_object, true);

enddefine;

define create_rc_slider_with_ident(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, type, wid) -> slider;
	;;; wid is a word or identifier

	;;; save its value, in case overridden during creation.
	lvars val = valof(wid);

	create_rc_slider(
		x1, y1, x2, y2, range,
		radius, linecol, slidercol, strings, spec, type) -> slider;

	wid -> rc_informant_ident(slider);

	if isvector(range) and datalength(range) >= 3 then
		subscrv(3, range) -> valof(wid)
	elseif isundef(valof(wid)) then
		rc_slider_value(slider) -> valof(wid);
	else
		val -> rc_slider_value(slider);
	endif;

enddefine;

define rc_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;
	lvars spec, wid, type = newrc_slider ;

	;;; see if optional word/identifier argument is provided

	if isword(strings) or isident(strings) then
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) ->
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, wid) ;
	else
		false -> wid;
	endif;

	if iskey(strings) or isprocedure(strings) then
		x1, y1, x2, y2, range, radius, linecol, slidercol, strings
        ->
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, type);
	endif;

	;;; see if optional featurespec argument has been provided
	if isvector(strings) or (islist(strings) and islist(slidercol)) then
		x1, y1, x2, y2, range, radius, linecol, slidercol, strings
        ->
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec);
	else
		false -> spec
	endif;

	if wid then
		create_rc_slider_with_ident(
			x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, type, wid) -> slider;
	else
		create_rc_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, type) -> slider;
	endif;
enddefine;


define rc_panel_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;
	;;; Create slider with panel for moving blob. Accepts the same optional arguments
	;;; as rc_slider
	dlocal rc_panel_slider_blob = true;

	rc_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;
enddefine;

endsection;

nil -> proglist;

/*
CONTENTS

 define rc_slider_square(s);
 define :rc_defaults;
 define :class vars rc_slider_blob_window; is rc_window_object rc_point_constrained_mover ;
 define :mixin vars rc_slider_frame;
 define :class vars rc_slider;
 define :class vars rc_slider_panel; is rc_number_input;
 define :class vars rc_slider_panel_noinput; is rc_number_input;
 define :class vars rc_slider_bar; is rc_invisible_action_button;
 define :method rc_handle_text_input(pic:rc_slider_panel_noinput, x, y, modifier, key);
 define :method rc_button_1_down(pic:rc_slider_panel_noinput, x, y, modifiers);
 define -- Methods for creating text input panel and invisible button
 define :method create_slider_panel(slider:rc_slider_frame, panelinfo) -> numberin;
 define lconstant move_button_slider(slider);
 define lconstant in_rectangle(x, y, picx, picy, slider, x1, y1, x2, y2, dist, width) -> boolean;
 define :method rc_button_1_down(pic:rc_slider, x, y, modifiers);
 define :method rc_sliderbutton_1_down(pic:rc_slider_bar, x, y, modifiers);
 define :method rc_sliderbutton_1_drag(pic:rc_slider_bar, x, y, modifiers);
 define :method create_slider_button(slider:rc_slider_frame, rad);
 define -- Drawing utilities for sliders and their parts
 define :method rc_draw_slider_blob_def(s:rc_slider_frame);
 define :method rc_draw_vert_slider_blob(s:rc_slider);
 define :method rc_draw_hor_slider_blob(s:rc_slider);
 define rc_draw_slider_mover(pic);
 define :method rc_setup_slider_barwidth(slider:rc_slider, radius);
 define :method rc_draw_slider_bar(s:rc_slider_frame);
 define rc_draw_slider_strings(x, y, strings, scaled);
 define :method rc_draw_slider_labels(s:rc_slider_frame);
 define :method rc_draw_slider_value(slider:rc_slider_frame, val);
 define :method rc_draw_slider_value_noinput(s:rc_slider_frame, val);
 define :method rc_draw_slider(s:rc_slider_frame);
 define :method rc_undraw_linepic(s:rc_slider);
 define -- Some utilities for sliders
 define rc_slider_ends(slider) /* ->( x1, y1, x2, y2) */;
 define constrain_between(val, v1, v2) -> val;
 define slider_value_from_coords(s, x, y) -> val;
 define slider_value_from_blob_coords(blob, s, x, y) -> val;
 define lconstant check_value_constrained(val, low, high, s) -> val;
 define lconstant slider_coords_from_value(s, val) -> (x, y);
 define slider_blob_coords_from_value(blob, s, val) -> (x, y);
 define lconstant adjust_step_value(s, val) -> val;
 define -- Printing methods
 define :method print_instance(s:rc_slider_frame);
 define :method print_instance(p:rc_slider_panel);
 define -- Methods for getting or updating the value
 define :method rc_slider_value(s:rc_slider_frame) -> val;
 define :method updaterof rc_slider_value(newval, s:rc_slider_frame);
 define :method rc_information_changed(s:rc_slider_frame);
 define :method updaterof rc_informant_value(val, s:rc_slider_frame);
 define :method updaterof rc_informant_value(val, numberin:rc_slider_panel);
 define :method rc_slider_reactor(s:rc_slider_frame, val);
 define :method rc_move_to(s: rc_slider, x, y, trail);
 define -- Creating sliders
 define :method setup_blob(blob:rc_slider_blob_window);
 define create_rc_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, type) -> slider;
 define create_rc_slider_with_ident(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, type, wid) -> slider;
 define rc_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;
 define rc_panel_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 25 2002
    replaced rc_ informant_contents with rc_informant_value
		
--- Aaron Sloman, Aug 24 2002
	Slightly reduced size of square drawn in
		rc_draw_vert_slider_blob
		rc_draw_hor_slider_blob
	to reduce risk of spoiling frame
--- Aaron Sloman, Jul 27 2002
	made sure drag method does nothing if something else is the currentlyy
	selected object.
--- Aaron Sloman, Jul 23 2000
	Introduced square blobs for horizontal and vertical sliders

--- Aaron Sloman, Jul 21 2000
    Changed from compile_mode strict, to make recompilation easier.

	Added rc_slider_labels_font rc_slider_labels_font_def, allowing
	strings printed as labels to have a font.
	Modified HELP file and relevant bits of rc_control_panel

--- Aaron Sloman, Jul  3 2000
	Changed bar frame width of 0 to mean no bar frame
--- Aaron Sloman, Jun 30 2000
	In support of opaque sliders introduced
	method rc_setup_slider_barwidth
--- Aaron Sloman, Oct 10 1999
	Made updater switch temporarily to appropriate window object
--- Aaron Sloman, Jul  5 1999
	changed variable names in check_value_constrained to avoid
	clash with old use of "end"
--- Aaron Sloman, May 29 1999
	fixed problem with re-drawing number panel when blob panel is dragged
--- Aaron Sloman, May 28 1999
	Made panel slider only button and motion sensitive
--- Aaron Sloman, May 27 1999
	gave panel blobs false exit handler
--- Aaron Sloman, May 27 1999
	introduced class rc_slider_bar
--- Aaron Sloman, May 25 1999
	Added support for panel blobs rc_panel_slider_blob
--- Aaron Sloman, May 23 1999
	Ensured that convert_in procedure was activated in the updater of
	rc_slider_value, and that if it is round, that information is used in
	showing decimal points.
--- Aaron Sloman, May  8 1999
	Made it possible to "drag" invisible action button on the slider bar.
--- Aaron Sloman, May  4 1999
	Allowed bar colour false to produce an invisible bar.
--- Aaron Sloman, May  1 1999
	Made sliders that are approximately horizontal or vertical have an
	click sensitive along their length.
--- Aaron Sloman, Apr 29 1999
	exported constrain_between
--- Aaron Sloman, Apr 18 1999
	Changed to allow one slider's reactor to move another slider
	Introduced method rc_information_changed for sliders.
--- Aaron Sloman, Apr 17 1999
	Changed so that if the rc_slider_convert_out procedure is round, then the
	rc_slider_places field is set to 0.
--- Aaron Sloman, Apr  6 1999
	Gave all sliders a number input panel by default, controlled by the slot
	rc_slider_textin (default true).
--- Aaron Sloman, Apr  4 1999
	Ensured that slider_value_from_coords constrained its result if rc_constrain_slider
	is true.
--- Aaron Sloman, Apr  3 1999
	used rc_project_point, and slightly improved organisation
--- Aaron Sloman, Apr  1 1999
	Total reorganisation and rationalisation. Make all drawing caused by moving
	go via updating of slider value. Introduced
	slider_value_from_coords, slider_coords_from_value, constrain_between
--- Aaron Sloman, Mar 30 1999
	Changes to make use of new features in rc_informant, including the
	invocation of reactor mechanisms. See TEACH RC_CONSTRAINED_PANEL
--- Aaron Sloman, Feb 25 1999
	Modified create_rc_slider_with_ident to allow for a range vector of
	length 4
--- Aaron Sloman, Feb 24 1999
	Changed so that sliders have a slot rc_slider_step. Default value is 0.
	If it's anything else, the value is constrainted to be an integral number
	times the step above the minimum.
	Allowed the range vector to contain 4 elements, in which case the
	4th number is the minimum step value

--- Aaron Sloman, Feb  8 1998
	Further adjustments including making the px and fx values accumulate
	and also the py and fy
--- Aaron Sloman, Feb  7 1998
	Introduced slot rc_slider_scaled which will be made false in rc_control_panel
	Added scale argument to rc_draw_slider_strings
	Made other changes to ignore scale when rc_slider_scaled field is false.
	(Default true).

--- Aaron Sloman, Nov 29 1997
	Changed to make dy coordinate for strings increase upwards.
--- Aaron Sloman, Nov 17 1997
	Allowed rc_slider to take an extra argument which is a word or an
		identifier.
	Introduced
		create_rc_slider_with_ident
	which is like
		create_rc_slider
	except that it takes an extra word or identifier as value.
--- Aaron Sloman, Nov 16 1997
		Allowed for informant_ident field
--- Aaron Sloman, Nov  9 1997
	Made everything scale independent except for coordinates of ends.
	Takes account only of larger of abs(rc_xscale), abs(rc_yscale)

--- Aaron Sloman, Nov  3 1997
	replaced slot rc_slider_line*col with rc_slider_barcol
	added slot rc_slider_barframe, rc_slider_barframe_def
	and changed the line drawing procedures.

--- Aaron Sloman, Nov  1 1997
	Introduced several new _def global variables for default values and
	made printing in the value panel sensitive to whether the number can
	be negative or not. (Is that right?)

--- Aaron Sloman, Aug 10 1997
	Changed rc_draw_slider_mover, to take an argument, the picture
	object.
--- Aaron Sloman, Aug  2 1997
	Changed so that windows are not made more event sensitive than
	necessary.
--- Aaron Sloman, Jul  7 1997
	Generalised to allow different slider shapes
	Also introduced create_rc_slider as more general procedure, to handle
	different types
--- Aaron Sloman, Jul  4 1997
	added rc_constrain_slider
	added facilities for sliders in rc_control panel
 */
