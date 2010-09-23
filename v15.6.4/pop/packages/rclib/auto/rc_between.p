/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_between.p
 > Purpose:			Tell if a number is between two others
 > Author:          Aaron Sloman, May  1 1999
 > Documentation:
 > Related Files:
 */

section;
compile_mode :pop11 +strict;

define rc_between(x, v1, v2) /* -> boolean */ ;
	min(v1, v2) <= x and x <= max(v1, v2) /* -> boolean */ ;
enddefine;

endsection;
