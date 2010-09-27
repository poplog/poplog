/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/menu/auto/menu_refresh.p
 > Purpose:         Refresh a menu
 > Author:          Aaron Sloman, Jan 21 1995
 > Documentation:
 > Related Files:
 */

/*
Call vedxrefresh or vedrefresh as appropriate
*/

section;

define global menu_refresh();
	if identprops("vedxrefresh") /= undef
	and isprocedure(valof("vedxrefresh")) then
		valof("vedxrefresh")()
	else
		vedrefresh();
	endif;
enddefine;

endsection;
