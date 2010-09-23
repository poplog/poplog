/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_opaque_slider.p
 > Purpose:         Slider with blob using rc_opaque_mover
 > Author:          Aaron Sloman, Jun 29 2000 (see revisions)
 > Documentation:
 > Related Files:
 */


/*

rc_kill_window_object(win1);
vars win1 = rc_new_window_object("right", "top", 350, 350, true, 'win1');
vars win1 = rc_new_window_object(650, 20, 500, 500, {250 250 2 -2}, 'win1');

vars ss1 = rc_opaque_slider(0, 0, -50, -50, 100, 5, 'red','black',
	[[{0 -20 'LO'}][{-20 10 'HI'}]],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
		;;; where p=panel, f=font (i.e. string)
	{rc_constrain_contents ^round
		rc_slider_step 5
		rc_slider_barframe ^(conspair('black', 2))
	 	rc_slider_value_panel
		;;; panel info
		;;; {endnum bg    fg      font   px  py  length ht}
			{1   'grey90' 'black' '8x13' 12  10  40    15}});


vars ss2 = rc_opaque_slider(-100, -100, 0, -100, 100, 7, 'red','blue',
	[[{0 -20 'LO'}][{-20 10 'HI'}]],
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
vars ss3 = rc_opaque_slider(50, 50, -150, -100, 100, 6, 'red','black',[],
		;;; panel info {endnum bg fg font places px py length ht fx fy}
	{rc_slider_convert_out ^round
	 	rc_slider_value_panel
		;;; panel info {endnum bg fg font    places px py length ht fx fy}
					   {1 'grey90' 'black' '8x13' 0 8 10 40 15 2 -6}});



rc_start();
vars ss4 =
	rc_opaque_slider(-100, 120, 100, 120, {0 1 0.25}, 5,
		'yellow', 'red', [[{-5 10 'lo'}] [{-5 10 'hi'}]],
			{rc_draw_slider_blob ^rc_draw_opaque_slider_square});

vars ss5 =
	rc_opaque_slider(-130, 110, 100, -120, {0 1 0.25}, 6,
		'grey85', 'red', [[{-5 10 'lo'}] [{-5 10 'hi'}]], newrc_square_opaque_slider);

rc_slider_value(ss3) =>

*/


section;
compile_mode :pop11 +varsch +defpdr -lprops -constr +global
                        :popc -wrdflt -wrclos;


uses rclib
uses rc_window_object
uses rc_slider
uses rc_opaque_mover
uses rc_defaults


define :rc_defaults;
	rc_opaque_slider_frame_def = conspair('grey20', 2);
	rc_slider_square_thickness_def = 2;
enddefine;

define :class vars rc_opaque_slider; is rc_slider rc_opaque_movable;
	slot rc_draw_slider_blob == "rc_draw_slider_opaque";
	slot rc_opaque_bg = rc_slider_barcol_def;
	slot rc_slider_barframe = rc_opaque_slider_frame_def;
enddefine;


define :method rc_setup_slider_barwidth(slider:rc_opaque_slider, radius);

	lvars ratio = 1;

	round(radius * 2 / ratio) + 1 -> rc_slider_barwidth(slider);

enddefine;


define :method rc_draw_slider_opaque(s:rc_opaque_slider);
	;;; for non-circular blobs
	lvars
		scaled = rc_slider_scaled(s),
		scale =
			if scaled then max(abs(rc_xscale), abs(rc_yscale))+0.0
			else 1
			endif,
		rad = rc_slider_blobradius(s),
		rx = rad*0.5/abs(rc_xscale),
		ry = rad*0.5/abs(rc_yscale),
		colour = rc_slider_blobcol(s),
	    ;
	dlocal
		rc_panel_slider_blob = 1,
		%rc_foreground(rc_window)%,
		;

	if colour then colour -> rc_foreground(rc_window) endif;
	rc_draw_unscaled_blob(0, 0, round(rad*scale), colour);

enddefine;

define :class vars rc_square_opaque_slider; is rc_opaque_slider;
	slot rc_draw_slider_blob == "rc_draw_opaque_slider_square";
	slot rc_slider_square_thickness = rc_slider_square_thickness_def;
enddefine;

define :method rc_draw_opaque_slider_square(s:rc_opaque_slider);
	;;; for non-circular blobs. Compare LIB RC_SQUARE_SLIDER
	lvars
		;;; square cannot be too large: otherwise the ends of the
		;;; bar will corrupted
		;;;
		r = 1.5*rc_slider_blobradius(s),
		col = rc_slider_blobcol(s);
	rc_draw_centred_square(0, 0, r, col, 3);
enddefine;


define rc_opaque_slider(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) -> slider;
	lvars spec, wid, type ;

	;;; see if word or identifier argument is provided.
	if isword(strings) or isident(strings) then
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings) ->
			(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, wid)
	else
		false -> wid
	endif;

	if iskey(strings) or isprocedure(strings) then
		x1, y1, x2, y2, range, radius, linecol, slidercol, strings
        ->
		(x1, y1, x2, y2, range, radius, linecol, slidercol, strings, type);
	else
		false -> type;
	endif;

	;;; see if optional featurespec argument has been provided
	if isvector(strings) or (islist(strings) and islist(slidercol)) then
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
		x1, y1, x2, y2, range, radius, linecol, slidercol, strings, spec,
			type or newrc_opaque_slider,
			if wid then wid endif) -> slider;

	rc_slider_barcol(slider) -> rc_opaque_bg(slider);
	
	if wid then
		;;; put blob in right place with clean bar
		rc_draw_slider_bar(slider);
		rc_slider_value(slider) -> rc_slider_value(slider);
		rc_draw_linepic(slider);
	endif;
enddefine;


endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Jul 28 2002
		changed classes to vars
--- Aaron Sloman, Jul 21 2000
	Changed compile mode, to make recompilation easier
 */
