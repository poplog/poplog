/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_transform_pictures.p
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


;;; rc_transform_pictures(pics, steps, delay, trail);
;;; each pic is a vector or list:
;;; startcoords, endcoords, colour, widthOrShape, mode, proc

rc_start();

rc_draw_blob(0,0,80,'yellow');

rc_transform_pictures(
	[
		[[0 200 50 50 50 100] [180 10 100 190 200 200]
			'blue' 3 ^CoordModeOrigin OPEN]

		[[-150 -200 -50 -10 50 -100] [180 -150 200 -50 240 -200]
			'green' 2 ^CoordModeOrigin CLOSED]

		[[-100 100 50 0 50 100] [200 -50 100 50 220 80]
			'red' 2 ^CoordModeOrigin FILLED]
	],
	20, 1, false);

;;; redo with final argument true to leave a trail
rc_transform_pictures(
	[
		[[0 200 50 50 50 100] [180 10 100 190 200 200]
			'blue' 3 ^CoordModeOrigin OPEN]

		[[-150 -200 -50 -10 50 -100] [180 -150 200 -50 240 -200]
			'green' 2 ^CoordModeOrigin CLOSED]

		[[-100 100 50 0 50 100] [200 -50 100 50 220 80]
			'red' 2 ^CoordModeOrigin FILLED]
	],
	20, 2, true);

rc_start();

;;; demonstrate movement using a procedure to draw a line given
;;; one end, a radius and an orientation


define draw_radius(vec, colour, width, mode);
	lvars (x, y, rad, orient) = explode(vec);

	;;; ignore the mode arguement.

	dlocal
		popradians = false,
		%rc_foreground(rc_window)%,

		rc_linewidth;
			
	if colour then colour -> rc_foreground(rc_window) endif;
	if width then width -> rc_linewidth endif;

	rc_drawline(x, y, x + rad*cos(orient), y + rad*sin(orient))
enddefine;

rc_start();

rc_transform_pictures(
	[
	 {{-100   100  50 0} {-100 -150 50 180}
		'red' 3 ^false draw_radius}
	 [[0 0 -100 100 100 100] [0 100 200 -150 50 180]
			'blue' ^Convex ^CoordModeOrigin  FILLED]
	],
		40, 1, false);

rc_transform_pictures(
	[{{-100   100  50 0}
	 {0 -150 50 180} 'red' 3 ^false draw_radius}],
		20, 2, true);

;;;compare

rc_transform_lines(
	{100   100  50 0},
	 {180 -150 50 180}, 20, 'red', 3, false, 3, false, draw_radius);

rc_transform_lines(
	{100   100  50 0},
	 {100 -150 50 180}, 20, 'red', 3, false, 3, true, draw_radius);

*/

compile_mode :pop11 +strict;

section;

uses rclib;
uses fast_interpolate_coords
uses rc_draw_lines

/*
test

get_vector([a b c d])=>
get_vector({a b c d})=>

*/

define lconstant get_vector(coords) -> newcoords;
	 getpointvec(coords, 2, false) -> (_, newcoords);
	;;; make sure it is a new vector
	if coords == newcoords then copy(coords) -> newcoords endif;
enddefine;

define free_vectors(newpics);
	lvars pic;
	for pic in newpics do
		;;; free items 1, 2, 4, and possibly 3
		freepointvec(subscrv(1, pic));	;;; startcoords
		freepointvec(subscrv(2,pic));	;;; endcoords
		freepointvec(subscrv(3, pic));	;;; coords1
		if subscrv(4, pic)then freepointvec(subscrv(4,pic)) endif;	;;; coords2
		freepointvec(pic);
	endfor;
	sys_grbg_list(newpics);
enddefine;

/*
setup_pic({[0 0] [1 1] 'red' 3 ^CoordModeOrigin FILLED}, true)=>
setup_pic({[0 0] [1 1] 'red' 3 ^CoordModeOrigin FILLED}, false)=>

*/

define lconstant setup_pic(pic, trail) -> newpic;
	;;; get new representation of pic including vectors for
	;;; start, intermediate and end coords, and interpret proc arg.

	lvars
		coords1,
		coords2 = false,
		(startcoords, endcoords, colour, widthOrShape, mode, proc) = explode(pic);

	if proc == "OPEN" then rc_draw_lines
	elseif proc == "CLOSED" then rc_draw_lines_closed
	elseif proc == "FILLED" then rc_draw_lines_filled
	else recursive_valof(proc)
	endif -> proc;

	;;; make sure that the coordinates are all in vectors

	;;; vectors for start and end coords
	get_vector(startcoords) -> startcoords;
	get_vector(endcoords) -> endcoords;

	;;; now coords vector for intermediate states
	copy(startcoords) -> coords1;

	;;; may need an extra vector for undrawing if trail is false
	unless trail then copy(startcoords) -> coords2; endunless;

	{^startcoords ^endcoords ^coords1 ^coords2 ^colour ^widthOrShape ^mode ^proc} -> newpic;

enddefine;

/*

setup_pics([
	{[0 0] [1 1] 'red' Convex ^CoordModeOrigin FILLED}
	[[0 0] [1 1] 'red' 3 ^CoordModeOrigin CLOSED]],
	false)==>

setup_pics(
	{{[0 0] [1 1] 'red' Convex ^CoordModeOrigin FILLED}
	[{0 0} {1 1} 'red' 3 ^CoordModeOrigin ^rc_draw_lines]},
	true)==>

*/

define lconstant setup_pics(pics, trail) -> newpics;
	;;; get new representation of pictures in pics
	if islist(pics) then
		maplist(pics, setup_pic(%trail%))
	else
		[% appdata(pics, setup_pic(%trail%)) %]
	endif -> newpics;

enddefine;


define transform_pic(pic, steps, stepnum, trail);

	lvars
		(startcoords, endcoords, coords1, coords2, colour, widthOrShape, mode, proc)
			= explode(pic);

	unless trail or stepnum == 0 then
		;;; Delete previous version by re-drawing it
		proc(coords2, colour, widthOrShape, mode)
	endunless;

	;;; Draw new version
	;;; Get interpolated coordinates for new version
	fast_interpolate_coords(startcoords, endcoords, steps, stepnum, coords1) -> coords1;

	if coords2 then
		;;; save these values for deleting next time
		explode(coords1), fill(coords2) ->;
	endif;

	;;; Now draw the picture.
	;;; (This will overwrite coords1, which is why we need coords2)
	proc(coords1, colour, widthOrShape, mode)

enddefine;

define rc_transform_pictures(pics, steps, delay, trail);

	rc_setup_linefunction();

	checkinteger(steps, 0, false);

	dlocal rc_linefunction = Glinefunction;

	lvars newpics = setup_pics(pics, trail);

	;;; repeatedly draw all the pictures after transforming them
	lvars stepnum;
	for stepnum from 0 to steps do
		lvars pic;
		for pic in newpics do

			;;; draw the transformed pic
			transform_pic(pic, steps, stepnum, trail);

			;;; delay if necessary
			unless delay == 0 then
				syssleep(delay);
			endunless;

			;;; if not trailing then redraw
			;;; unless trail or stepnum == steps then
				;;; delete before next draw
			;;;	transform_pic(pic, steps, stepnum, false);
			;;;endunless;
		endfor;
	endfor;

	;;; hand back temporary data structures
	free_vectors(newpics);
	
enddefine;

endsection;
