/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/newprb/include/WID.ph
 > Purpose:         For getting Word identifiers into lists
 > Author:          Aaron Sloman, Apr 28 1996
 > Documentation:
 > Related Files:
 */


;;; For getting word identifiers in pattern lists
;;; This works only from Poplog V14.5
define lconstant macro WID;
	[ ("ident %readitem()% ") ].dl
enddefine;

/*
;;; Version for Poplog before V14.5
de*fine global constant macro WID;
	"(", """, word_identifier(readitem(), current_section, undef), """,")",
enddefine;
*/
