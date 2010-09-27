/* --- Copyright University of Birmingham 2002. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/async_vedinput.p
 > Purpose:         Put action on ved input stream
 > Author:          Aaron Sloman,  4 Jan 1997 (see revisions)
 > Documentation:
 > Related Files:	Based on LIB * MENU_VEDINPUT
 */

section;


define global async_vedinput(P);
	;;; This is needed for putting stuff on VED input stream in Xved
	;;; Otherwise do the actin immediately
	lvars procedure P;
	if vedusewindows == "x" and not(vedinvedprocss) then
		vedinput(P <> vedcheck <> vedsetcursor);
	else
		ved_apply_action(P)
	endif;
enddefine;

endsection;;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Sep  7 2002
		Added test for vedinvedprocess
 */
