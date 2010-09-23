/*  --- Copyright University of Sussex 1986.  All rights reserved. ---------
 >  File:           C.all/lib/lib/outlines.p
 >  Purpose:        draw overlapping rectangles
 >  Author:         Max Clowes (see revisions)
 >  Documentation:  TEACH * LABELLING
 >  Related Files:  LIB * OVERLAY
 */

#_TERMIN_IF DEF POPC_COMPILING

compile_mode :pop11 +oldvar;

turtle();
vars occluded;

define ahead()->result;
vars x y;
	Newposition(1) -> y -> x;
	if picture(round(x),round(y)) /== space
	then not(occluded)->occluded; true
	elseif occluded then true
	else false
	endif -> result
enddefine;

define drawside(dist);
	repeat dist times
		(if ahead() then tjump else tdraw endif)(1)
	endrepeat;
	turn(90)
enddefine;

define rect(place,width,height);
	vars x1 y1 occluded;
	dl(place)->y1 ->x1;
	false->occluded;
	jumpto(x1,y1);
	drawside(width); drawside(height);
	drawside(width); drawside(height);
enddefine;
