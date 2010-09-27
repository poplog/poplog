/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/fast_interpolate_coords.p
 > Purpose:			Interpolate between two lists of points
					Like rc_interpolate coords, but uses fast_subscrv
					Accepts ONLY vectors
 > Author:          Aaron Sloman, Nov 16 2000
 > Documentation:	HELP RCLIB
 > Related Files:	LIB rc_draw_lines
 */

/*
uses rclib

;;; tests

vars ll = { 0 0};
vars x;
for x from 1 to 10 do
	fast_interpolate_coords({0 0}, {1 1}, 10, x, ll)=>
endfor;

vars ll = { 0 0  0 0};

vars x;
for x from 0 to 10 do
	fast_interpolate_coords({0 0 1 1}, {0 1 1 0}, 10, x, ll)=>
endfor;

ll=>


*/

compile_mode :pop11 +strict;


section;

define fast_interpolate_coords(coords1, coords2, steps, stepnum, coords3) -> coords3;

	lconstant err = 'INTERPOLATING BETWEEN DIFFERENT LENGTH POINTLISTS';

	check_vector(coords1);
	check_vector(coords2);
	check_vector(coords3);

	lvars
		len1 = datalength(coords1),
		len2 = datalength(coords2),
		len3 = datalength(coords3),
		ratio = (stepnum+0.0)/steps,
		index, x1, x2;

	if len1 /== len2 then
		mishap(err, [^coords1 ^coords2])
	elseif len1 /== len3 then
		mishap(err, [^coords1 ^coords3])
	endif;

	fast_for index from 1 to len1 do
		fast_subscrv(index,coords1) -> x1;
		fast_subscrv(index,coords2) -> x2;
		;;; rounding might be a mistake
		(x2 - x1)*ratio + x1 -> fast_subscrv(index,coords3);
		;;; round((x2 - x1)*ratio + x1) -> coords3(index);
	endfor;

enddefine;

endsection;
