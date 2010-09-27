/* --- The University of Birmingham 1994.  --------------------------------
 > File:            $poplocal/local/auto/ved_detabmr.p
 > Purpose:			De-tab marked range.
 > Author:          Aaron Sloman, Nov  8 1994
 > Documentation: below
 > Related Files:
 */
/*
ENTER detabmr
	Will remove tabs from the marked range while preserving layout.
*/

section;

define ved_detabmr;
	;;; remove tabs from marked range
	dlocal  vednotabs = true;
	veddo('sgsr/\t/\t')
enddefine;

endsection;
