/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_interpolate_coords.p
 > Purpose:			Interpolate between two lists of points
 > Author:          Aaron Sloman, Nov 16 2000
 > Documentation:	HELP RCLIB
 > Related Files:	LIB rc_draw_lines
 */

/*
uses rclib

;;; tests

vars ll = [ 0 0];
vars x;
for x from 1 to 10 do
	rc_interpolate_coords([0 0], [1 1], 10, x, ll)=>
endfor;

vars ll = { 0 0  0 0};

vars x;
for x from 0 to 10 do
	rc_interpolate_coords({0 0 1 1}, {0 1 1 0}, 10, x, ll)=>
endfor;

ll=>


*/

compile_mode :pop11 +strict;


section;

define rc_interpolate_coords(coords1, coords2, steps, stepnum, coords3) -> coords3;

	lconstant err = 'INTERPOLATING BETWEEN DIFFERENT LENGTH POINTLISTS';

	lvars
		len1 = length(coords1),
		len2 = length(coords2),
		len3 = length(coords3),
		ratio = (stepnum+0.0)/steps,
		index, x1, x2;

	if len1 /== len2 then
		mishap(err, [^coords1 ^coords2])
	elseif len1 /== len3 then
		mishap(err, [^coords1 ^coords3])
	endif;

	fast_for index from 1 to len1 do
		coords1(index) -> x1;
		coords2(index) -> x2;
		;;; rounding might be a mistake
		(x2 - x1)*ratio + x1 -> coords3(index);
		;;; round((x2 - x1)*ratio + x1) -> coords3(index);
	endfor;

enddefine;

endsection;
