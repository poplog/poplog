/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/newprb/include/IFSECTIONS.p
 > Purpose:         Compile time control of whether sections are used
 > Author:          Aaron Sloman, Apr 28 1996
 > Documentation:
 > Related Files:
 */
;;; uses prb_use_sections, defined in lib poprulebase

define lconstant macro IFSECTIONS;
	;;; if prb_use_sections is false, ignore the next expression
	;;; up to the semicolon
	unless prb_use_sections then
		lvars item;
		repeat
			readitem() -> item;
			quitif(item == ";")
		endrepeat;
	endunless;
enddefine;
