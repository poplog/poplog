/*  --- Copyright University of Sussex 1990. All rights reserved. ----------
 > File:           C.all/lib/sun/vedwin_adjust.p
 > Purpose:        adjust ved to suit (sun) window size
 > Author:         Ben Rubinstein, Mar  6 1986 (see revisions)
 */
compile_mode :pop11 +strict;

section;

define vars vedwin_adjust(/* l, c */) with_nargs 2;
	vedresize(/* l, c */);
enddefine;

endsection;


/* --- Revision History ---------------------------------------------------
--- Rob Duncan, May  2 1990
		Moved code out to a general (rather than Sun-specific) library
		LIB * VEDRESIZE
 */
