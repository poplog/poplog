/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/max_string_length.p
 > Purpose:			Find length of longest string in a vector of strings
 > Author:          Aaron Sloman, May  8 1999
 > Documentation:	HELP RCLIB
 > Related Files:
 */

section;

compile_mode :pop11 +strict;

define  max_string_length(vec)->num;
	;;; return the length of the longest string in vec
	lvars string, i;
	0-> num;
	fast_for i to datalength(vec) do
		fi_max(num, datalength(fast_subscrv(i,vec))) -> num
	endfor;
enddefine;


endsection;
