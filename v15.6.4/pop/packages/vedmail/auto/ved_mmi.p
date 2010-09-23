/* --- Copyright University of Birmingham 1999. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_mmi.p
 > Purpose:			Move Mail In
 > Author:          Aaron Sloman, Mar  6 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

;;; $poplocal/local/auto/ved_mmi.p

;;; LIB VED_MMI                                              A.Sloman DEC 1985

;;; Move current message from 'other' file into this one
;;; Uses VED_MMO

section;

define ved_mmi;
	if vedargument = vednullstring then
		vedswapfiles()
	else ved_ved()
	endif;
	ved_mcm();
	vedswapfiles();					;;; go back to first file
	ved_mi();
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Dec 15 1999
	Changed to copy mail file to current location, not end of file.
 */
