/* --- Copyright University of Birmingham 2000. All rights reserved. ------
 > File:            $poplocal/local/prb/include/IFTRACING.ph
 > Purpose:         Control tracing instructions at compile time
 > Author:          Aaron Sloman, Apr 28 1996 (see revisions)
 > Documentation:
 > Related Files:
 */

;;; uses prb_tracing_on, defined in lib poprulebase

define lconstant macro IFTRACING;
	;;; if prb_tracing_on is false, ignore the next expression
	;;; up to the semicolon
	unless prb_tracing_on then
		lvars item;
		repeat
			readitem() -> item;
			quitif(item == ";")
		endrepeat;
	endunless;
enddefine;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jan 20 2000
	fixed headre
 */
