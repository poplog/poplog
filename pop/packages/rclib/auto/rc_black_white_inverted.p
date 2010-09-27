/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/rc_black_white_inverted.p
 > Purpose:         Check whether colours are as on Suns
 > Author:          Riccardo Poli and Aaron Sloman,  21 Mar 1997 (see revisions)
 > Documentation:
 > Related Files:
 */
/*

;;; Test

rc_black_white_inverted() =>

;;; Returns true if black = 0 and white = 1, as on DEC alphas,
;;; otherwise false, as on Suns.

*/

compile_mode: pop11 +strict;


section;
exload_batch;
uses xlib;
uses XlibMacros;

define rc_black_white_inverted() -> isinverted;
	unless XptDefaultDisplay then XptDefaultSetup(); endunless;
	XWhitePixel(XptDefaultDisplay, 0) /== 0 -> isinverted;
enddefine;

endexload_batch;
endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Mar 21 1997
	completely replaced previous version
 */
