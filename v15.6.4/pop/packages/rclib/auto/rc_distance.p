/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_distance.p
 > Purpose:			compute distance between two points
 > Author:          Aaron Sloman, Jul  2 1997
 > Documentation:
 > Related Files:
 */

section;
compile_mode :pop11 +strict;

define rc_distance(x1, y1, x2, y2) -> dist;
	lvars dx = (x2 - x1), dy = (y2 - y1);
	sqrt( dx*dx + dy*dy) -> dist;
enddefine;

endsection;
