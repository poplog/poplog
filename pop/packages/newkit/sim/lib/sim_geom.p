/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/sim/lib/sim_geom.p
 > Purpose:         Handle notion of current direction associated with
					and object,and also angle computations.
					Also other geometric computations.
 > Author:          Aaron Sloman, Apr  7 1996 (see revisions)
 > Documentation:	HELP * SIM_GEOM
 > Related Files:
 */


/*
;;;Test

vars a1 = sim_init_angle(90), a2 = sim_init_angle(45);

a1 =>

sim_rotate_angle(a1, 45);

a1 =>

sim_angle_diff(a1, a2)=>

sim_angle_diff(a2, a1)=>

sim_angle_xy(0,10) =>
sim_angle_xy(-100,-100) =>

sim_heading_from(10,10, 0, 20)=>
sim_heading_from(10,10, 0, 0)=>

sim_distance_from(0, 0, 10, 10) =>
sim_distance_from(0, 0, 0, 10) =>
sim_distance_from(10, 10, -90, -90) =>

sim_subtend_ang(20, 40) =>

sim_subtend_ang(17.3205, 20) =>

sim_intersect_lines(0, 0, 0, 1, 2, 0, 2, 4) =>
    ** <false> <false>
sim_intersect_lines(0, 0, 0, 1, 2, 0, 2, -4) =>
    ** <false> <false>
sim_intersect_lines(0, 0, 10, 10, 0, 10, 10, 0) =>
    ** 5 5
sim_intersect_lines(0, 0, -10, -10, 0, -10, -10, 0) =>
    ** -5 -5
sim_intersect_lines(0, 0, -100, 100, -50, 0, -50, 100) =>
    ** -50 50
sim_intersect_lines(0, 0, -100, 100, 50, 0, 50, 100) =>
    ** 50 -50
sim_intersect_lines(0, 0, -100, 100, 50, 0, 50, -100) =>
    ** 50 -50

sim_intersect_segs(0, 0, 0, 1, 2, 0, 2, 4) =>
    ** <false> <false>
sim_intersect_segs(0, 0, 0, 1, 2, 0, 2, -4) =>
    ** <false> <false>
sim_intersect_segs(0, 0, 10, 10, 0, 10, 10, 0) =>
    ** 5 5
sim_intersect_segs(0, 0, -10, -10, 0, -10, -10, 0) =>
    ** -5 -5
sim_intersect_segs(0, 0, -100, 100, -50, 0, -50, 100) =>
    ** -50 50

;;; three cases where lines intersect but not the segments
sim_intersect_lines(0, 0, -100, 100, 50, 0, 50, 100) =>
    ** 50 -50
 sim_intersect_segs(0, 0, -100, 100, 50, 0, 50, 100) =>
    ** <false> <false>
sim_intersect_lines(0, 0, -100, 100, 50, 0, 50, -100) =>
    ** 50 -50
 sim_intersect_segs(0, 0, -100, 100, 50, 0, 50, -100) =>
    ** <false> <false>
sim_intersect_lines(0, 0, -100, 0, 0, 50, 100, 150) =>
    ** -50 0
 sim_intersect_segs(0, 0, -100, 0, 0, 50, 100, 150) =>
    ** <false> <false>

sim_intersect_segs(50, -50, -100, 100, 50, 0, 50, -100) =>
    ** 50 -50
sim_intersect_segs(0, 0, -100, 0, 0, 50, -100, -100) =>
    ** -100_/3 0
sim_intersect_segs(0, 0, -100, 0, 0, 50, -100, -50) =>
    ** -50 0

*/




section;

compile_mode :pop11 +strict;

defclass sim_angle{sim_degrees, sim_cos, sim_sin};

procedure(ang) with_props sim_print_angle;
	printf(sim_degrees(ang), '<sim_angle %P>')
endprocedure -> class_print(sim_angle_key);


define sim_normalise_angle(degrees) /*-> degrees */ ;
	while degrees >= 360.0 do
		degrees - 360.0 -> degrees
	endwhile;
	while degrees < 0 do
		degrees + 360.0 -> degrees
	endwhile;
	degrees
enddefine;

define sim_set_angle(angle, degrees);
	;;; update the angle record to correspend to degrees
	dlocal popradians = false;

	sim_normalise_angle(degrees), cos(degrees), sin(degrees), fill(angle) ->;

enddefine;

define sim_init_angle(degrees) /* -> angle */;
	;;; create an angle record
	conssim_angle(sim_normalise_angle(degrees), cos(degrees), sin(degrees))
enddefine;

define sim_degrees_diff(degrees1, degrees2) /* -> diff */;
	;;; assume both degrees1 and degrees2 are in range 0 to 360
	;;; subtract and return a number in range -180 to 180
	;;; return a number
	lvars diff = degrees1 - degrees2;
	if diff > 180 then
		diff - 360
	elseif diff <= -180 then diff + 360
	else diff
	endif
enddefine;

/*
test

sim_degrees_diff(0,3) =>
sim_degrees_diff(0,-3) =>
sim_degrees_diff(360,3) =>
sim_degrees_diff(3, 360) =>
sim_degrees_diff(358, 360) =>
sim_degrees_diff(-3, 360) =>
sim_degrees_diff(3, 5) =>
sim_degrees_diff(5, 3) =>
sim_degrees_diff(3, 365) =>
sim_degrees_diff(365, 3) =>
sim_degrees_diff(180, 3) =>
sim_degrees_diff(180, 359) =>
sim_degrees_diff(180, 0) =>
sim_degrees_diff(0, 180) =>

*/

/*
sim_angle_diff(3,0) =>
sim_angle_diff(359,0) =>

*/

define sim_rotate_angle(angle, degrees);
	lvars angle;
	;;; add the angle to the current frame angle, then set
	;;; rc_rotate_cos and rc_rotate_sin
	sim_set_angle(angle, degrees + sim_degrees(angle));
enddefine;

define sim_angle_diff(angle1, angle2) /* -> degrees */ ;

	sim_degrees(angle1) - sim_degrees(angle2) /* -> degrees */

enddefine;

define sim_angle_xy(x, y) -> degrees  ;
	;;; given coordinates of point work out angle, between 0 and 360
	dlocal popradians = false;
	arctan2(x,y) -> degrees;
	if degrees < 0 then
		degrees + 360 -> degrees
	endif
enddefine;

define sim_heading_from(x1, y1, x2, y2) /* -> heading */;
	sim_angle_xy(x2 - x1, y2 - y1) /* -> heading */
enddefine;

define sim_distance_from(x1, y1, x2, y2) /* -> dist */;
	sqrt(((x2 - x1).dup *) + ((y2 - y1).dup *)) /* -> dist */
enddefine;
/*
sim_distance_from(0,0,3,4) =>
sim_distance_from(-3,4,0,0) =>

*/

define sim_subtend_ang(dist, width) /* -> degrees*/;
	;;; return angle subtended by object of width at distance d.
	sim_angle_xy(dist + dist, width) * 2 /* -> degrees */
enddefine;

define sim_intersect_lines(xa, ya, xb, yb, xc, yc, xd, yd) -> (x, y);
	;;; does the line joining (xa ya) to (xb yb) intersect the
	;;; line joining (xc yc) to (xd yd)?
	;;; If so return coords of the intersection point otherwise (false false)
	lvars
		dx1 = (xb - xa), dy1 = (yb - ya),
		dx2 = (xd - xc), dy2 = (yd - yc),
		d = (dy1 * dx2 - dx1 * dy2) ;

	define intersect(xa, ya, xb, yb, dx1, dy1, xc, yc, xd, yd, dx2, dy2, d);
		(yd * dx1 * dx2 - dy2 * dx1 * xd + dy1 * dx2 * xa - dx1 * dx2 * ya)
			/ d
	enddefine;

	if abs(d) < 0.000001 then
		false ->> (x,y)
	else

		intersect(xa, ya, xb, yb, dx1, dy1, xc, yc, xd, yd, -dx2, -dy2, -d) -> x;
		intersect(ya, xa, yb, xb, dy1, dx1, yc, xc, yd, xd, -dy2, -dx2, d) -> y;
	endif;
enddefine;


define sim_intersect_segs(xa, ya, xb, yb, xc, yc, xd, yd) -> (x, y);
	;;; does the segment joining (xa ya) to (xb yb) intersect the
	;;; segment joining (xc yc) to (xd yd)?
	;;; If so return coords of the intersection point otherwise (false false)

	sim_intersect_lines(xa, ya, xb, yb, xc, yc, xd, yd) -> (x, y);

	define is_between(x, y, z);
		;;; is the value of x between those of y and z
		if z >= y then
			x >= y and z >= x
		else
			y >= x and x >= z
		endif;
	enddefine;

	if x then
		;;; find out if the intersection point is actually on the lines
		unless is_between(x, xa, xb) and is_between(x, xc, xd)
		 	and is_between(y, ya, yb) and is_between(y, yc, yd)
		then
			false ->> (x,y)
		endunless
	endif;

enddefine;

/*
is_between(0, 5, 10)=>
is_between(5, 5, 10)=>
is_between(7, 5, 10)=>
is_between(10, 5, 10)=>
is_between(15, 5, 10)=>

is_between(0, 10, 5)=>
is_between(5, 10, 5)=>
is_between(7, 10, 5)=>
is_between(10, 10, 5)=>
is_between(15, 10, 5)=>


*/



;;; for "uses sim_geom"
global vars sim_geom = true;
endsection;

/*
CONTENTS (define)

 define sim_normalise_angle(degrees) /*-> degrees */ ;
 define sim_set_angle(angle, degrees);
 define sim_init_angle(degrees) /* -> angle */;
 define sim_degrees_diff(degrees1, degrees2) /* -> diff */;
 define sim_rotate_angle(angle, degrees);
 define sim_angle_diff(angle1, angle2) /* -> degrees */ ;
 define sim_angle_xy(x, y) -> degrees  ;
 define sim_heading_from(x1, y1, x2, y2) /* -> heading */;
 define sim_distance_from(x1, y1, x2, y2) /* -> dist */;
 define sim_subtend_ang(dist, width) /* -> degrees*/;
 define sim_intersect_lines(xa, ya, xb, yb, xc, yc, xd, yd) -> (x, y);
 define sim_intersect_segs(xa, ya, xb, yb, xc, yc, xd, yd) -> (x, y);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jun 26 1999
	Fixed bug in sim_intersect_segs found by Natalie Andrew:
		the test was erroneous where one of the segments is vertical.
--- Aaron Sloman, Jun  4 1996
	changed sim_degrees_diff to return a signed result
 */
