/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_transform_lines.p
 > Purpose:			Draw a succession of open/closed polygons
 > Author:          Aaron Sloman, Nov 16 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:
 */

/*

;;; tests

uses rclib;
uses rc_window_object

rc_kill_window_object(win1);

vars win1 =
        rc_new_window_object("right", "top", 500, 500, true, 'win1');

;;; rc_transform_lines(
;;; 		coords1, coords2, steps, colour, widthOrShape,
;;; 		mode, delay, trail, procedure proc);

rc_start();

rc_transform_lines([0 100 50 0 50 100], [180 -50 150 150 200 200], 40,
	'blue', 3, CoordModeOrigin, 2, false, rc_draw_lines)=>

rc_transform_lines([0 100 50 0 50 100], [180 -50 150 150 200 200], 40,
	'green', 2, CoordModeOrigin, 2, true, rc_draw_lines);

rc_transform_lines([-100 100 50 0 50 100], [180 -50 150 150 200 200], 40,
	'red', 2, CoordModeOrigin, 2, false, rc_draw_lines_closed);

rc_transform_lines([-100 150 50 0 50 100], [180 -50 150 150 200 200], 40,
	'blue', 2, CoordModeOrigin, 2, false, rc_draw_lines_filled);



rc_draw_blob(0,0,80,'red');

rc_start();

rc_transform_lines(
	[0   100  50 0   50  100 -50 200 -100 -50],
	[100 -150 180 140 100 60 180 250 100 200], 40,
	'green', 3, CoordModeOrigin, 1, false, rc_draw_lines);

rc_transform_lines(
	[0   100  50 0   50  100 -50 200 -100 -50],
	[100 -150 180 140 100 60 180 250 100 200], 50,
	'orange', 3, CoordModeOrigin, 1, true, rc_draw_lines)=>

rc_transform_lines([-100 150 50 0 50 100], [180 -50 150 150 200 200], 40,
	'blue', Convex, CoordModeOrigin, 2, false, rc_draw_lines_filled);

rc_start();

rc_transform_lines({0   100  50 0   50  100 -50 200 -100 -50},
				   [100 -150 180 140 100 60 180 250 100 200], 40,
	'green', 3, CoordModeOrigin, 1, false, rc_draw_lines_closed);

rc_transform_lines([0   100  50 0   50  100 -50 200 -100 -50],
				   [100 -150 180 140 70 60 180 250 100 200], 40,
	'red', Complex, CoordModeOrigin, 2, false, rc_draw_lines_filled);

rc_transform_lines([0   100  50 0   50  100 -50 200 -100 -50],
				   [100 -150 180 140 80 60 180 250 100 200], 40,
	'red', Nonconvex, CoordModeOrigin, 2, false, rc_draw_lines_filled);

;;; demonstrate movement using a procedure to draw a line given
;;; one end, a radius and an orientation

false -> popradians;

define draw_radius(vec, colour, width, mode);
	lvars (x, y, rad, orient) = explode(vec);

	;;; ignore the mode arguement.

	dlocal
		%rc_foreground(rc_window)%,

		rc_linewidth;
			
	if colour then colour -> rc_foreground(rc_window) endif;
	if width then width -> rc_linewidth endif;

	rc_drawline(x, y, x + rad*cos(orient), y + rad*sin(orient))
enddefine;

rc_start();

rc_transform_lines({-100   100  50 0},
				   {-100 -150 50 180}, 40,
					'red', 2, false, 3, false, draw_radius);



*/

compile_mode :pop11 +strict;

section;

uses rclib;
uses rc_interpolate_coords
uses rc_draw_lines

define rc_transform_lines(coords1, coords2, steps, colour, widthOrShape, mode, delay, trail, procedure proc);
	checkinteger(steps, 0, false);

	rc_setup_linefunction();


	dlocal rc_linefunction = Glinefunction;

    lvars
        len = length(coords1),
		(, coordsa) = getpointvec(coords1, 2, false),
		coordsb = if trail then false else copy(coordsa) endif,
		stepnum;
	;;; make sure it is a new vector
	if coords1 == coordsa then copy(coordsa) -> coordsa endif;
	for stepnum from 0 to steps do
		;;; set coordsa, and if necessary coordsb, to have the coordinates
		rc_interpolate_coords(coords1, coords2, steps, stepnum, coordsa) -> coordsa;
		unless trail then
			;;; keep a record of the coordinates for undrawing the picture
			explode(coordsa), fill(coordsb) ->;
		endunless;
		;;; now draw the picture
		proc(coordsa, colour, widthOrShape, mode);

		;;; delay if necessary
		unless delay == 0 then
			syssleep(delay);
		endunless;

		;;; if not leaving a trail, delete the last picture drawn
		unless trail or stepnum == steps then ;;; don't leave trail, i.e. delete before next draw
			proc(coordsb, colour, widthOrShape, mode);
		endunless;

	endfor;

	unless coordsa == coords1 then freepointvec(coordsa) endunless;
	if coordsb then freepointvec(coordsb) endif;
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov 19 2000
	Made sure that getpointvec produces a new vector if coords1 is
	a vector, otherwise coords1 will be corrupted.
 */
