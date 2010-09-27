/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/menu_vedinput.p
 > Purpose:         Put action on ved input stream
 > Author:          Aaron Sloman, Jan 21 1995 (see revisions)
 > Documentation:
 > Related Files:
 */

section;

define global menu_vedinput(P);
	;;; This is needed for putting stuff on VED input stream in Xved
	lvars P;
	if vedusewindows == "x" and not(vedinvedprocess) then
		vedinput(P <> vedcheck <> vedsetcursor);
	else
		P()
	endif;
enddefine;

endsection;;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  7 2002
		Added check for vedinvedprocess
--- Aaron Sloman, Feb 5th 1995
	Made to use vedinput only if vedusewindows = "x" true
 */
