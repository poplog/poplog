/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/rclib/lib/rc_exceed.p
 > Purpose:         Enable rclib to be used with eXceed running on a PC
 > Author:          Aaron Sloman, Apr 22 1999 (see revisions)
 > Documentation:   HELP * RCLIB_PROBLEMS, * RCLIB_NEWS
 > Related Files:
 */


uses rclib
uses rc_linepic
uses rc_setup_linefunction
rc_setup_linefunction();

/*
;;; This is now handled by rc_setup_linefunction

GXequiv -> Glinefunction;
rc_xor_drawpic -> Gdrawprocedure;	
*/

;;; for uses
vars rc_exceed = true;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 27 1999
	No longer needed.
 */
