/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_panel_slider.p
 > Purpose:			Creat a slider with a textin panel for its number display
 > Author:          Aaron Sloman, Apr  4 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/*
;;; TESTS
uses rclib;
uses rc_window_object;
;;; Test the commands below in each of these windows. Despite scale change,
;;; the text and number input fields should be the same size. Only location
;;; changes.
rc_kill_window_object(win1);
vars win1 = rc_new_window_object(700, 40, 300, 250, true, 'win1');
vars win2 = rc_new_window_object(520, 40, 600, 500, {300 250 2 2}, 'win1');

;;; create_rc_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, type)

rc_start();
vars ps1 =
	create_rc_slider(
	-50, 0, 50, 100, {-50 50 20}, 8, 'blue', 'red',[],
		[], newrc_panel_slider);

ps1=>
rc_slider_value(ps1)=>
vars np1 = rc_slider_value_panel(ps1);
np1 =>
-50 -> rc_slider_value(ps1);
30 -> rc_slider_value(ps1);

;;; If true, allows constraints to be violated, but corrects the value
vars rc_constrain_slider = true;
-300 -> rc_slider_value(ps1);
-20 -> rc_informant_value(np1);
225 -> rc_informant_value(np1);


vars ps2a = rc_panel_slider(-70, -30, 30, -30, {-40 100 0},  11, 'red','black',
	[[{0 -20 'LO'}][{-20 -20 'HI'}]],
	{rc_slider_convert_out ^identfn
		;;; rc_slider_step 5
		rc_slider_barframe ^(conspair('black', 2))
	 	rc_slider_value_panel
		;;; panel info {endnum bg    fg      font   places px py  length ht fx fy}
					   {2   'grey90' 'black' '8x13' ^false 10  8   50    15 2  -4}});

vars ps2b = rc_panel_slider(-70, 30, 30, 30, {-40 100 0},  11, 'red','black',
	[[{0 -20 'LO'}][{-20 -20 'HI'}]],
	{rc_slider_convert_out ^round
		;;; rc_slider_step 5
		rc_slider_barframe ^(conspair('black', 2))
	 	rc_slider_value_panel
		;;; panel info {endnum bg    fg      font   places  px py  length ht fx fy}
					   {1   'grey90' 'black' '8x13' ^false -55  8   50    15  2  -4}});

rc_start();

vars ps3 = rc_panel_slider(-50, -50, 50, -50, {-200 200 0},  9, 'red','black',
	[[{0 -20 'LO'}][{-20 10 'HI'}]],
	{rc_slider_convert_out ^identfn
		;;; rc_slider_step 5
		rc_slider_barframe ^(conspair('black', 2))
	 	rc_slider_value_panel
		;;; panel info {endnum bg    fg      font   places  px py  length ht fx fy}
					   {2   'grey90' 'black' '8x13' ^false  8  8   50    15  2  -4}});


vars ss3a =
    rc_panel_slider(-65, 65, -50, -25, {-500 500 100},
		6, 'white', 'gray10', [[{5 5 'MIN'}] [{-25 -15 'MAX'}]],
			{rc_slider_convert_out ^round
					rc_slider_barframe ^(conspair('red', 2))});

cancel sliderval;

vars sliderval = 66;

;;; slider should take on value of sliderval
vars ss4 =
    rc_panel_slider(-65, 65, -50, -25, {-500 500},
		6, 'white', 'gray10', [[{5 5 'MIN'}] [{-35 0 'MAX'}]],
			{rc_slider_convert_out ^round
				rc_slider_step 0
					rc_slider_barframe ^(conspair('red', 2))},
						ident sliderval);

sliderval =>


sliderval, ss4.rc_slider_value, ss4.rc_informant_value =>
123.5 -> rc_slider_value(ss4);
vars x; for x from -500 by 5 to 500 do x -> rc_slider_value(ss4); endfor;

Try again after:
20-> rc_slider_step(ss4);
	

*/

section;

uses rclib
uses rc_window_object
uses rc_mousepic
uses rc_text_input
uses rc_slider


global vars
	;;; default for slider value panel (rc_slider_value_panel)
	rc_slider_value_textin_def =
	;;; {endnum bg     fg     font places px py length ht fx fy}
		{2    'pink'  'blue' '8x13' 2    10  8  55    15 2  -4},
;


define :class rc_slider_panel; is rc_number_input;
	;;; The panel where the slider value is shown

	;;; slot for the slider holding the panel
	slot rc_numberin_slider == false;
enddefine;

define :method print_instance(p:rc_slider_panel);
	printf('<SLIDER_PANEL at(%P,%P) value: %P>',
			[%rc_coords(p), rc_informant_value(p)%])
enddefine;

define :class rc_panel_slider; is rc_slider;
	;;; Slot for the rc_number_input panel holding the slider
	;;; value
	slot rc_slider_value_panel = rc_slider_value_textin_def;
enddefine;

define :method print_instance(s:rc_panel_slider);
	;;; pad places with 0s
	dlocal pop_pr_places = `0` << 16 || rc_slider_places(s);

	printf('<PANEL_SLIDER (%P,%P) (%P,%P), value: %P>',
				[^(rc_slider_ends(s)) ^(rc_informant_value(s))])
enddefine;

lvars updating_level = 0;

define :method updaterof rc_informant_value(val, s:rc_panel_slider);
	dlocal updating_level = updating_level + 1;
	call_next_method(val, s);
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
		if isrc_panel_slider(slider) then
			dlocal rc_constrain_slider = true;
			val -> rc_slider_value(slider);
			;;; Get value subject to slider constraints
			rc_slider_value(slider) -> val;
		endif;
	endunless;
	;;; finally set the number panel
	call_next_method(val, numberin);
enddefine;

define :method create_slider_panel(slider:rc_panel_slider, panelinfo) -> numberin;
	lvars
	  	(endnum, bg, fg, font, places, px, py, len, ht, fx, fy)
			= explode(panelinfo),
		(x, y) =
			explode(if endnum==1 then rc_pic_end1 else rc_pic_end2 endif(slider));

	;;; adjust for scale
	px/rc_xscale -> px;
	- py/rc_yscale -> py;
	
	;;; Adjust for width of bar
	lvars adjust
		= (if endnum == 1 then -1 else 1 endif)*0.5*rc_slider_barwidth(slider);
	px + adjust/rc_xscale -> px;

	unless places then rc_slider_places(slider) -> places endunless;

	create_text_input_field(x+px, y+py, len, ht,
		[%rc_slider_value(slider)% {places ^places}],
		false, font, newrc_slider_panel) -> numberin;

	;;; Link up slider and panel
	slider -> rc_numberin_slider(numberin);
	numberin -> rc_slider_value_panel(slider);

enddefine;

define :method rc_draw_slider(s:rc_panel_slider);
	call_next_method(s);
	;;; rc_draw_slider_value(s, rc_slider_value(s));
enddefine;

define :method rc_draw_slider_value(slider:rc_panel_slider, val);
	;;; Draw a simple panel, and print the value on it
	;;; Make all values independent of scale
	lvars
		scaled = rc_slider_scaled(slider),
		panelinfo = rc_slider_value_panel(slider),
		(minval,maxval) = destpair(rc_slider_range(slider));

	if isvector(panelinfo) then
		;;; Text input panel net yet initialised. Make one
		create_slider_panel(slider, panelinfo) -> panelinfo;
		val -> rc_informant_value(panelinfo);
	endif;

	rc_draw_linepic(rc_slider_value_panel(slider));

enddefine;

define rc_panel_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;
	lvars spec, wid;

	;;; see if word or identifier argument is provided.
	if isword(strings) or isident(strings) then
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) ->
			(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, wid)
	else
		false -> wid
	endif;

	;;; see if optional featurespec argument has been provided
	if isvector(strings) then
		x1, y1, x2, y2, range, radius, linecol, slidercol, strings
        ->
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec)
	else
		false -> spec
	endif;

	if wid then
		create_rc_slider_with_ident
	else
		create_rc_slider
	endif(
		x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec, newrc_panel_slider,
			if wid then wid endif) -> slider;

enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 26 2002
	replaced rc_informant_contents with rc_informant_value

         CONTENTS - (Use <ENTER> gg to access required sections)

 define :class rc_slider_panel; is rc_number_input;
 define :method print_instance(p:rc_slider_panel);
 define :class rc_panel_slider; is rc_slider;
 define :method print_instance(s:rc_panel_slider);
 define :method updaterof rc_informant_value(val, s:rc_panel_slider);
 define :method updaterof rc_informant_value(val, numberin:rc_slider_panel);
 define :method create_slider_panel(slider:rc_panel_slider, panelinfo) -> numberin;
 define :method rc_draw_slider(s:rc_panel_slider);
 define :method rc_draw_slider_value(slider:rc_panel_slider, val);
 define rc_panel_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;

 */
