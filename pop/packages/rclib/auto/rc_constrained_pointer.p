/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_constrained_pointer.p
 > Purpose:			Create a combination of semi-circle and rotatable "arrow" pointer
 > Author:          Aaron Sloman, Jun 18 2000 (see revisions)
 > Documentation:	TEACH rc_constrained_pointer, HELP rclib
 > Related Files:	LIB * rclib,
		LIB rc_draw_pointer, rc_draw_semi_circle, rc_constrained_rotater rc_opaque_mover
 */

/*

rc_kill_window_object(win1);
rc_kill_window_object(win2);
rc_kill_window_object(win3);
vars win1 = rc_new_window_object( "right", 20, 450, 450, true, 'win1');
vars win2 = rc_new_window_object( "right", 20, 450, 450, {200 200 -1.5 1.5}, 'win2');
vars win3 = rc_new_window_object( "right", 20, 450, 450, {225 225 1.5 0.7}, 'win3');


rc_start();
vars p1 =
	instance rc_constrained_pointer;
		rc_picx = 100;
		rc_picy = 100;
		rc_rotater_orient = 0;
		rc_pointer_bg = 'red';
		rc_pointer_colour = 'yellow';
		rc_pivot_length = 100;
		rc_min_ang = 0;
		rc_max_ang = 135;
		rc_rotater_start_ang = 180;
		;;; rc_rotater_draw_arc = undef;
	endinstance;

-100-> rc_rotater_orient(p1);
false -> rc_pointer_initialised(p1);
rc_install_pointer(p1, rc_current_window_object);
rc_draw_linepic(p1);
100 -> rc_axis(p1) =>
rc_mousepic(win1); rc_add_pic_to_window(p1, win1, true);

p1.rc_pivot_coords =>
p1. rc_coords =>
p1.rc_axis =>
rc_mousepic(win2); rc_add_pic_to_window(p1, win2, true);
rc_mousepic(win3); rc_add_pic_to_window(p1, win3, true);

rc_constraint(p1) =>
p1=>
rc_axis(p1) =>
rc_set_axis(p1, 135, true);
rc_set_axis(p1, 180, true);
rc_end_x(p1), rc_end_y(p1) =>
rc_pivot_length(p1)=>
rc_pivot_coords(p1)=>
rc_end_coords(p1)=>
rc_real_end_coords(p1)=>
rc_turn_by(p1, 45, true);
rc_turn_by(p1, -45, true);
rc_move_to(p1, 99, 15, true);
rc_move_to(p1, 101, 15, true);
rc_move_to(p1, 0, 150, true);
rc_move_to(p1, 50, 65, true);

rc_coords(p1)=>
rc_undraw_linepic(p1);
rc_end_coords(p1) =>
rc_pivot_coords(p1) ,rc_coords(p1)=>
p1=>
rc_transxyout(70.71,70.71)=>

rc_move_to(p1, 100, 100, true);
rc_move_to(p1, 0, 100, true);
rc_move_to(p1, 45, -45, true);
rc_move_by(p1, -5,6, true);

rc_axis(p1) =>

vars p2 =
	instance rc_constrained_pointer;
		rc_picx = -100;
		rc_picy = -120;
		rc_pointer_colour = 'blue';
		rc_pointer_bg = 'pink';
		rc_pivot_length = 80;
		rc_rotater_orient = 90;
		rc_min_ang = 0;
		rc_max_ang = 180;
	endinstance;
rc_draw_linepic(p2);

rc_add_pic_to_window(p2, win1, true);
rc_add_pic_to_window(p2, win2, true);

rc_add_pic_to_window(p2, win3, true);
rc_coords(p2)=>
rc_pivot_coords(p2)=>
rc_real_pivot_coords(p2)=>
rc_end_coords(p2)=>
rc_real_end_coords(p2)=>
rc_undraw_linepic(p2);
rc_turn_by(p2, 45, true); rc_end_coords(p2), rc_axis(p2)=>
rc_turn_by(p2, -45, true);rc_end_coords(p2) =>
rc_pivot_coords(p2)=>
rc_end_coords(p2)=>
rc_real_end_coords(p2)=>

rc_move_to(p2, -200, 0, true);
rc_move_to(p2, -300, -100, true);
rc_move_to(p2, 0, 100, true);
rc_move_to(p2, -200, 100, true);
rc_move_to(p2, -100, 0, true);
rc_move_to(p2, -100, 100, true);
rc_move_to(p2, -200, -120, true);

rc_end_x(p2), rc_end_y(p2) =>

repeat 10 times rc_move_by(p2, -5,1, true); syssleep(10); endrepeat;
rc_coords(p2) =>
rc_real_end_coords(p2) =>
rc_pivot_y(p2)=>
p2 =>

rc_start();
vars p3 =
	instance rc_constrained_pointer;
		rc_picx = 100;
		rc_picy = -120;
		rc_pointer_colour = 'blue';
		rc_pointer_bg = 'pink';
		rc_pivot_length = 80;
		rc_rotater_orient = -90;
		rc_min_ang = 0;
		rc_max_ang = 180;
	endinstance;

rc_set_axis(p3, 145, true);
rc_draw_linepic(p3);

rc_add_pic_to_window(p3, win1, true);

rc_add_pic_to_window(p3, win3, true);

rc_end_coords(p3) =>
rc_pointer_value(p3) =>

rc_real_end_coords(p3) =>
rc_axis(p3) =>
rc_set_axis(p3, 200, true);
rc_move_to(p3, 10, -150, true)

rc_draw_blob(0,0,5,'red');

vars p4 =
	instance rc_constrained_pointer;
		rc_picx = -150;
		rc_picy = 120;
		rc_pointer_colour = 'brown';
		rc_pointer_bg = 'yellow';
		rc_pivot_length = 60;
		rc_rotater_orient = 180;
		rc_min_ang = 0;
		rc_max_ang = 180;
	endinstance;
rc_draw_linepic(p4);

rc_add_pic_to_window(p4, win1, true);

vars p5 = rc_constrained_pointer(0, 0, 45, 45, 135, 40, 12, 'red', 'yellow');

untrace rc_draw_pointer
untrace rc_draw_blob_sector
untrace rc_draw_blob
rc_draw_blob(3.5, 3.5, 5, 'blue');

vars p3c =
    rc_constrained_pointer(
        -80, 40, 135, 0, 90, 70, 10, 'blue', 'yellow');
rc_pointer_value(p3c) =>
rc_move_to(p3c, 140, 140, true);
rc_move_to(p3c, 140, 0, true);
rc_move_to(p3c, -80+15+140, 0, true);
rc_end_coords(p3c)=>
rc_real_end_coords(p3c)=>
rc_virtual_axis(p3c)=>
new_win1();


vars p3d =
    rc_constrained_pointer(
        -80, 140, 135, -45, 90, 70, 10, 'blue', 'red');
rc_coords(p3d) =>
rc_pivot_coords(p3d) =>
rc_pointer_value(p3d) =>
rc_move_to(p3d, 140, 140, true);
rc_move_to(p3d, 140, 0, true);
rc_move_to(p3d, -80+15+140, 0, true);
rc_end_coords(p3d)=>
rc_real_end_coords(p3d)=>
rc_virtual_axis(p3d)=>

vars p3e =
    rc_constrained_pointer(
        -90, -60, 0, -45, 90, 70, 10, 'blue', 'yellow');
rc_pointer_value(p3e) =>


vars p3f =
    rc_constrained_pointer(
        0, -60, 0, -135, 90, 70, 10, 'blue', 'yellow');
rc_pointer_value(p3f) =>


vars p3g =
    rc_constrained_pointer(
        100, -60, -135, -90, 90, 70, 10, 'blue', 'yellow');
rc_pointer_value(p3g) =>

-1180->rc_pointer_value(p3g);

vars p3h =
    rc_constrained_pointer(
        120, 100, 45, -135, 135, 70, 10, 'blue', 'yellow');
rc_pointer_value(p3h) =>

90->rc_pointer_value(p3h);

vars p3i =
    rc_constrained_pointer(
        -20, 140, -45, -135, 135, 70, 10, 'blue', 'yellow');
rc_pointer_value(p3i) =>

110->rc_pointer_value(p3i);


vars p3j =
    rc_constrained_pointer(
        -150, 100, -180, 0, 270, 70, 10, 'blue', 'red');
rc_pointer_value(p3j) =>

1110->rc_pointer_value(p3j);

vars p3k =
    rc_constrained_pointer(
        0, 0, -235, 0, 270, 70, 10, 'blue', 'red');
rc_pointer_value(p3k) =>

110->rc_pointer_value(p3k);

*/


section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;

/*

define -- Load required libraries and set defaults for globals

*/

uses rclib
uses rc_informant
uses rc_draw_pointer
uses rc_draw_semi_circle
uses rc_constrained_rotater
uses rc_opaque_mover
uses rc_draw_arc_segments
uses rc_label_dial

uses rc_defaults;

uses ARGS

define :rc_defaults;

	;;; if true, then if yscale is positive, the dials still
	;;; increment counter-clockwise by default
	rc_dial_counter_clockwise = true;

	rc_pointer_length_def = 20;
	rc_pointer_width_def = 10;	;;; angular with in degrees
	rc_pointer_colour_def = 'grey30';
	rc_pointer_bg_def = 'grey80';
	rc_pointer_orient_def = 0;

	;;; ratio between width of base of pointers and
	;;; amount of offset for semi-circular dials.
	rc_width_offset_ratio = 0.5;

	;;; Two procedures for converting values when going in and out
	;;; They default to identfn, which leaves values unchanged.
	rc_pointer_convert_in_def = identfn;
	rc_pointer_convert_out_def = identfn;

	;;; Default number of decimal places to print
	rc_informant_places_def = 2;
enddefine;

define :generic rc_pointer_mouse_limit(x, y, picx, picy, pic);
	;;; defined properly below
enddefine;

/*

define -- The class rc_constrained_pointer

*/

define :class vars rc_constrained_pointer;
	is rc_constrained_rotater rc_opaque_rotatable rc_selectable, rc_informant;

	slot rc_pic_lines = "rc_draw_constrained_pointer";

	;;; slots for optional "decorations"
	slot rc_pointer_marks = [];
	slot rc_pointer_labels = [];
	slot rc_pointer_captions = [];

	;;; give it a procedure (method) as mouse limit, so that it can
	;;; be defined to suit the dial geometry
	slot rc_mouse_limit = rc_pointer_mouse_limit;

	slot rc_pivot_length = rc_pointer_length_def;

	;;; pointer width in degrees
	slot rc_pointer_width = rc_pointer_width_def;

	slot rc_pointer_base = undef;	;;; to be derived from the width and length

	slot rc_pointer_offset == 0;

	;;; Pointer base will be offset this length from the
	;;; semi-circle's diameter, non zero only for semi-circular
	;;; dials.
	slot rc_pointer_base_offset == 0;
	slot rc_pointer_xinc == undef;
	slot rc_pointer_yinc == undef;

	slot rc_pointer_colour = rc_pointer_colour_def;

	;;; if bg is false, use default background
	slot rc_pointer_bg = rc_pointer_bg_def;
	slot rc_opaque_bg = rc_pointer_bg_def;

	;;; The orienatation of the dial in degrees.
	;;; 0 = upright,  90 = rotated 90degrees clockwise
	;;; if rc_scale is positive and rc_yscale negative.
	slot rc_rotater_orient = rc_pointer_orient_def;
	;;; angle from which to start drawing
	slot rc_rotater_start_ang = undef;
	;;; angle through which to draw
	slot rc_rotater_draw_arc = undef;
	;;; The first time it is drawn this is set true. After that
	;;; background is not redrawn
	slot rc_pointer_initialised == false;

	;;; For the window containing the dial
	;;; NOT NEEDED use rc_informant_window
	;;; slot rc_pointer_container == undef;

	;;; range of possible values
	slot rc_informant_start;
	slot rc_informant_end;
	;;; minimal amounts by which to increase or decrease value
	slot rc_informant_step == false;

	;;; The stored internal value. Default value may be given
	slot rc_informant_default == false;

	;;; default for pop_pr_places when the value is printed
	slot rc_informant_places = rc_informant_places_def;

	;;; Inherit methods, etc. from the mixin rc_informant.
	;;; see LIB rc_informant
	slot rc_informant_reactor == "rc_pointer_reactor";

	slot rc_pointer_convert_in = rc_pointer_convert_in_def ;
	slot rc_pointer_convert_out = rc_pointer_convert_out_def ;
	slot rc_redrawing = false;
enddefine;

/*

define -- methods for the class

*/

define :method print_instance(pic:rc_constrained_pointer);
	dlocal pop_pr_places;

	lvars places = rc_informant_places(pic);

	if isinteger(places) and places /== 0 then
		;;; pad with 0 if necessary
		`0` << 16 || places -> pop_pr_places
	endif;

    printf('<Dial at (%p, %p) ang %p val %p>',
		[%rc_coords(pic), rc_axis(pic)+0.0, rc_informant_value(pic) %])
enddefine;


define :method rc_pointer_mouse_limit(x, y, picx, picy, pic:rc_constrained_pointer) -> boole;
	;;; mouse pointer is at location x, y, and the picture is at picx picy
	;;; is x,y in the sensitive region?

	lvars
		(x1, y1) = rc_real_pivot_coords(pic),
		len = rc_pivot_length(pic),
		dist = rc_distance(x, y, x1, y1);

	if dist > len then
		false -> boole
	elseif dist + dist < rc_pointer_width(pic) then
		true -> boole
	else
		lvars
			ang = rc_ang_to_point(pic, x, y) mod 360,
			orient = 180 - rc_rotater_orient(pic),
			maxdiff = rc_maxdiff(pic),
			angmin = rc_min_ang(pic);

		orient - angmin -> angmin;

		lvars angdiff = (angmin - ang) mod 360;

		angdiff < maxdiff -> boole;

	endif

enddefine;

/*

define -- drawing procedures

*/

lvars
	in_rc_draw_linepic = false,
	in_rc_set_axis = false;

define rc_draw_pivot_blob(pic, bg);
	;;; if angdiff less than 180 draw a blob at centre of pivot
	lvars angdiff = rc_maxdiff(pic);

	if angdiff < 180 then
		lvars
			(x, y) =
					if rc_redrawing(pic) then
						rc_real_pivot_coords(pic)
					else
						rc_pivot_coords(pic)
					endif,
			width = rc_pointer_base(pic),
		;

		;;; Veddebug(['Drawing pivot blob' ^bg at ^x ^y in ^rc_xorigin ^rc_yorigin]);
		rc_draw_blob(x,y, width*0.5, bg);
		;;; Veddebug('Blob Drawn');
	endif;
enddefine;


define lconstant decoration_parameters(pic) -> (x, y, len, startorient, endorient);

    ;;; first find the centre of rotation of the pointer
	if in_rc_draw_linepic then
		;;; get relative coordinates, since drawing in the frame of
		;;; the picture object
		rc_pivot_coords(pic)
	else
		rc_real_pivot_coords(pic)
		;;; invoked directly
	endif -> (x,y);

    ;;; and its length
    rc_pivot_length(pic) -> len;

	(180 - rc_rotater_orient(pic)) mod 360 -> startorient;
	;;; rc_rotater_orient(pic) -> startorient;

    startorient - rc_maxdiff(pic) -> endorient;

	if rc_dial_counter_clockwise and rc_yscale > 0 then
		(startorient,endorient) -> (endorient,startorient)
	endif;
	
enddefine;

define :method rc_draw_dial_marks(pic:rc_constrained_pointer, marks);
	lvars
		(x, y, len, startorient, endorient) = decoration_parameters(pic),
		spec;
	for spec in marks do
		lvars
			(lengthinc, anglegap, tickwidth, ticklength, colour) = explode(spec);

		if rc_dial_counter_clockwise and rc_yscale > 0 then
			-anglegap -> anglegap
		endif;

		rc_draw_arc_segments(x, y, len+lengthinc,
			startorient, -anglegap, endorient, tickwidth, ticklength, colour);
	endfor;

enddefine;

define :method rc_draw_dial_labels(pic:rc_constrained_pointer, labels);
	lvars
		(x, y, len, startorient, endorient) = decoration_parameters(pic),
		spec;
	for spec in labels do

		lvars
			(lengthinc, anglegap, startnum, inc, colour, font) = explode(spec);

		if rc_dial_counter_clockwise and rc_yscale > 0 then
			-anglegap -> anglegap
		endif;

		rc_label_dial(x,y, len+lengthinc,
			startorient, -anglegap, endorient, startnum, inc, colour, font);
	endfor;
enddefine;

define :method rc_print_dial_captions(pic:rc_constrained_pointer, captions);
	lvars
		(x, y) =
			if in_rc_draw_linepic then
				rc_pivot_coords(pic)
			else
				rc_real_pivot_coords(pic)
			endif,
		spec ;

	for spec in captions do
		lvars
			(dx, dy, string, colour, font) = explode(spec);

		rc_print_a_string(x+dx, y+dy, string, colour, font)
	endfor;

enddefine;


define :method rc_draw_dial_decorations(pointer:rc_constrained_pointer);

	lvars
		marks = rc_pointer_marks(pointer),
		labels = rc_pointer_labels(pointer),
		captions = rc_pointer_captions(pointer);
	dlocal rc_frame_angle = 0;
	;;; dlocal 2 %rc_coords(pointer)%;
	;;; 0,0 -> rc_coords(pointer);
	if marks /== [] then rc_draw_dial_marks(pointer, marks) endif;
	if labels /==[] then rc_draw_dial_labels(pointer, labels) endif;
	if captions /==[] then rc_print_dial_captions(pointer, captions) endif;

enddefine;

define :method rc_undraw_dial_marks(pic:rc_constrained_pointer, marks);
	lvars
		(x, y, len, startorient, endorient) = decoration_parameters(pic),
		spec;
	for spec in marks do
		lvars
			(lengthinc, anglegap, tickwidth, ticklength, _) = explode(spec);

		if rc_dial_counter_clockwise and rc_yscale > 0 then
			-anglegap -> anglegap
		endif;

		rc_draw_arc_segments(x, y, len+lengthinc,
			startorient, -anglegap, endorient, tickwidth, ticklength, "background");
	endfor;

enddefine;

define :method rc_undraw_dial_labels(pic:rc_constrained_pointer, labels);
	lvars
		(x, y, len, startorient, endorient) = decoration_parameters(pic),
		spec;
	for spec in labels do

		lvars
			(lengthinc, anglegap, startnum, inc, _, font) = explode(spec);

		if rc_dial_counter_clockwise and rc_yscale > 0 then
			-anglegap -> anglegap
		endif;

		rc_label_dial(x,y, len+lengthinc,
			startorient, -anglegap, endorient, startnum, inc, "background", font);
	endfor;
enddefine;

define :method rc_undraw_dial_captions(pic:rc_constrained_pointer, captions);
	lvars
		(x, y) =
			if in_rc_draw_linepic then
				rc_pivot_coords(pic)
			else
				rc_real_pivot_coords(pic)
			endif,
		spec ;

	for spec in captions do
		lvars
			(dx, dy, string, _, font) = explode(spec);

		rc_print_a_string(x+dx, y+dy, string, "background", font)
	endfor;

enddefine;



define :method rc_draw_pointer_frame(pic:rc_constrained_pointer);
	;;; may be used to draw a more sophisticated frame
enddefine;

define :method rc_draw_constrained_pointer(pic:rc_constrained_pointer);
	;;;; The name of this method is the default value of rc_pic_lines
	;;;; This is called by rc_draw_linepic.

	lvars
		orient = rc_rotater_orient(pic),
		len = rc_pivot_length(pic),
		angmin = rc_min_ang(pic),
		angmax = rc_max_ang(pic),
		bg = rc_opaque_bg(pic),
		width = rc_pointer_width(pic),
		baseoffset = rc_pointer_base_offset(pic),
		px = 0, py = 0,	;;; possible pivot points, default 0,0
		;

	;;; Veddebug([%orient, angmin, angmax%]);
	unless rc_pointer_initialised(pic) then
		lvars
			draw_arc = rc_rotater_draw_arc(pic),
			arc_start = rc_rotater_start_ang(pic),
			mid_ang = arc_start + draw_arc*0.5;

		if bg then
			;;; do the initialisation, including drawing background.
			;;; expand background by pointer width at each end, if necessary

			;;; Draw a blob in background colour near where the pointer pivots
			;;; Veddebug([pivot drawing bg ^bg]);
			rc_draw_pivot_blob(pic, bg);
			;;; Veddebug([pivot drawn]);

			;;; Draw pointer in min and max positions with background colour
			;;; Veddebug('Drawing extreme1');
			rc_draw_pointer(0, 0, len, 180 - orient - angmax, width, bg);

			;;; Veddebug('Drawing extreme2');
			rc_draw_pointer(0, 0, len, 180 - orient - angmin, width, bg);

			;;; Draw the background (a circular sector)
			;;; rc_draw_blob_sector(xcentre, ycentre, radius, orientation, incang, colour);
			;;; Veddebug('Drawing blob sector');
			rc_draw_blob_sector(0, 0, len, arc_start, draw_arc, bg);
			;;; Veddebug('Drawn blob sector');
			
			;;; for debugging
			;;; rc_draw_blob(0, baseoffset, 5,'black');
			;;; rc_draw_blob(0, 0, 5,'red');
				;;;		dlocal rc_frame_angle = rc_frame_angle + rc_axis(pic);

			if baseoffset /== 0 then
				;;; draw a bar expanding the semi circle along its diameter
				;;; Veddebug(['drawing rectangle' angle ^rc_frame_angle]);
				lvars halfwidth = baseoffset*0.5;
				;;; rc_draw_rotated_rect(halfwidth*cos(mid_ang), halfwidth*sin(mid_ang), arc_start, len*2, width, bg);
				;;;rc_draw_rotated_rect(0, halfwidth, arc_start, len*2, baseoffset, bg);
				if rc_redrawing(pic) then
					;;; Veddebug([offset ^baseoffset bg ^bg scales ^rc_xscale ^rc_yscale]);
					procedure();
						dlocal
							rc_frame_angle =  mid_ang + 90,
							rc_linefunction = GXcopy;
						rc_drawline_relative(-len, halfwidth, len, halfwidth, bg, baseoffset+2);
					endprocedure();
				else
					;;; Veddebug('drawing base');
					rc_drawline_relative(-len, halfwidth, len, halfwidth, bg, baseoffset+2);
				endif;
			
				;;; Veddebug(['drawn rectangle']);
			endif;
		endif;	

		;;; Call user definable frame drawer
		rc_draw_pointer_frame(pic);

		true -> rc_pointer_initialised(pic);

		unless rc_redrawing(pic) then

			;;; now set the informant contents, and constrain the angle
			;;; get the virtual angle
			lvars vang = rc_virtual_axis(pic);

			;;; now work out actual angle
			(180 - orient - vang) mod 360 -> rc_axis(pic);

			;;; set the stored informant "value"
			recursive_valof(rc_pointer_convert_in(pic))(vang) -> rc_informant_value(pic);

		endunless
		;;;; Don't do rc_information_changed(pic); Here. Not ready yet

	endunless;

	lvars axis = rc_axis(pic);

	;;; now finally draw the pointer itself
	;;; Veddebug('drawing pointer');
	rc_draw_pointer( px, py, len, axis, width, rc_pointer_colour(pic));
	;;;Veddebug('drawn pointer');

	px+len*cos(axis) -> rc_end_x(pic);
	py+len*sin(axis) -> rc_end_y(pic);

	;;; [draw ends %rc_pivot_coords(pic), rc_end_coords(pic), "ang", rc_axis(pic)%] =>
enddefine;

global vars procedure rc_install_pointer; ;;; defined below

define :method rc_draw_linepic(pic:rc_constrained_pointer);
	;;; Veddebug([ang ^rc_frame_angle]);
	dlocal in_rc_draw_linepic;
	returnif(in_rc_draw_linepic);
	true -> in_rc_draw_linepic;
	unless rc_pointer_initialised(pic) then
		rc_setup_rotater(pic);
		unless iscaller(rc_install_pointer) then
			false -> in_rc_draw_linepic;
			rc_install_pointer(pic, rc_current_window_object);
			return();
		endunless;
	endunless;
	call_next_method(pic);
enddefine;




define :method rc_undraw_dial(pic:rc_constrained_pointer);
	;;; This is still too complex. Also there's a failure
	;;; if the dial is drawn in a region of a panel or picture
	;;; where the background is not the same as the default
	;;; panel background.
	;;; This is handled specially in rc_redraw_panel

	false -> rc_pointer_initialised(pic);
	lvars
		orient = rc_rotater_orient(pic),
		len = rc_pivot_length(pic),
		angmin=rc_min_ang(pic),
		angmax=rc_max_ang(pic),
		baseoffset = rc_pointer_base_offset(pic),
		halfwidth = baseoffset*0.5,
		yoffset = (baseoffset*0.5)*sign(rc_yscale),
		(x,y) = rc_real_pivot_coords(pic),
		draw_arc = rc_rotater_draw_arc(pic),
		arc_start = rc_rotater_start_ang(pic),
		mid_ang = arc_start + draw_arc*0.5,
		axis = mid_ang - 90,
	;

	rc_draw_blob_sector(x, y, len, arc_start, draw_arc, "background");
	;;; draw a rectangle for the offset, allowing for orientation of axis

	if baseoffset == 0 then
		procedure();
			dlocal %rc_redrawing(pic)% = true;
			lvars
				pointer_width = rc_pointer_width(pic),
				bg = "background";

			rc_draw_pivot_blob(pic, bg);
			;;; Veddebug([pivot drawn]);

			;;; Draw pointer in min and max positions with background colour
			;;; Veddebug(['Drawing extreme1' ^len ^pointer_width]);
			rc_draw_pointer(x, y, len, 180 - orient - angmax, pointer_width, bg);

			;;; Veddebug('Drawing extreme2');
			rc_draw_pointer(x, y, len, 180 - orient - angmin, pointer_width, bg);
		endprocedure();
	else
		lvars
			width = rc_pointer_base_offset(pic),
			xinc = -rc_pointer_xinc(pic)*0.5*rc_xscale,
			yinc = rc_pointer_yinc(pic)*0.5*rc_yscale;

		;;; Veddebug([xinc ^xinc yinc ^yinc]);
		;;; Veddebug(['drawing rectangle' angle ^arc_start]);
		rc_draw_rotated_rect(x+xinc,y+yinc, arc_start, 2*len, width+3, "background");
		;;; rc_draw_rotated_rect(x+xinc,y+yinc, arc_start, 2*len, width+2, 'red');
		;;; Veddebug(['drawn rectangle' angle ^arc_start]);
	endif;
	
	lvars
		marks = rc_pointer_marks(pic),
		labels = rc_pointer_labels(pic),
		captions = rc_pointer_captions(pic);

	procedure ();
		dlocal rc_frame_angle = 0;
		if marks then rc_undraw_dial_marks(pic, marks) endif;
		if labels then rc_undraw_dial_labels(pic, labels) endif;
		if captions then rc_undraw_dial_captions(pic, captions) endif;
	endprocedure();
	;;; axis -> rc_axis(pic);
enddefine;

define :method rc_redraw_linepic(pic:rc_constrained_pointer);
	procedure();
		dlocal %rc_redrawing(pic)% = true;
		rc_undraw_dial(pic);
		if rc_pointer_base_offset(pic) == 0 then
			;;; for redrawing non-semi-circular dials
			false -> rc_redrawing(pic);
		endif;
		rc_draw_linepic(pic);
		rc_draw_dial_decorations(pic);
	endprocedure();
enddefine;



/*

define -- Mechanisms for handling, converting and changing pointer values

*/

;;; two utilities for handling value ranges

define lconstant pointer_value_from_ang(vang, pic) -> val;
	;;; vang is the virtual angle.
	lvars
		angmaxdiff = rc_maxdiff(pic),
		start = rc_informant_start(pic),
		end = rc_informant_end(pic);

	if rc_dial_counter_clockwise and rc_yscale > 0 then
		;;; switch order
		start,end -> (end,start)
	endif;

	if angmaxdiff == 0 then 360 -> angmaxdiff endif;
	(vang/angmaxdiff)*(end - start) + start -> val;
	;;;; XXXXX fix steps?
enddefine;

define lconstant pointer_ang_from_value(val, pic) -> vang;
	lvars
		angmaxdiff = rc_maxdiff(pic),
		angmin = rc_min_ang(pic),
		start = rc_informant_start(pic),
		end = rc_informant_end(pic);

	if rc_dial_counter_clockwise and rc_yscale > 0 then
		;;; switch order
		start,end -> (end,start)
	endif;

	if angmaxdiff == 0 then 360 -> angmaxdiff endif;
	((val - start)/(end - start))*angmaxdiff + angmin -> vang;
enddefine;


define lconstant adjust_step_value(pic, val) -> val;
	;;; Given a value, find the nearest stepped point
	lvars
		rangestart = rc_informant_start(pic),
		rangeend = rc_informant_end(pic),
		stepval = rc_informant_step(pic);

	if stepval then
		dlocal popdprecision = true;
		round((val - rangestart)/stepval) * stepval + rangestart -> val;
	endif;
enddefine;

define :method rc_set_axis(pic:rc_constrained_pointer, ang, mode);

	returnif(in_rc_set_axis);
	dlocal in_rc_set_axis = true;

	recursive_valof(rc_constraint(pic))(pic, ang) -> ang;

	lvars
		oldaxis = rc_axis(pic),
		oldval = rc_informant_value(pic);
	returnif(ang == oldaxis);

	;;; this calls rc_set_axis for constrained rotater. Will operate constraints
	;;; call_next_method(pic, ang, mode);

	;;; compute virtual angle from constrained angle before computing contents
	lvars
		;;; and see if the new one would be different, after adjusting
		vang = rc_actual_to_virtual_angle(pic, ang);

	;;; compute new informant value derived from vang
	lvars val = recursive_valof(rc_pointer_convert_in(pic))(vang);

	;;; Now see if it has to be adjusted because of steps in the value range
	lvars newval =
		if rc_informant_step(pic) then adjust_step_value(pic, val); else val endif;

	;;; Maybe there's no change, e.g. if the step is too small
	unless newval = oldval then

		;;; otherwise update stored value and picture
		newval -> rc_informant_value(pic);

		;;; make reactors run
		rc_information_changed(pic);

		;;; now check whether the step adjustment requires a change to the
		;;; pointer appearance
		lvars newang = rc_pointer_convert_out(pic)(newval);

		;;; and draw the chang if required;
		if newang /== rc_virtual_axis(pic) then

			;;; false -> in_rc_set_axis ;
			call_next_method(pic, (180 - rc_rotater_orient(pic) - newang), true);
			
		endif;
	endunless;
	
enddefine;

define :method rc_pointer_value(pic:rc_constrained_pointer) -> val;
	;;; Ignore current location, just return stored value, making sure
	;;; elsewhere that it has been properly set up.
	rc_informant_value(pic) -> val;
enddefine;

global vars in_rc_pointer_update = false;

define :method updaterof rc_pointer_value(newval, pic:rc_constrained_pointer);

	;;; Transform newval to angle, then check constraints.
	returnif(in_rc_pointer_update);	;;;MAKE IT TRUE BELOW

	dlocal in_rc_pointer_update;

	lvars
		old_win = rc_current_window_object,
		informant_win = rc_informant_window(pic),
		oldval = rc_informant_value(pic);

	returnif(newval == oldval);

	if informant_win and informant_win /== old_win then
		;;; make sure drawing happens in right window
		informant_win -> rc_current_window_object
	endif;

	lvars
		;;; do the conversion to virtual angle
		vang = recursive_valof(rc_pointer_convert_out(pic))(newval),
		angmin = rc_min_ang(pic),
		angmax = rc_max_ang(pic),
		;

	;;; [vang ^vang] =>	

	if vang < angmin then angmin  -> vang
	elseif vang > angmax  then angmax -> vang endif;
	
	;;; now get the actual angle from the virtual angle
	lvars ang = (180 - rc_rotater_orient(pic) - vang);

	;;; rc_set_axis will operate constraints on angle
	true -> in_rc_pointer_update;
	rc_set_axis(pic, ang, true);

	if old_win /== rc_current_window_object then
		old_win -> rc_current_window_object;
	endif;

enddefine;


/*
;;; doesn't work ???
define :method updaterof rc_informant_value(val, pic:rc_constrained_pointer);
	if in_rc_pointer_update then
		call_next_method(val, pic);
	else
		val -> rc_pointer_value(pic);
	endif;
enddefine;
  */

define :method rc_pointer_reactor(s:rc_constrained_pointer, val);
	;;; default value of rc_informant_reactor. User definable
enddefine;

/*

define -- Dial and pointer spec abbreviations

*/

;;; User extendable property for abbreviations in dial/pointer specs
global constant procedure rc_dial_spectrans =
	newproperty(
	  [
		[length rc_pivot_length]
		[pointerwidth rc_pivot_width]
		[constraint rc_constraint]
		[orient rc_rotater_orient]
		[pointercol rc_pointer_colour]
		[dialbg rc_pointer_bg]
		[constrain ^rc_constrain_contents]
		[ident ^rc_informant_ident]
		[reactor ^rc_informant_reactor]],
		11, false, "perm");

define expand_dial_spec_abbreviations(spec) -> spec;
	;;; Translate some shorthand specs

	;;; But not if the spec is false
	returnunless(spec);

	lvars item, n;
	if isvector(spec) then
		fast_for n from 1 by 2 to datalength(spec) do
			
			rc_dial_spectrans(subscrv(n, spec)) -> item;
			if item then item -> subscrv(n, spec) endif
		endfor;
	elseif islist(spec) then
		;;; It should be a list. Recursively translate
		for item in spec do
			expand_dial_spec_abbreviations(item) ->;
		endfor;
	else
		mishap('Spec should be vector or list', [^spec]);
	endif
enddefine;



/*

define -- Recognisers for optional arguments

*/

define iswident(w);
	isword(w) or isident(w);
enddefine;

define isspecvector(v);
	isvector(v) and not(isnumber(fast_subscrv(1, v)))
enddefine;

define isrctypespec(item);
	iskey(item)
enddefine;

define lconstant Istypespec(list, word);
	islist(list) and listlength(list) > 1 and front(list) == word
enddefine;

define ismarkspec(item);
	Istypespec(item, "MARKS")
enddefine;

define islabelspec(item);
	Istypespec(item, "LABELS")
enddefine;

define iscaptionspec(item);
	Istypespec(item, "CAPTIONS")
enddefine;


/*

define -- creation of dials

*/

define rc_install_dial_features(range, marks, labels, captions, pointer);
	lvars
		rangemin = 0, rangemax = false, rangestep = false, defaultval = 0;
	
	if isnumber(range) then
		range -> rangemax
	elseif isvector(range) then
		lvars rangelen = datalength(range);
		subscrv(1, range) -> rangemax;

		if rangelen > 1 then
			rangemax ->> rangemin -> defaultval;
			subscrv(2, range) -> rangemax;
		endif;
		if rangelen > 2 then
			subscrv(3, range) -> defaultval;
		endif;
		if rangelen == 4 then
			subscrv(4, range) -> rangestep
		endif;
	else
		mishap('DIAL RANGE SHOULD BE A NUMBER OR VECTOR',
					[%range%])
	endif;

	rangemax -> rc_informant_end(pointer);
	rangemin -> rc_informant_start(pointer);
	rangestep -> rc_informant_step(pointer);
	defaultval -> rc_informant_default(pointer);

	;;; [start ^rangemin default ^defaultval end ^rangemax]=>

	if isinteger(rangestep) and isinteger(rangemin) then
		;;; might as well print without decimal places
		0 -> rc_informant_places(pointer)
	endif;

	;;; set up converters
	pointer_value_from_ang(%pointer%) -> rc_pointer_convert_in(pointer);
	pointer_ang_from_value(%pointer%) -> rc_pointer_convert_out(pointer);

	if marks then tl(marks) -> rc_pointer_marks(pointer) endif;
	if labels then tl(labels) -> rc_pointer_labels(pointer) endif;
	if captions then tl(captions) -> rc_pointer_captions(pointer) endif;


enddefine;

define rc_constrained_pointer_init(x, y, orient, minang, maxang, len, width, colour, bg) -> pointer;
	;;; Create a new instance, and set up some of its slits

	lvars
		wid = false, specs = false, type = rc_constrained_pointer_key;

	ARGS
		x, y, orient, minang, maxang, len, width, colour, bg,
			&OPTIONAL
				wid:iswident, specs:isspecvector, type:isrctypespec;

	dlocal popradians = false;

	lvars
		;;; adjust x, y location to fit previous specification
		pivotdir = orient - 90,
		xinc = cos(pivotdir)*width*sign(rc_xscale)*rc_width_offset_ratio,
		yinc = sin(pivotdir)*width*sign(rc_yscale)*rc_width_offset_ratio,
		;

	;;; create instance
	if type then class_new(type) -> type endif;
	type() -> pointer;

	if width > len then
		mishap('POINTER WIDTH EXCEEDS LENGTH', [^width ^len (^x ^y)])
	endif;

	width -> rc_pointer_base(pointer);

	;;; insert defaults provided

	x + xinc -> rc_picx(pointer);
	y - yinc -> rc_picy(pointer);
	xinc -> rc_pointer_xinc(pointer);
	yinc -> rc_pointer_yinc(pointer);
	orient -> rc_rotater_orient(pointer);
	len -> rc_pivot_length(pointer);
	minang -> rc_min_ang(pointer);
	maxang -> rc_max_ang(pointer);
	180 - orient - minang -> rc_axis(pointer);

	;;; compute the angular width of the pointer given the desired width at its
	;;; base. Ignore scale for now. Assume the pointer angle is small, so that
	;;; this is approximate: 2*len*sin(ang/2) = width. so
	;;; ang = 2*arcsin(width/(2.0*len)

	lvars
		angwidth = 2*arcsin(width/(2.0*len)),
		angdiff = round(maxang - minang),
		baseoffset
		;

	angwidth -> rc_pointer_width(pointer);

	if angdiff > 360 then
		mishap('MIN and MAX angles differ by more than 360',
			[^minang ^maxang]);

	elseif abs(angdiff) /== 180 then
		;;; remove the pivot offset. It is needed only for sem-circular dials
		;;; since otherwise they will not look good
		0 ->> baseoffset -> rc_pointer_base_offset(pointer);
	else
		;;; round up half the width to compute offset
		round((width+0.5)*rc_width_offset_ratio) ->> baseoffset -> rc_pointer_base_offset(pointer);
		;;;; Veddebug([width ^width baseoffset ^baseoffset]);
	endif;

	if specs then
		interpret_specs(pointer, expand_dial_spec_abbreviations(specs))
	endif;

	if wid then wid -> rc_informant_ident(pointer) endif;

	;;; see if default colours are to be overridden.
	if bg then
		bg ->> rc_pointer_bg(pointer) -> rc_opaque_bg(pointer);
	endif;
	if colour then colour -> rc_pointer_colour(pointer) endif;

 	;;; set up derived information
    rc_setup_rotater(pointer);

	lvars
		draw_arc =
			if (maxang - minang) mod 360 = 0 then
				360
			else
				(maxang - minang) mod 360
			endif,
		arc_start = (180 - orient - minang - draw_arc) mod 360;

	draw_arc -> rc_rotater_draw_arc(pointer);
	arc_start -> rc_rotater_start_ang(pointer);

	;;; find pivot coords, by finding the middle of the background angle,
	;;; the following will assign (0,0) if offset == 0
	(0,0) -> rc_pivot_coords(pointer);

enddefine;

define rc_install_pointer(pointer, win);
	;;; Pointer has been created. Now draw it and add it to the manipulable
	;;; objects in win.

	dlocal rc_current_window_object = win;

	rc_add_pic_to_window(pointer, win, true);

	win -> rc_informant_window(pointer);
	;;; this will invoke rc_pic_lines(pointer), i.e. rc_draw_constrained_pointer
	rc_draw_linepic(pointer);

	lvars defaultval = rc_informant_default(pointer);

	unless not(defaultval) or in_rc_draw_linepic or defaultval == rc_pointer_value(pointer) then
		unless rc_redrawing(pointer) then
			;;; set the default value
			;;; Veddebug('Setting default');
			defaultval -> rc_pointer_value(pointer)
		endunless;
	endunless;

	rc_draw_dial_decorations(pointer);

enddefine;


define rc_constrained_pointer(x, y, orient, minang, maxang, len, width, colour, bg) -> pointer;

	rc_check_window(rc_current_window_object);

	rc_constrained_pointer_init(x, y, orient, minang, maxang, len, width, colour, bg) -> pointer;

	;;; now install it in window and draw it
	rc_install_pointer(pointer, rc_current_window_object);

enddefine;

define create_rc_pointer_dial(
		x, y, orient, minang, maxang, len, width, colour, bg,
			range, marks, labels, captions,
				wid, specs, typespec) -> pointer;


	lvars win = rc_current_window_object;
	rc_check_window(win);

	rc_constrained_pointer_init(
		x, y, orient, minang, maxang, len, width, colour, bg,
			if wid then wid endif,
			if specs then specs endif,
			if typespec then typespec endif) -> pointer;

	rc_install_dial_features(range, marks, labels, captions, pointer);

	;;; now install it in window and draw it
	rc_install_pointer(pointer, win);

enddefine;

endsection;

/*

CONTENTS

 define -- Load required libraries and set defaults for globals
 define :rc_defaults;
 define :generic rc_pointer_mouse_limit(x, y, picx, picy, pic);
 define -- The class rc_constrained_pointer
 define :class vars rc_constrained_pointer;
 define -- methods for the class
 define :method print_instance(pic:rc_constrained_pointer);
 define :method rc_pointer_mouse_limit(x, y, picx, picy, pic:rc_constrained_pointer) -> boole;
 define -- drawing procedures
 define rc_draw_pivot_blob(pic, bg);
 define lconstant decoration_parameters(pic) -> (x, y, len, startorient, endorient);
 define :method rc_draw_dial_marks(pic:rc_constrained_pointer, marks);
 define :method rc_draw_dial_labels(pic:rc_constrained_pointer, labels);
 define :method rc_print_dial_captions(pic:rc_constrained_pointer, captions);
 define :method rc_draw_dial_decorations(pointer:rc_constrained_pointer);
 define :method rc_undraw_dial_marks(pic:rc_constrained_pointer, marks);
 define :method rc_undraw_dial_labels(pic:rc_constrained_pointer, labels);
 define :method rc_undraw_dial_captions(pic:rc_constrained_pointer, captions);
 define :method rc_draw_pointer_frame(pic:rc_constrained_pointer);
 define :method rc_draw_constrained_pointer(pic:rc_constrained_pointer);
 define :method rc_draw_linepic(pic:rc_constrained_pointer);
 define :method rc_undraw_dial(pic:rc_constrained_pointer);
 define :method rc_redraw_linepic(pic:rc_constrained_pointer);
 define -- Mechanisms for handling, converting and changing pointer values
 define lconstant pointer_value_from_ang(vang, pic) -> val;
 define lconstant pointer_ang_from_value(val, pic) -> vang;
 define lconstant adjust_step_value(pic, val) -> val;
 define :method rc_set_axis(pic:rc_constrained_pointer, ang, mode);
 define :method rc_pointer_value(pic:rc_constrained_pointer) -> val;
 define :method updaterof rc_pointer_value(newval, pic:rc_constrained_pointer);
 define :method updaterof rc_informant_value(val, pic:rc_constrained_pointer);
 define :method rc_pointer_reactor(s:rc_constrained_pointer, val);
 define -- Dial and pointer spec abbreviations
 define expand_dial_spec_abbreviations(spec) -> spec;
 define -- Recognisers for optional arguments
 define iswident(w);
 define isspecvector(v);
 define isrctypespec(item);
 define lconstant Istypespec(list, word);
 define ismarkspec(item);
 define islabelspec(item);
 define iscaptionspec(item);
 define -- creation of dials
 define rc_install_dial_features(range, marks, labels, captions, pointer);
 define rc_constrained_pointer_init(x, y, orient, minang, maxang, len, width, colour, bg) -> pointer;
 define rc_install_pointer(pointer, win);
 define rc_constrained_pointer(x, y, orient, minang, maxang, len, width, colour, bg) -> pointer;
 define create_rc_pointer_dial(

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug 27 2002
	made updaterof rc_informant_value work??
--- Aaron Sloman, Aug 25 2002
	replaced rc_informant_contents with rc_informant_value
--- Aaron Sloman, Aug 20 2002
		Changed to print as <Dial...>, not <pointer...>
--- Aaron Sloman, Aug 13 2002
		Changed printing of dials to show angle and value
--- Aaron Sloman, Aug  6 2002
		Changed compile mode
--- Aaron Sloman, Jul 28 2002
		redefined the :class as vars
--- Aaron Sloman, Mar 17 2001
		Corrected code for dials not a semi-circle
		Removed some old redundant code. Still some tidying up to do.
--- Aaron Sloman, Mar 13 2001
		Fix bug due to uninitialised variables, only showing up on Alphas!
--- Aaron Sloman, Mar 13 2001
	Inserted test for false default value
--- Aaron Sloman, Mar 11 2001
		Introduced rc_draw_rotated_rect
--- Aaron Sloman, Mar 11 2001
	Many changes to clean up and make this more maintainable and more
	usable.
--- Aaron Sloman, Mar  9 2001
	Changed to call rc_information_changed when contents updated.
--- Aaron Sloman, Aug 30 2000
	Added  updaterof rc_informant_value(val, pic:rc_constrained_pointer);
--- Aaron Sloman, Aug 29 2000
	Moved main procedure out to LIB rc_*dial and renamed it.
	Improved rc_pointer_mouse_limit, removed in_rectangle
	Extended with automatic formatting of decorations for dials, etc.
--- Aaron Sloman, Aug 26 2000
	Introduced rc_virtual_axis in lib rc_constrained_rotater, and fixed
	the angle constraints, finally
--- Aaron Sloman, Aug 25 2000
	Fixed several bugs to do with odd orientations.
--- Aaron Sloman, Aug 22 2000
	Improved algorithm for detecting mouse on pointer.
--- Aaron Sloman, Jun 28 2000
	removed rc_pointer_*container. rc_informant_window suffices

	split rc_constrained_pointer into rc_constrained_pointer_init and
	rc_install_pointer
	
 */
