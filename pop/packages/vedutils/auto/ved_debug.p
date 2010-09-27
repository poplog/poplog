/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/auto/ved_debug.p
 > Purpose:         toggle the value of pop_debugging
 > Author:          Aaron Sloman, Jun  3 1997
 > Documentation:
 > Related Files:
 */




define ved_debug();
	not(pop_debugging) -> pop_debugging;
	vedputmessage('DEBUG ' >< pop_debugging)
enddefine;
