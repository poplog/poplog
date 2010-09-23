/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/async_compile.p
 > Purpose:			Compile instructions, with output to Ved buffer
 > Author:          Aaron Sloman, Apr 21 1997 (see revisions)
 > Documentation:
 > Related Files:
 */


section;

define vars async_compile(list);
	pop11_compile(list);
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Apr 27 1997
	Removed redirection of cucharout. Now done elsewhere
 */
