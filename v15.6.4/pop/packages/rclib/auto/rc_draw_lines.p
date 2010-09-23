/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_draw_lines.p
 > Purpose:			Draw polygon of specified location, colour, thickness
 > Author:          Aaron Sloman, Aug  2 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:
 */
/*
uses rc_window_object


vars win1 =
        rc_new_window_object("right", "top", 300, 300, true, 'win1');


rc_start();
;;; rc_draw_coords([% -100, 100, -50, 50, -50, 100%], 'blue', 2, CoordModeOrigin, XpwDrawLines);
;;; rc_draw_coords([% -50, -100, -50, 50, 50, 100%], 'green', 2, CoordModePrevious, XpwDrawLines);

rc_draw_lines([%0,0, 100, 0, 100, 100%], 'red', 3, CoordModeOrigin);
rc_draw_lines_closed([%0,0, 100, 0, 100, 100%], 'blue', 3, CoordModeOrigin);
rc_draw_lines_closed([%-100, 0, -100, -100, 0, 0%], 'green', 3, CoordModeOrigin);
rc_draw_lines([%0,0, 100, 100%], 'yellow', 3, CoordModeOrigin);
rc_draw_lines({0 100 100 0 100 100 -100 -100}, 'blue', 5, CoordModeOrigin);
rc_draw_lines_closed([0 100 100 0 100 100 -100 -100], 'red', 5, CoordModeOrigin);
rc_draw_lines({0 100 100 100 0 0}, 'green', 5, CoordModeOrigin);
rc_start();
rc_draw_lines([%0, 0, 50, 50, -100, 100%], 'red', 5, CoordModeOrigin);
rc_draw_lines_closed([%50, 50, -100, 100, 0, 0%], 'blue', 5, CoordModeOrigin);
rc_draw_lines({50 100 100 50 0 100 -100 -50}, 'blue', 5, CoordModeOrigin);
rc_draw_lines_closed({50 100 100 50 0 100 -100 -50}, 'blue', 5, CoordModeOrigin);
rc_draw_lines([%-100,-100, 100, 0, -100, 100%], 'pink', 10, CoordModeOrigin);

rc_draw_lines(consshortvec(#| -100,-100, 100, 0, -100, 100 |#), 'pink', 10, CoordModeOrigin);

rc_start();
rc_draw_lines({-100 100 20 0 0 -20 20 0 50 -50 -100 0}, 'red', 5, CoordModePrevious);
rc_draw_lines({-100 50 20 0 0 -20 20 0 50 -50 -100 0}, 'pink', 5, CoordModePrevious);
rc_draw_lines({-120 0 20 0 0 -20 20 0 50 -50 -100 0}, 'blue', 5, CoordModePrevious);
rc_start();
rc_draw_lines_closed({-100 100 20 0 0 -20 20 0 50 -50 -100 0}, 'red', 5, CoordModePrevious);
rc_draw_lines_closed({-100 50 20 0 0 -20 20 0 50 -50 -100 0}, 'pink', 5, CoordModePrevious);
rc_draw_lines_closed({-120 0 20 0 0 -20 20 0 50 -50 -100 0}, 'blue', 5, CoordModePrevious);

rc_start();
rc_draw_lines_filled([%0,0, 100, 0, 100, 100%], 'red', Convex, CoordModeOrigin);
rc_draw_lines_filled({%0,0, 100, 100, -100, 0%}, 'yellow', Convex, CoordModeOrigin);
rc_draw_lines_filled([0 100 100 0 100 100 -100 -100], 'blue', Complex, CoordModeOrigin);
rc_draw_lines_filled([0 100 100 0 100 100 -100 -100], 'grey', Nonconvex, CoordModeOrigin);
rc_draw_lines_filled([-100 100 30 0 0 -30 -50 -50], 'blue', Convex, CoordModePrevious);
rc_draw_lines_filled([-100 0 30 0 0 -30 -50 -50], 'red', Convex, CoordModePrevious);
rc_draw_lines_filled({120 0 20 0 0 -20 20 0 50 -50 -100 0}, 'blue', Convex, CoordModePrevious);
rc_draw_lines_filled({120 0 20 0 0 -20 20 0 50 -50 -100 0}, 'orange', Convex, CoordModeOrigin);

*/

uses rclib
uses rc_linepic
loadinclude XpwPixmap.ph

uses getpointvec;	;;; provides freepointvec also

section;

define lconstant rc_draw_coords(coords, colour, widthOrShape, mode, closed, procedure proc);
	;;; Draw lines joining the points in coords.
	;;; mode is CoordModeOrigin or CoordModePrevious
	;;; closed is true or false: false for an open polygon (irrelevant for fill)
	;;; proc is XpwDrawLines or XpwFillPolygon
	;;; If proc XpwDrawLines is then widthOrShape should be a number representing the
	;;; required line width.
	;;; If proc is XpwFillPolygon then widthOrShape should
	;;; be one of Convex, Nonconvex or Complex see REF XpwPixmap
	;;; (REF file says "NonConvex", but that's a mistake)


	dlocal
		%rc_foreground(rc_window)%;

	if colour then colour -> rc_foreground(rc_window) endif;

	lvars

		len = length(coords),
		;;; transfer the coordinates to a NEW short vector
		(n, vec) = getpointvec(coords, 2, closed),

		newlen = datalength(vec),	;;; will be len+2 if closed
		x, y,
		index = 1;


	dlocal rc_xorigin, rc_yorigin;

	;;; Transform the points to use the rc_graphic coordinates
	if mode == CoordModePrevious then

		;;; get the first two points transformed (relative to origin)
		;;; NB rc_transxyout rounds, so only integers are returned.
		;;; in principle they should be short (16 bit), but may not be!
		;;; If so a mishap will occur.
		rc_transxyout(	
			fast_subscrv(1, vec),
			fast_subscrv(2, vec))
			-> ( fast_subscrv(1, vec),
			fast_subscrv(2, vec));

		;;; treat all additional coordinates as relative to previous ones
		;;; by setting origin at 0,0
		0 ->> rc_xorigin -> rc_yorigin;
		3 -> index;

		until index fi_> len do
			rc_transxyout(	
				fast_subscrv(index, vec),
				fast_subscrv(index fi_+ 1, vec))
					-> ( fast_subscrv(index, vec),
						fast_subscrv(index fi_+ 1, vec));
			index fi_+ 2 -> index;
		enduntil;
		if closed then
			;;; compute the last two coordinates by working out how far the
			;;; last point is from the first
			lvars xinc = 0, yinc = 0;
			3 -> index;
			until index fi_> len do
				fast_subscrv(index, vec) + xinc -> xinc;
				fast_subscrv(index fi_+ 1, vec) + yinc -> yinc;
				index fi_+ 2 -> index;
			enduntil;
			;;; now fill the last two points with the reverse vector
			-xinc -> fast_subscrv(len + 1, vec);
			-yinc  -> fast_subscrv(len + 2, vec);
		endif;

	elseunless mode == CoordModeOrigin then
		mishap('Wrong "mode" arg in line/poly drawing procedure', [^mode])

	else
		;;; CoordModeOrigin
		;;; transform all the coordinates relative to the current origin
		until index fi_> len do
			rc_transxyout(	
				fast_subscrv(index, vec),
				fast_subscrv(index fi_+ 1, vec))
					-> ( fast_subscrv(index, vec),
						fast_subscrv(index fi_+ 1, vec));
			index fi_+ 2 -> index;
		enduntil;
		if closed then
			;;; add the last two coordinates
			fast_subscrv(1, vec) -> fast_subscrv(len fi_+ 1, vec);
			fast_subscrv(2, vec) -> fast_subscrv(len fi_+ 2, vec);
		endif;
	endif;

	if proc == XpwDrawLines then

		procedure();
			;;; use a procedure for dlocal to work

			dlocal rc_linewidth;
			if widthOrShape then widthOrShape -> rc_linewidth endif;

			XpwDrawLines(rc_window, vec, mode)

		endprocedure();

	elseif proc == XpwFillPolygon then

		unless
			;;; see REF XpwPixmap/SHAPE
			widthOrShape == Convex or widthOrShape == Nonconvex or widthOrShape == Complex
		then
			mishap('Wrong "shape" arg in line/poly drawing procedure',
				[^widthOrShape ])
		endunless;

		XpwFillPolygon(rc_window, vec, widthOrShape, mode)

	else
		mishap('Unrecognized "proc" argument in drawline/poly procedure',
					[^proc])
	endif;

	;;; Return vec to freelist.
	unless vec == coords then freepointvec(vec); endunless;
	
enddefine;


define rc_draw_lines(coords, colour, linewidth, mode);
	rc_draw_coords(coords, colour, linewidth, mode, false, XpwDrawLines);
enddefine;

define rc_draw_lines_closed(coords, colour, linewidth, mode);
	rc_draw_coords(coords, colour, linewidth, mode, true, XpwDrawLines);
enddefine;


define rc_draw_lines_filled(coords, colour, shape, mode);
	rc_draw_coords(coords, colour, shape, mode, false, XpwFillPolygon);
enddefine;

endsection;

/*

CONTENTS - (Use <ENTER> gg to access required sections)

 define lconstant rc_draw_coords(coords, colour, widthOrShape, mode, closed, procedure proc);
 define rc_draw_lines(coords, colour, linewidth, mode);
 define rc_draw_lines_closed(coords, colour, linewidth, mode);
 define rc_draw_lines_filled(coords, colour, shape, mode);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Aug 24 2000
	Allowed coords to be a vector, and to be re-used. In that case it
	is not given to freepointvec.
	Introduced more error checking.
 */
