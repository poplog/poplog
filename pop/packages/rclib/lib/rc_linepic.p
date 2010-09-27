/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_linepic.p
 > Linked to:       $poplocal/local/lib/rc_linepic.p
 > Purpose:			Creation of fast_drawn objects made of lines
 > Author:          Aaron Sloman,  31 Mar 1996 (see revisions)
 > Documentation:	HELP * RC_LINEPIC
 > Related Files:	LIB * RC_MOUSEPIC
 */
/*
CONTENTS now at end.

For full information see TEACH * RC_LINEPIC, HELP * RC_LINEPIC
LIB * RC_MOUSEPIC adds mouse-based interaction.

Methods for temporarily drawing on a different pane could be constructed.

See rc_context in HELP * RC_GRAPHIC

*/
section;

compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;


uses objectclass
uses create_instance	;;; to avoid identifier clash if loaded later
uses rc_graphic
uses rclib
uses rc_black_white_inverted
uses rc_setup_linefunction.p
;;; uses rc_rotate_xy
uses rc_font
uses rc_foreground
uses rc_line_width
uses rc_line_style
uses rc_draw_circle
uses int_parameters


/*
define -- The main mixins
*/

;;; These are the slot accessor procedures defined below.
global vars procedure
	(rc_picx, rc_picy, rc_oldx, rc_oldy, rc_pic_lines, rc_pic_strings,
	rc_coords);


define :mixin vars rc_linepic;
	;;; coordinates of point relative to which to draw
	slot rc_picx == 0;
	slot rc_picy == 0;
	;;; A procedure or a list of line-pictures to draw.
	slot rc_pic_lines == [];
	;;; A procedure or list of strings to draw.
	slot rc_pic_strings == [];
enddefine;


define :mixin vars rc_linepic_movable; is rc_linepic;
	;;; Extend the class to include a record of previous location.
	slot rc_oldx == false;
	slot rc_oldy == false;
enddefine;

define :mixin vars rc_rotatable; is rc_linepic_movable;
	slot rc_axis == 0;
	slot rc_oldaxis == false;
enddefine;

define :mixin vars rc_rotatable_picsonly; is rc_rotatable;
	;;; rotation methods defined so that strings are not rotated
enddefine;


;;; define a dummy class to overcome a recogniser bug in V15.5
;;; This may be needed in V15.5 systems without the fixed version of
;;; $usepop/pop/lib/objectclass/src/class_isa.p
;;; With fix dated Jan 15 1997
define :class dummy;  is rc_rotatable;
enddefine;


/*
define -- Pausing utility (probably useless, except for debugging?)
*/

;;; Make this true to cause all drawing to pause until a key is
;;; pressed. If it is a string, the string is printed out when pausing.
global
	vars rc_pause_draw;

if isundef(rc_pause_draw) then
	false -> rc_pause_draw
endif;

define global vars rc_check_pausing();
	if rc_pause_draw then
		if isstring(rc_pause_draw) then
			vedputmessage(rc_pause_draw)
		endif;
		rawcharin() ->;
		if isstring(rc_pause_draw) then
			vedputmessage(nullstring)
		endif;
	endif
enddefine;


/*
define -- Procedures assignable to Gdrawprocedure

;;; See LIB rc_setup_linefunction

Depending on whether black and white are represented as 0 and 1 or
1 and 0 different behaviour is needed. The next two procedures
handle drawing under these conditions. The use of "xor" is for
Suns and the like. The use of "equiv" is for use by DEC alphas and
some PC X systems. These mechanisms are used by "movable" pictures,
to ensure that if the same thing is drawn twice over another picture
the original state will then be restored.

*/

define rc_xor_drawpic(pic, wasequiv, wastrailing, procedure proc);
	;;; This procedure is a possible value of Gdrawprocedure
	lvars already_drawn = rc_oldx(pic),
		(xloc, yloc) = rc_coords(pic);

	proc(pic, xloc, yloc);

	;;; make sure that the location last drawn is recorded
	;;; if necessary
	if already_drawn and not(wastrailing) then
		;;; the above will have erased the picture
		false -> rc_oldx(pic);
	else
		;;; record where drawn
		xloc -> rc_oldx(pic);
		yloc -> rc_oldy(pic);
		if isrc_rotatable(pic) then
			rc_axis(pic) -> rc_oldaxis(pic)
		endif;
	endif;
enddefine;

define rc_equiv_drawpic(pic, wasequiv, wastrailing, procedure proc);
	;;; This procedure is a possible value of Gdrawprocedure
	lvars already_drawn = rc_oldx(pic),
		(xloc, yloc) = rc_coords(pic),
		linefunction = rc_linefunction;

	dlocal rc_linefunction;

	if linefunction == GXequiv or wasequiv then
		;;; handle strange colour map, eg. on alphastation
			rc_set_planemask( rc_window, 254);
			if wastrailing then GXcopy else GXxor endif ->rc_linefunction;
			proc(pic, xloc, yloc);

			rc_set_planemask( rc_window, 1);
	endif;

	linefunction -> rc_linefunction;

	proc(pic, xloc, yloc);

	;;;;if linefunction = GXequiv or wasequiv then
	rc_set_planemask( rc_window, 255);
	;;;;endif;

	;;; make sure that the location last drawn is recorded
	;;; if necessary
	if already_drawn and not(wastrailing) then
		;;; the above will have erased it
		false -> rc_oldx(pic);
	else
		;;; record where drawn
		xloc -> rc_oldx(pic);
		yloc -> rc_oldy(pic);
		if isrc_rotatable(pic) then
			rc_axis(pic) -> rc_oldaxis(pic)
		endif;
	endif;
enddefine;

;;; Set up defaults. See LIB rc_setup_linefunction

if isundef(Glinefunction) then
	;;; default, for suns etc, can be overridden by rc_setup_linefunction()
	;;; The first default is set in lib rc_setup_linefunction
	;;; GXxor -> Glinefunction;
	rc_xor_drawpic -> Gdrawprocedure;
endif;


/*
define -- Utility procedures and methods
*/


define :method vars rc_coords(pic:rc_linepic);
	rc_picx(pic);
	rc_picy(pic);
enddefine;

define :method updaterof rc_coords(/*x, y,*/ pic:rc_linepic);
	-> (rc_picx(pic), rc_picy(pic))
enddefine;
	
define :method rc_undrawn(pic:rc_linepic);
	;;; Can't undraw default linepics, so do nothing.
enddefine;

define :method rc_undrawn(pic:rc_linepic_movable);
	;;; Make it look as if it has not been drawn
	false -> rc_oldx(pic)
enddefine;

define vars procedure rc_undraw_all(pics);
	applist(pics, rc_undrawn)
enddefine;

/*
define -- Utilities concerned with rotation.
Based on LIB RC_ROTATE_XY
*/

;;; Hidden from user. Angles represent counter-clockwise rotation.
lvars
	rc_actual_frame_angle = 0,
	rc_rotate_cos = 1.0,
	rc_rotate_sin = 0.0,
;

;;; This active variable is the interface to the above variables

define active rc_frame_angle();
	;;; This active variable is used to access the current frame angle
	rc_actual_frame_angle;
enddefine;

define updaterof active rc_frame_angle(angle);
	;;; Update rc_actual_frame_angle, and set the values of rc_rotate_cos and
	;;; rc_rotate_sin to correspond to a rotation of angle degrees.
	lvars angle;
	dlocal popradians = false;
	;;; normalise the angle
	while angle >= 360.0 do
		angle - 360.0 -> angle
	endwhile;
	while angle < 0 do
		angle + 360.0 -> angle
	endwhile;
	cos(angle) -> rc_rotate_cos;
	sin(angle) -> rc_rotate_sin;
	angle -> rc_actual_frame_angle;
enddefine;

define rc_rotate_coords(x, y) -> (x, y);
	;;; Takes two numbers (user co-ordinates) and returns two
	;;; new numbers, corresponding to rotation by rc_frame_angle
	;;; It uses rc_rotate_cos and rc_rotate_sin
	lvars x,y;

	;;; First rotate about user origin
	x * rc_rotate_cos - y * rc_rotate_sin,
		x * rc_rotate_sin + y * rc_rotate_cos
			-> y -> x;
	;;; Do the rest of the transformation
	if rc_xscale == 1 then x else x * rc_xscale endif + rc_xorigin -> x;
	if rc_yscale == -1 then y else -y * rc_yscale endif + rc_yorigin -> y;
enddefine;

define rc_rotate_coords_rounded(x, y) -> (x, y);
	;;; Similar, but rounds the output
	;;; reverse rc_yscale for desired effect (Why???)
	dlocal rc_yscale = -rc_yscale;
	rc_rotate_coords(x,y) .round -> y, .round -> x
enddefine;

/*
define -- picture bounds procedures

*/

;;; A procedure to compute the (relative coordinate) bounds within
;;; which lines will be drawn
define :method rc_linepic_bounds(pic:rc_linepic, absolute)
		-> (xmin, ymin, xmax, ymax);
	;;; Find the bounds required for drawing the lines.
	;;; If the second argument is true, absolute coordinates
	;;; should be returned, otherwise relative
	lvars
		pic, xmin, ymin, xmax, ymax,
		line_lists = rc_pic_lines(pic),
		points, point, dx, dy, key;

	returnunless( ispair(line_lists) );

	lconstant ignore = [STYLE WIDTH COLOUR XSCALE YSCALE];

	pop_max_int ->> xmin -> ymin;
	pop_min_int ->> xmax -> ymax;

	while lmember(front(line_lists), ignore) do
		back(back(line_lists)) -> line_lists
	endwhile;

	fast_for points in line_lists do
		while lmember(front(points) ->> key, ignore) do
			back(back(points)) -> points
		endwhile;

		if key == "CIRCLE" then
			fast_back(points) -> points;
			for point in points do
				lvars (x, y, rad) = explode(point);
				max((x + rad), xmax) -> xmax;
				max((y + rad), ymax) -> ymax;
				min((x - rad), xmin) -> xmin;
				min((y - rad), ymin) -> ymin;
			endfor;
		elseif lmember(key, #_<[SQUARE RSQUARE]>_#) then
			fast_back(points) -> points;
			for point in points do
				lvars (x, y, width) = explode(point);
				max((x + width), xmax) -> xmax;
				max(y, ymax) -> ymax;
				min(x, xmin) -> xmin;
				min((y - width), ymin) -> ymin;
			endfor;
		elseif lmember(key, #_<[RECT RRECT]>_#) then
			fast_back(points) -> points;
			for point in points do
				lvars (x, y, width, height) = explode(point);
				max((x + width), xmax) -> xmax;
				max(y, ymax) -> ymax;
				min(x, xmin) -> xmin;
				min((y - height), ymin) -> ymin;
			endfor;
		elseif key == "rc_draw_ob" then
			;;; see the definition of LIB * RC_DRAW_OB
			fast_back(points) -> points;
			for point in points do
				lvars x, y, width, height;
				;;; ignore the last two elements of the vector, and
				;;; treat it like a rectangle
				explode(point) -> (x, y, width, height, , );
				max((x + width), xmax) -> xmax;
				max(y, ymax) -> ymax;
				min(x, xmin) -> xmin;
				min((y - height), ymin) -> ymin;
			endfor;
		elseif isword(key) and key /== "CLOSED" then
			;;; can't interpret
		else
			if key == "CLOSED" then
				fast_back(points) -> points
			;;; otherwise assume it's an open polyline
			endif;
			fast_for point in points do
				explode(point) -> (dx, dy);
				max(dx,xmax) -> xmax;
				max(dy,ymax) -> ymax;
				min(dx,xmin) -> xmin;
				min(dy,ymin) -> ymin;
			endfor;
		endif
	endfor;

	if absolute then
		;;; having found the relative bounds, compute the absolute bounds.
		lvars (startx, starty) = rc_coords(pic);

		startx + xmax -> xmax;		
		startx + xmin -> xmin;		
		starty + ymax -> ymax;		
		starty + ymin -> ymin;
	endif
enddefine;


define :method rc_linepic_bounds (pic:rc_rotatable, absolute)
		-> (xmin, ymin, xmax, ymax);
    ;;; Get the relative coordinates, for a rotatable object.
	lvars ang = rc_axis(pic);
	if abs(ang - 0) < 0.0001 then
		;;; no rotation, just use normal result.
		call_next_method(pic, absolute) -> (xmin, ymin, xmax, ymax);
	else
		;;; get the relative non-rotated bounds
		call_next_method(pic, false) -> (xmin, ymin, xmax, ymax);

		;;; Rotate them about centre of picture object
		dlocal
			rc_frame_angle = ang,
			(rc_xorigin,rc_yorigin) =
				if absolute then rc_coords(pic) else 0,0 endif;

		;;; This is really a hack, and not reliable.
		rc_rotate_coords(xmin, ymin) -> (xmin, ymin);
		rc_rotate_coords(xmax, ymax) -> (xmax, ymax);
		min(xmin,xmax), max(xmin,xmax) -> (xmin, xmax);
		min(ymin,ymax), max(ymin,ymax) -> (ymin, ymax);
	endif;
enddefine;

/*
define -- Core procedures for drawing lines and strings

*/

;;; rc_active_picture_object is set in rc_mousepic
;;; keep a list of picture objects currently being drawn
global vars rc_current_picture_object = false;

define is_current_picture_object(pic);
	pic == rc_current_picture_object;
enddefine;

define set_current_picture_object(pic);
	pic -> rc_current_picture_object;
enddefine;

define unset_current_picture_object(pic);
	pic -> rc_current_picture_object;
enddefine;

define :method rc_set_drawing_colour(pic:rc_linepic, colour, window);
	;;;; can be redefined for opaque movable objects
	colour -> rc_foreground(window)
enddefine;


/*
define -- String procedures
*/

lconstant
	string_descriptors = [FONT COLOUR];

;;; defined below
vars procedure rc_interpret_strings;

define rc_interpret_qualified_strings(list, pic);
;;; This may turn out to be needed for tracing in a multi process environment

	lvars
		oldfont = rc_font(rc_window),
		oldforeground = rc_foreground(rc_window);

	dlocal
		0 %,if dlocal_context fi_< 3 then
				oldfont -> rc_font(rc_window);
				oldforeground -> rc_foreground(rc_window)
			endif%;

	lvars key;
	while ispair(list)
	and fast_lmember(fast_front(list) ->> key, string_descriptors)
	do
		if key == "FONT" then
			destpair(fast_back(list)) -> (rc_font(rc_window), list);

		;;; See if there is a colour specification
		elseif key == "COLOUR" then
			;;; Was previously: before 18 Jun 2000
			;;; destpair(fast_back(list)) -> (rc_foreground(rc_window), list);

			;;; This will behave differently when redrawing an
			;;; opaque object
			rc_set_drawing_colour(
				pic, destpair(fast_back(list))-> list, rc_window);
		endif;
			
	endwhile;

	;;; environment set, so do it
	rc_interpret_strings(list, pic)
enddefine;

;;; User definable procedure for printing strings.
;;; defaults to rc_print_at. users may need to change this
;;; to deal with change of sign in rc_xscale and/or rc_ycale

global vars procedure rc_print_pic_string = rc_print_at;

define vars procedure rc_interpret_strings(strings, pic);
	;;; First check for environment keyword
	lvars item;

	if isprocedure(strings) or isword(strings) then
		recursive_valof(strings)(pic)
	else
		
		until strings == [] do

			destpair(strings) -> ( item, strings );

			if isvector(item) then
				rc_print_pic_string(explode(item))
			elseif islist(item) then
				rc_interpret_qualified_strings(item, pic);
			else
				mishap(item,1,'LIST OR VECTOR NEEDED IN STRING SPEC')
			endif;
		enduntil;
	endif
enddefine;

/*
define -- Utilities for drawing pictures
*/


/*
define -- Abbreviations for picture types

*/

;;; Convenient abbreviations for rc_graphic drawing procedures
;;; other autoloadable drawing procedurs are available, e.g.
;;; rc_draw_blob, rc_draw_ob
global vars
	SQUARE  = "rc_draw_square",		;;; non-rotatable square
	RSQUARE = "rc_draw_Rsquare",	;;; rotatable square
	RECT    = "rc_draw_rect",		;;; non-rotatable rectangle
	RRECT   = "rc_draw_Rrect",		;;; rotatable rectangle
	CIRCLE	= "rc_draw_circle",		;;; circle
	ARC		= "rc_draw_arc", ;;; six args (See HELP * RC_GRAPHIC/rc_draw_arc)

;

global vars
	pic_descriptors = [WIDTH STYLE COLOUR ANGLE XSCALE YSCALE];

;;; Procedures defined below
vars procedure
	(rc_draw_lines_rotated,
	rc_interpret_pics,
	);

define vars procedure rc_interpret_qualified_pics(pic_specs, pic);
	;;; Interpreter for picture specification, with special keywords rotation.
	;;; For examples see TEACH RC_LINEPIC
	;;; Draw the lines and strings for a linepic, interpreting
	;;; keywords, such as CLOSED, CIRCLE, ARC, etc. in pic_specs

	lvars
		oldyorigin = rc_yorigin,
		oldxorigin = rc_xorigin,
		oldxscale = rc_xscale,
		oldyscale = rc_yscale,
		oldwidth = rc_line_width(rc_window),
		oldstyle = rc_line_style(rc_window),		;;; dashed, dotted, etc.
		oldforeground = rc_foreground(rc_window);	;;; colour

	;;; Define "exit" action, for normal exits
	dlocal 0 %,
		if dlocal_context fi_< 3 then
			oldwidth -> rc_line_width(rc_window);
			oldstyle -> rc_line_style(rc_window);
			oldforeground -> rc_foreground(rc_window);
			oldxorigin -> rc_xorigin,
			oldyorigin -> rc_yorigin,
			oldxscale -> rc_xscale,
			oldyscale -> rc_yscale,
		endif%;

	lvars key, angle = false;

	while ispair(pic_specs)
	and fast_lmember(fast_front(pic_specs) ->> key, pic_descriptors)
	do
		;;; key is one of the pic_descriptors, find out which, and set
		;;; environment.

		;;; See if there's a global width specification
		;;; WIDTH <num>
		if key == "WIDTH" then
			destpair(fast_back(pic_specs)) ->
			(rc_line_width(rc_window), pic_specs);

			;;; See if there's a global style specification
			;;; STYLE <num>
		elseif key == "STYLE" then
			destpair(fast_back(pic_specs))
				-> (rc_line_style(rc_window), pic_specs);

			;;; See if there's a global foreground (colour) specification
			;;; COLOUR <string>
		elseif key == "COLOUR" then
			;;; this will behave differently when redrawing an
			;;; opaque object
			rc_set_drawing_colour(
				pic, destpair(fast_back(pic_specs))-> pic_specs, rc_window);
		elseif key == "XSCALE" then
			destpair(fast_back(pic_specs))
				-> (rc_xscale, pic_specs);
		elseif key == "YSCALE" then
			destpair(fast_back(pic_specs))
				-> (rc_yscale, pic_specs);
		elseif key == "ANGLE" then
			;;; see if there is an angle specification
			destpair(fast_back(pic_specs)) -> (angle, pic_specs);
		else
			;;; No other options possible as yet
			mishap('Unrecognized picture descriptor',[^key]);
		endif;
	endwhile;

	if angle then
		rc_draw_lines_rotated(
			0, 0, pic_specs, [], angle + rc_frame_angle, pic);
	else
		;;; Interpret the list of pictures, in the standard frame
		;;; (which may result in a recursive call to this procedure)
		rc_interpret_pics(pic_specs, pic)
	endif;

enddefine;

define lconstant apply_proc(procedure proc, args);
	if args == [] then
		proc()
	else
		lvars item;
		for item in args do
			proc(explode(item))
		endfor;
	endif;
enddefine;

define vars procedure rc_interpret_pics(pic_specs, pic);
	;;; Interpret each item in pic_specs.
	;;; It can be
	;;; o a procedure, to be applied to pic
	;;; o a list starting with one of the key words in "pic_descriptors",
	;;; o a list starting with a procedure or procedure name, followed
	;;; 	by one or more vectors providing arguments to be given to the procedure,
	;;; o a list of point coordinates, in the form of two-element vectors,
	;;;		or pairs, or other type suitable for explode

	lvars item;
	recursive_valof(pic_specs) -> pic_specs;
	if isprocedure(pic_specs) then
		pic_specs(pic)
	else
		until pic_specs == [] do
			front(pic_specs) -> item;
			;;; Now what is to be drawn. Default is open polyline
			;;; Is there a keyword? E.g. "CIRCLE", or "ARC" or "CLOSED",
			;;; or a procedure name.
			
			if item == "CLOSED" then
				;;; draw closed polyline
				rc_draw_pointlist(fast_back(pic_specs), true);
				return();
			elseif isword(item) then
				recursive_valof(item) -> item;

				unless isprocedure(item) then
					mishap(
						'DRAWING PROCEDURE NEEDED: ' sys_>< front(item) sys_>< ' found',
						[^item]);
				endunless;

				;;; The rest of the picture description is a list of vectors of
				;;; arguments for proc. It could be empty

				apply_proc(item, fast_back(pic_specs));
				return();
			elseif isvector(item) or (ispair(item) and isnumber(fast_front(item))) then
				;;; Drawing an open polyline
				rc_draw_pointlist(pic_specs, false);
				return();
			elseif ispair(item) then
				;;; A sub-description in the form of a list. Interpret then return to this loop
				if fast_lmember(fast_front(item), pic_descriptors) then
		 			rc_interpret_qualified_pics(item, pic)
				else
		 			rc_interpret_pics(item, pic)
				endif
			elseif isrecordclass(item) then
				;;; assume that it is a record class instance used for defining points
				;;; whose components can be accessed by explode, like conspair
				;;; Drawing an open pointlist
				rc_draw_pointlist(pic_specs, false);
				return();
			elseif isprocedure(item) then
				;;; Like the word case
				;;; The rest of the picture description is a list of vectors of
				;;; arguments for proc. Possibly empty
				apply_proc(item, fast_back(pic_specs));
				return();
			else
				mishap('Unrecognized picture element', [^item])
			endif;
			fast_back(pic_specs) -> pic_specs;
		enduntil
	endif
enddefine;

define vars procedure rc_draw_lines_normal(startx, starty, pic_specs, strings, pic);
	;;; Draw the lines and strings for a rotateable linepic, interpreting
	;;; keywords, such as CLOSED, CIRCLE, ARC, etc. in pic_specs

	lvars old_current = rc_current_picture_object;	

	dlocal
		0 % ,
		    if dlocal_context fi_< 3 then
				unset_current_picture_object(old_current) endif%;

	set_current_picture_object(pic);
			
	;;; Use startx and starty as rc_xorigin and rc_yorigin
	;;; Could be extended to use scale arguments. But for now
	;;; assumes rc_xscale and rc_yscale are global.

	lvars oldxorigin = rc_xorigin, oldyorigin = rc_yorigin;

	dlocal
		0 % , if dlocal_context fi_< 3 then
				oldxorigin -> rc_xorigin;
				oldyorigin -> rc_yorigin;
				endif%;

		rc_xorigin + rc_xscale*startx -> rc_xorigin;
		rc_yorigin + rc_yscale*starty -> rc_yorigin;

	;;; first draw the pictures

	recursive_valof(pic_specs) -> pic_specs;
	if isprocedure(pic_specs) then
		rc_interpret_pics(pic_specs, pic)
	else
		;;; It should be a list, possibly empty
		unless pic_specs == [] then
			;;; First check for environment keyword
			if fast_lmember(front(pic_specs), pic_descriptors) then
				;;; interpret in changed environment
				rc_interpret_qualified_pics(pic_specs, pic)
			else
				rc_interpret_pics(pic_specs, pic)
			endif
		endunless;
	endif;

	;;; now draw the strings
	unless strings == [] then
		if ispair(strings) and fast_lmember(front(strings), string_descriptors) then
			;;; interpret in changed environment
			rc_interpret_qualified_strings(strings, pic)
		else
			rc_interpret_strings(strings, pic);
		endif
	endunless
enddefine;

define :method rc_draw_pics_rotated(pic:rc_rotatable, startx, starty, pics, ang);
	;;; draw pictures, but not strings
	dlocal
		rc_frame_angle = ang,
		rc_transxyout = rc_rotate_coords_rounded;

	rc_draw_lines_normal (startx, starty, pics, [], pic);
enddefine;

define :method rc_draw_strings_rotated(pic:rc_rotatable, startx, starty, strings, ang);
	;;; draw strings but not pictures
	dlocal
		rc_frame_angle = ang,
		rc_transxyout = rc_rotate_coords_rounded;

	rc_draw_lines_normal (startx, starty, [], strings, pic);

enddefine;

define :method rc_draw_strings_rotated(pic:rc_rotatable_picsonly, startx, starty, strings, ang);
	;;; draw the strings, but not rotated
	dlocal
		rc_frame_angle = 0,
		rc_transxyout = rc_rotate_coords_rounded;

	rc_draw_lines_normal (startx, starty, [], strings, pic);

enddefine;

define vars procedure rc_draw_lines_rotated
			(startx, starty, pic_specs, strings, ang, pic);
	;;; Version of previous procedure with rotated axes, specified by ang

	rc_draw_pics_rotated(pic, startx, starty, pic_specs, ang);

	rc_draw_strings_rotated(pic, startx, starty, strings, ang);

enddefine;

/*
define -- Methods for drawing and re-drawing pictures
*/

;;; two variables that control drawing mode. To be replaced
global vars
	wastrailing = false,
	wasequiv=false,
	;

define :method rc_draw_linepic(pic:rc_linepic);
	;;; The basic method that does the drawing of a picture
	dlocal rc_linefunction = GXcopy;
	rc_draw_lines_normal(
		rc_coords(pic), rc_pic_lines(pic), rc_pic_strings(pic), pic)
enddefine;

		

define :method rc_draw_linepic(pic:rc_linepic_movable);
	;;; The method that does the drawing for a movable object

	define lconstant do_drawing(pic,xloc,yloc);
		rc_draw_lines_normal(
			xloc, yloc,
			rc_pic_lines(pic),
			rc_pic_strings(pic),
			pic);
	enddefine;

	unless Glinefunctionsetup then rc_setup_linefunction() endunless;

	dlocal rc_linefunction = Glinefunction;

	Gdrawprocedure(pic, wasequiv, wastrailing, do_drawing);

enddefine;

define :method rc_draw_linepic(pic:rc_rotatable);
	;;; The method that does the drawing for a rotatable object

	define lconstant do_drawing(pic, xloc, yloc);
		rc_draw_lines_rotated(
			xloc, yloc,
			rc_pic_lines(pic),
			rc_pic_strings(pic),
			rc_axis(pic),
			pic);
	enddefine;

	unless Glinefunctionsetup then rc_setup_linefunction() endunless;

	dlocal rc_linefunction = Glinefunction;

	Gdrawprocedure(pic, wasequiv, wastrailing, do_drawing);

enddefine;

define :method rc_draw_oldpic(pic:rc_linepic_movable);
	;;; A method to draw the object at the old location (which will
	;;; obliterate it if rc_linefunction is set right)
	;;; Prevent re-drawing if not already drawn (rc_oldx(pic) is false)

	define lconstant do_drawing(pic, xloc, yloc);
		rc_draw_lines_normal(
			rc_oldx(pic),
			rc_oldy(pic),
			rc_pic_lines(pic),
			rc_pic_strings(pic),
			pic);
	enddefine;

	if rc_oldx(pic) then
		unless Glinefunctionsetup then rc_setup_linefunction() endunless;

		;;; Drawn at old location so undraw it
		dlocal rc_linefunction = Glinefunction;

		Gdrawprocedure(pic, Glinefunction == GXequiv, wastrailing, do_drawing);
	endif;

	;;; prevent redrawing
	false -> rc_oldx(pic);
enddefine;

define :method rc_draw_oldpic(pic:rc_rotatable);
	;;; As above, but for rotatable objects

	define lconstant do_drawing(pic, xloc, yloc);
		rc_draw_lines_rotated(
			rc_oldx(pic),
			rc_oldy(pic),
			rc_pic_lines(pic),
			rc_pic_strings(pic),
			rc_oldaxis(pic),
			pic);
	enddefine;

	if rc_oldx(pic) then
		unless Glinefunctionsetup then rc_setup_linefunction() endunless;

		dlocal rc_linefunction = Glinefunction;
		Gdrawprocedure(pic, wasequiv, wastrailing, do_drawing);

	endif;
	;;; prevent redrawing
	false -> rc_oldx(pic);
enddefine;

/*
define :method rc_undraw_linepic(pic:rc_linepic);
	;;; by default picture objects cannot be undrawn, so do nothing.
	;;; better to leave this out and let a mishap occur?
enddefine;
*/

define :method rc_undraw_linepic(pic:rc_linepic_movable);
	if rc_oldx(pic) then
		rc_draw_oldpic(pic);
		false -> rc_oldx(pic);
	endif;
enddefine;
	
define :method rc_undraw_linepic(pic:rc_rotatable);
	if rc_oldx(pic) then
		rc_draw_oldpic(pic);
		false -> rc_oldx(pic);
	endif;
enddefine;


/*
define -- Methods for drawing moving pictures
*/

;;; dummy methods to avoid spurious mishaps
define :method rc_move_to(pic:rc_linepic, newx, newy, draw);
	;;; do nothing
enddefine;

define :method rc_move_by(pic:rc_linepic, dx, dy, draw);
	;;; do nothing
enddefine;

define :method rc_move_draw(pic:rc_linepic_movable);
	;;; Draw a moving object. Draw at old location, then at new.
	rc_undraw_linepic(pic);
	rc_draw_linepic (pic);
enddefine;


define :method rc_move_to(pic:rc_linepic_movable, newx, newy, draw);
	;;; Move a picture to location (newx, newy).
	;;; If the final argument is non false, then draw the picture
	;;; 	moving.
	;;; If it is true obliterate old location. If it is "trail"
	;;;		then leave the old location.
	;;;	If is false don't draw.
	;;; If rc_pause_draw is true, pause after drawing.

	lvars
		;;; Get initial location
		already_drawn = rc_oldx(pic),
		(oldx, oldy) = rc_coords(pic);

	unless Glinefunctionsetup then rc_setup_linefunction() endunless;

	dlocal wastrailing = draw == "trail",
			wasequiv = Glinefunction == GXequiv;

	if draw == true then ;;; not "trail"
		unless already_drawn then
			rc_draw_linepic(pic);
			;;; that will update the old location
		else
			;;; Record "old" location
			oldx -> rc_oldx(pic);
			oldy -> rc_oldy(pic);
		endunless
	endif;

	;;; Move startpoint to newx,newy and store new location
	(newx, newy) -> rc_coords(pic);

    if wastrailing then
		;;; Not previously drawn, or drawing a trail
		;;; just draw new position
		dlocal Glinefunction = GXcopy;
		rc_draw_linepic(pic);
	elseif draw then
		;;; draw old (to remove picture) and new
		rc_move_draw(pic);
	endif;
	if draw then
		rc_check_pausing();
	endif;
enddefine;

define :method rc_move_by(pic:rc_linepic_movable, dx, dy, draw);
	;;; Move a picture by amount dx, dy.
	rc_move_to(pic, rc_picx(pic) + dx, rc_picy(pic) + dy, draw);
enddefine;

/*
define -- Methods for rotation
*/

define :method rc_set_axis(pic:rc_rotatable, ang, draw);
	;;; Move axis to angle ang
	;;; If the final argument is non false, then draw the picture
	;;; 	moving.
	;;; If it is true obliterate old location. If it is "trail"
	;;;		then leave the old location.
	;;;	If is false don't draw.
	;;; If rc_pause_draw is true, pause after drawing.

	unless Glinefunctionsetup then rc_setup_linefunction() endunless;

	dlocal wastrailing = draw == "trail";

	if draw == true then ;;; not "trail"
		rc_draw_oldpic(pic)
	endif;

	;;; Store new angle
	ang -> rc_axis(pic);

	if wastrailing then
		dlocal rc_linefunction = GXcopy, Glinefunction = GXcopy;
	endif;

	rc_draw_linepic(pic);
	if draw then
		rc_check_pausing();
	endif;
enddefine;

define :method rc_turn_by(pic:rc_rotatable, ang, draw);
	rc_set_axis(pic, rc_axis(pic)+ang, draw)
enddefine;

global vars rc_linepic = true;	;;; for uses
endsection;

nil -> proglist;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep 17 2002
		At the suggestion of Jonathan Cunningham, added dummy (null) methods
			rc_move_to(pic:rc_linepic, newx, newy, draw);
			rc_move_by(pic:rc_linepic, dx, dy, draw);
	
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug  8 2002
	Redeclared more things as vars to simplify debugging.
--- Aaron Sloman, Jul  9 2000
	Rebuilt the index
--- Aaron Sloman, Jul  7 2000
	Introduced rc_rotatable_picsonly, and split rc_draw_lines_rotated
	following a suggestion by Matthias Scheutz
--- Aaron Sloman, Jun 18 2000
	replaced lconstant check_pausing with rc_check_pausing
--- Aaron Sloman, Jun 18 2000
	Changed slot defaults to use "==" for constants.

	Introduced
		method rc_set_drawing_colour(pic:rc_linepic, colour, window);
	for use with opaque moving objects
enddefine;

--- Aaron Sloman, Mar 21 1999
	Altered rc_draw_lines_normal to include an extra check
--- Aaron Sloman, Aug 10 1997
	Changed so that if value of rc_pic_lines slot is a procedure it
	is applied directly to the appropriate picture, instead of having
	to use the variable rc_current_picture_object

	Also changed rc_current_picture_object to be a list, and introduced
		is_current_picture_object(pic);
		set_current_picture_object(pic);
		unset_current_picture_object(pic);

--- Aaron Sloman, Jun 17 1997
	Add XSCALE and YSCALE as linepic features
--- Aaron Sloman, Jun 13 1997
	Introduced rc_print_pic_string, decaulting to rc_print_at;
	Also allowed rc_pic_strings to be a procedure or a word naming
		a procedure
--- Aaron Sloman, May 18 1997
	Changed to allow rc_pic_lines to hold a procedure or name
	of a procedure.
--- Aaron Sloman, Apr 21 1997
	Made rc_undrawn do nothing on non-movable objects.
--- Aaron Sloman, Mar 27 1997
	added method rc_undraw_linepic
--- Aaron Sloman, Mar 25 1997
	renamed rc_draw_*polyline as rc_draw_pointlist

--- Aaron Sloman, Mar 24 1997
	Moved stuff concerned with setting up Glinefunction to
		LIB rc_setup_linefunction

    With help from Riccardo Poli, cleaned up LIB rc_black_white_inverted

	Made available currently drawn picture in the variable
		rc_current_picture_object (not rc_active_picture_object, as in lib rc_mousepic)
	This required some reorganisation.

--- Aaron Sloman, Jan 14 1997
		Added Glinefunctionsetup and rc_setup_linefunction, to automate setting up
		of drawing mode for Alphas, etc.
--- Aaron Sloman, Jan 12 1997
	Generalised and optimised, allowing environment descriptors in any order,
	and recursively in string specs and picture specs.
	Allows points to be any two element recordclass
--- Aaron Sloman, Jan 11 1997
	After experimenting with Riccardo Poli's suggestions for handling the
	DEC Alpha's colour maps reorganised drawings, using planemasks.
	Introduced user defineable Gdrawprocedure
--- Aaron Sloman, Jan  1 1997
	Generalised to allow fonts and colours to be specified in rc_pic_strings.
	Added more picture types (e.g. rc_draw_blob). Generalised the
	mechanisms and removed various bugs. Reduced interaction between
	drawing procedures and event-handling in rc_mousepic

	Fixed cacheing of various things, including foreground (colour),
	linewidth, font, linestyle, linefunction etc.

	Put some of the drawing procedures into separate autoloadable files.

--- Aaron Sloman, Apr 14 1996
	Generalised in various ways. Added WIDTH, STYLE, RECT, RRECT,
	SQUARE, RSQUARE, oblong drawing, and allowed user-definable
	procedures to be used.
	This included producing cached versions of rc_linestyle and
	rc_linewidth, rc_linefunction, and generalising rc_linepic_bounds
--- Aaron Sloman, Apr 11 1996
	Lots of cleaning up
--- Aaron Sloman, Apr 11 1996
	Added support for rotatable, and made more things methods instead of
	procedures.
--- Aaron Sloman, Apr 10 1996
	Move stuff for selectables to rc_mousepic

CONTENTS (Use ENTER g define, or ENTER gg)

 define -- The main mixins
 define :mixin vars rc_linepic;
 define :mixin vars rc_linepic_movable; is rc_linepic;
 define :mixin vars rc_rotatable; is rc_linepic_movable;
 define :mixin vars rc_rotatable_picsonly; is rc_rotatable;
 define :class dummy;  is rc_rotatable;
 define -- Pausing utility (probably useless, except for debugging?)
 define global vars rc_check_pausing();
 define -- Procedures assignable to Gdrawprocedure
 define rc_xor_drawpic(pic, wasequiv, wastrailing, procedure proc);
 define rc_equiv_drawpic(pic, wasequiv, wastrailing, procedure proc);
 define -- Utility procedures and methods
 define :method vars rc_coords(pic:rc_linepic);
 define :method updaterof rc_coords(/*x, y,*/ pic:rc_linepic);
 define :method rc_undrawn(pic:rc_linepic);
 define :method rc_undrawn(pic:rc_linepic_movable);
 define vars procedure rc_undraw_all(pics);
 define -- Utilities concerned with rotation.
 define active rc_frame_angle();
 define updaterof active rc_frame_angle(angle);
 define rc_rotate_coords(x, y) -> (x, y);
 define rc_rotate_coords_rounded(x, y) -> (x, y);
 define -- picture bounds procedures
 define :method rc_linepic_bounds(pic:rc_linepic, absolute)
 define :method rc_linepic_bounds (pic:rc_rotatable, absolute)
 define -- Core procedures for drawing lines and strings
 define is_current_picture_object(pic);
 define set_current_picture_object(pic);
 define unset_current_picture_object(pic);
 define :method rc_set_drawing_colour(pic:rc_linepic, colour, window);
 define -- String procedures
 define rc_interpret_qualified_strings(list, pic);
 define vars procedure rc_interpret_strings(strings, pic);
 define -- Utilities for drawing pictures
 define -- Abbreviations for picture types
 define vars procedure rc_interpret_qualified_pics(pic_specs, pic);
 define lconstant apply_proc(procedure proc, args);
 define vars procedure rc_interpret_pics(pic_specs, pic);
 define vars procedure rc_draw_lines_normal(startx, starty, pic_specs, strings, pic);
 define :method rc_draw_pics_rotated(pic:rc_rotatable, startx, starty, pics, ang);
 define :method rc_draw_strings_rotated(pic:rc_rotatable, startx, starty, strings, ang);
 define :method rc_draw_strings_rotated(pic:rc_rotatable_picsonly, startx, starty, strings, ang);
 define vars procedure rc_draw_lines_rotated
 define -- Methods for drawing and re-drawing pictures
 define :method rc_draw_linepic(pic:rc_linepic);
 define :method rc_draw_linepic(pic:rc_linepic_movable);
 define :method rc_draw_linepic(pic:rc_rotatable);
 define :method rc_draw_oldpic(pic:rc_linepic_movable);
 define :method rc_draw_oldpic(pic:rc_rotatable);
 define :method rc_undraw_linepic(pic:rc_linepic);
 define :method rc_undraw_linepic(pic:rc_linepic_movable);
 define :method rc_undraw_linepic(pic:rc_rotatable);
 define -- Methods for drawing moving pictures
 define :method rc_move_to(pic:rc_linepic, newx, newy, draw);
 define :method rc_move_by(pic:rc_linepic, dx, dy, draw);
 define :method rc_move_draw(pic:rc_linepic_movable);
 define :method rc_move_to(pic:rc_linepic_movable, newx, newy, draw);
 define :method rc_move_by(pic:rc_linepic_movable, dx, dy, draw);
 define -- Methods for rotation
 define :method rc_set_axis(pic:rc_rotatable, ang, draw);
 define :method rc_turn_by(pic:rc_rotatable, ang, draw);

 */
