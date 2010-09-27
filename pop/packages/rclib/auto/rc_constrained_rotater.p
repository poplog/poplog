/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_constrained_rotater.p
 > Purpose:			Create a constrained rotating object
 > Author:          Aaron Sloman, Jun 18 2000 (see revisions)
 > Documentation:	HELP RCLIB
 > Related Files:	lib rc_constrained_mover, rc_constrained_pointer
 */

section;

;;; compile_mode :pop11 +strict;
compile_mode
            :pop11 +varsch +defpdr -defcon -lprops -constr +global
            :vm +prmfix
            :popc -wrdflt -wrclos;



uses rclib
uses rc_constrained_mover

define :mixin vars rc_constrained_rotater;
	is rc_constrained_mover;

	;;; location around which pointer pivots
	;;; relative coords
	slot rc_pivot_x == 0;	;;; default - rotates about its centre
	slot rc_pivot_y == 0;
	;;; absolute coords, calculated from location, offset and orientation
	slot rc_real_pivot_x == false;	
	slot rc_real_pivot_y == false;
	
	slot rc_pivot_length;

	;;; coordinates of end of pointer relative to origin (rc_picx, rc_picy)
	slot rc_end_x ;	;;; movable end
	slot rc_end_y ;	;;; movable end

	;;; stuff for constraints, including a method to constrain the rotater
	slot rc_min_ang == false;
	slot rc_max_ang == false;
	slot rc_maxdiff == false;
	;;; direction opposite to direction half way between max and min angles
	slot rc_oppmiddiff;
	slot rc_constraint == "rc_constrain_rotater";

	;;; The orientation of the whole dial (not pointer) in degrees.
	;;; 0 = upright, 90 = rotated 90degrees clockwise
	;;; if rc_scale is positive and rc_yscale negative.
	slot rc_rotater_orient = 0;

enddefine;

define :method rc_setup_rotater(pic:rc_constrained_rotater);
	;;; setup derived slots after creation of instance

	lvars
		angmax = rc_max_ang(pic),
		angmin = rc_min_ang(pic),
		angmaxdiff = (angmax - angmin);

		if angmaxdiff /== 360 then
			angmaxdiff mod 360 -> angmaxdiff
		endif;

	lvars
		;;; middle direction, relative to angmin
		middiff = angmaxdiff*0.5;

	angmaxdiff  -> rc_maxdiff(pic);
	;;; direction opposite to the middle of the allowed sector
	(middiff + 180) mod 360 -> rc_oppmiddiff(pic);
enddefine;

define :method rc_constrain_rotater(pic:rc_constrained_rotater, vang) -> newang;
	;;; default filler of rc_constraint slot
	;;; Return a constrained (virtual) angle derived from vang, using pic's constraints
	lvars
		angmax = rc_max_ang(pic),
		angmin = rc_min_ang(pic),
		angmaxdiff = rc_maxdiff(pic);

	unless angmaxdiff then
		;;; set derived slots
		rc_setup_rotater(pic);
		rc_maxdiff(pic) -> angmaxdiff
	endunless;

	if angmax == angmin or angmaxdiff == 360 then

		;;; max and min effectively the same, or not set, so all angles permitted
		;;; just use the angle
		vang;
	else
		;;; try to constrain vang to lie between min and max (modulo 360 !)
		;;; use orientation of dial, and reverse direction, to get actual
		;;; angles of limits
		lvars
			orient = 180 - rc_rotater_orient(pic),
		;;; direction opposite to the middle of the allowed sector
			oppmiddiff = rc_oppmiddiff(pic);
		
		;;; (Note swap of max & min: hence use multiple assignment)
		(orient - angmin),
		(orient - angmax),
			-> (angmax, angmin);

		;;; [MIN ^angmin MAX ^angmax]=>
		
		lvars
			angdiff = (vang - angmin) mod 360;

		;;; angdiff should now be vang-angmin mod 360, i.e. must be positive.

		if angdiff > oppmiddiff then
			;;;  beyond direction opposite to middle direction, so use angmin
			angmin
		elseif angdiff > angmaxdiff then
			;;;  beyond direction of angmax, so use angmax
			angmax
		else
			;;; should be within range, so use the angle itself
			vang
        endif;
		
	endif -> newang;

	;;; [newang ^ newang] =>
enddefine;

define :method rc_pivot_coords(pic:rc_constrained_rotater);
	rc_pivot_x(pic), rc_pivot_y(pic)
enddefine;

define :method updaterof rc_pivot_coords(x, y, pic:rc_constrained_rotater);
	x -> rc_pivot_x(pic);
	y -> rc_pivot_y(pic);
enddefine;

define :method rc_real_pivot_coords(pic:rc_constrained_rotater) -> (x,y);

	rc_real_pivot_x(pic) -> x;
	if x then
		;;; already done
		rc_real_pivot_y(pic) -> y;
	else
		;;; compute the coords
		;;; start from coords of the object
		rc_coords(pic) -> (x,y);
		lvars
			(xp, yp) = rc_pivot_coords(pic);

		x+xp -> x; y+yp -> y;
		;;; save them
		x -> rc_real_pivot_x(pic); y -> rc_real_pivot_y(pic);
	endif
enddefine;

define :method updaterof rc_real_pivot_coords(x0, y0, pic:rc_constrained_rotater);

	mishap('Cannot change pivot coords', [%pic, x0, y0%]);

enddefine;

define :method rc_end_coords(pic:rc_constrained_rotater);
	;;; Coordinates of end relative to origin. Change when pointer moves
	rc_end_x(pic), rc_end_y(pic)
enddefine;

define :method updaterof rc_end_coords(/*x,y, */ pic:rc_constrained_rotater);
	/*x, y*/ -> (rc_end_x(pic), rc_end_y(pic))
enddefine;


define :method rc_real_end_coords(pic:rc_constrained_rotater) -> (x,y);
	;;; coorindates of end in rc_graphic coordinates
	lvars
		(x, y) = rc_coords(pic),
		(xp, yp) = rc_end_coords(pic);

	x + xp -> x; y + yp -> y;		
enddefine;

define :method updaterof rc_real_end_coords(x0, y0, pic:rc_constrained_rotater);
	lvars
		(x, y) = rc_coords(pic);
	x0 - x, y0 - y -> rc_end_coords(pic);
enddefine;

define :method rc_set_axis(pic:rc_constrained_rotater, ang, mode);

	;;; [ang ^ang] =>
	;;; first constrain the angle
	recursive_valof(rc_constraint(pic))(pic, ang) -> ang;
	;;; [constrained_ang ^ang]=>

	;;; Draw the picture with the new angle: will rotate
	call_next_method(pic, ang, mode);

	;;; Now set up new pivot ends	
	lvars
		(xp, yp) = rc_pivot_coords(pic),
		len = rc_pivot_length(pic),
        ;

	xp + len*cos(ang) -> rc_end_x(pic);
	yp + len*sin(ang) -> rc_end_y(pic);

	;;; debugging stuff
	;;; rc_draw_blob(rc_real_pivot_coords(pic), 20, 'red');
	;;; rc_draw_blob(rc_real_end_coords(pic), 10, 'blue');
	;;;dlocal pop_pr_places = 2;
	;;; [rotate ends %rc_pivot_coords(pic), rc_end_coords(pic), "ang", rc_axis(pic)%] =>
enddefine;

define :method rc_turn_by(pic:rc_constrained_rotater, ang, draw);
	;;; if ang is > 0, and rc_yscale < 0 turn clockwise
	rc_set_axis(pic, rc_axis(pic)-ang, draw)
enddefine;

define :method rc_oriented_angle(pic:rc_constrained_rotater, ang) -> ang;
	;;; is this needed??
	180 - rc_rotater_orient(pic) - ang -> ang;
enddefine;

define rc_actual_to_virtual_angle(pic, ang) -> vang;
	;;; assume rc_axis already constrained by rc_constraint(pic)
	;;; so compute angle relative to the orientation, clockwise if y goes up
	;;; and adjust if necessary by adding or subtracting 360, to keep
	;;; within desired range

	;;; Do converstion relative to new orientation

	(180 - rc_rotater_orient(pic) - ang) -> vang;

	;;; ensure within bounds
	if vang < rc_min_ang(pic) then
		vang + 360 -> vang;
	elseif vang > rc_max_ang(pic) then
		vang - 360 -> vang;
	endif;

enddefine;


define :method rc_virtual_axis(pic:rc_constrained_rotater) -> vang;

	rc_actual_to_virtual_angle(pic, rc_axis(pic)) -> vang;

enddefine;

define :method updaterof rc_virtual_axis(vang, pic:rc_constrained_rotater);
	;;; just reverse the above, but assume that vang is already in range.

	rc_set_axis(pic, (180 - rc_rotater_orient(pic) - vang), true);

enddefine;


define :method rc_ang_to_point(pic:rc_constrained_rotater, x, y) -> ang;
	;;; find the direction from pivot of the rotater to x,y
	;;; x,y are real coords

	lvars (x0, y0) = rc_real_pivot_coords(pic);

	if abs(x - x0) > 0.0001 or abs(y - y0) > 0.0001 then

		;;; assume X increases to the right for now
		arctan2(x - x0, y - y0) -> ang;
		;;; if ang < 0 then ang + 360 -> ang endif;

	else
		;;; points too close together, so leave pic unchanged
		rc_axis(pic) -> ang;
	endif;
	
enddefine;

define :method rc_move_to(pic:rc_constrained_rotater, x, y, mode);
	;;; rotate pointer to new location and redraw

	;;; rc_set_axis will operate constraints
	rc_set_axis(pic, rc_ang_to_point(pic, x, y), mode);

	;;; [move ends %rc_pivot_coords(pic), rc_end_coords(pic), rc_axis(pic) %] =>
enddefine;

define :method rc_move_by(pic:rc_constrained_rotater, dx, dy, draw);
	;;; Move a picture by amount dx, dy.
	lvars (x,y) = rc_real_end_coords(pic);
	rc_move_to(pic, x + dx, y + dy, draw);
enddefine;


;;; for uses
global vars rc_constrained_rotater = true;
endsection;

/*

CONTENTS

 define :mixin rc_constrained_rotater;
 define :method rc_setup_rotater(pic:rc_constrained_rotater);
 define :method rc_constrain_rotater(pic:rc_constrained_rotater, vang) -> newang;
 define :method rc_pivot_coords(pic:rc_constrained_rotater);
 define :method updaterof rc_pivot_coords(x, y, pic:rc_constrained_rotater);
 define :method rc_real_pivot_coords(pic:rc_constrained_rotater) -> (x,y);
 define :method updaterof rc_real_pivot_coords(x0, y0, pic:rc_constrained_rotater);
 define :method rc_end_coords(pic:rc_constrained_rotater);
 define :method updaterof rc_end_coords(/*x,y, */ pic:rc_constrained_rotater);
 define :method rc_real_end_coords(pic:rc_constrained_rotater) -> (x,y);
 define :method updaterof rc_real_end_coords(x0, y0, pic:rc_constrained_rotater);
 define :method rc_set_axis(pic:rc_constrained_rotater, ang, mode);
 define :method rc_turn_by(pic:rc_constrained_rotater, ang, draw);
 define :method rc_oriented_angle(pic:rc_constrained_rotater, ang) -> ang;
 define rc_actual_to_virtual_angle(pic, ang) -> vang;
 define :method rc_virtual_axis(pic:rc_constrained_rotater) -> vang;
 define :method updaterof rc_virtual_axis(vang, pic:rc_constrained_rotater);
 define :method rc_ang_to_point(pic:rc_constrained_rotater, x, y) -> ang;
 define :method rc_move_to(pic:rc_constrained_rotater, x, y, mode);
 define :method rc_move_by(pic:rc_constrained_rotater, dx, dy, draw);

*/

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  9 2002
		Changed compile mode
--- Aaron Sloman, Aug  6 2002
		Changed compile mode
--- Aaron Sloman, Aug 27 2000
	introduced slot rc_maxdiff
--- Aaron Sloman, Aug 26 2000
	Fixed rc_constrain_rotater, and made it mathematically clearer
	Added rc_virtual_axis(pic:rc_constrained_rotater)
--- Aaron Sloman, Jun 23 2000
	????
	Changed to rotate from right to left as angle increases. Also orientation.
 */
