/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/rclib/auto/create_modified_instance.p
 > Purpose:
 > Author:          Aaron Sloman, Apr 17 1997
 > Documentation:
 > Related Files:
 */

/*
uses objectclass;

define :class trip;
	slot trip1 = 1;
	slot trip2 = 2;
	slot trip3 = 3;
enddefine;

vars atrip =
	create_modified_instance({{2 trip1}{1 trip2}}, newtrip);

atrip =>
** <trip trip1:2 trip2:1 trip3:3>

define updaterof tripcoords(vec, trip);
	lvars (x,y) = explode(vec);
	x -> trip1(trip);
	y -> trip2(trip)
enddefine;

vars btrip = create_instance(trip_key, {^tripcoords {22 11}});
btrip =>
*/


compile_mode :pop11 +strict;


section;

define update_slot(obj, vec);
	;;; obj is typically an objectclass instance. vec a vector whose last item is
	;;; a procedure or procedure name. Run the updater of the procedure on the
	;;; other vector elements and obj.
	;;; This is used to interpret elements in a button definition
	lvars pdr;
	;;; Put the elements of vec on the stack;
	explode(vec) -> pdr;
	;;; get the procedure
	recursive_valof(pdr) -> pdr;
	unless isprocedure(pdr) then
		mishap('Last element of vector should be procedure or its name',[^vec])
	endunless;
	;;; run the procedure
	->pdr(obj);
enddefine;


define create_modified_instance(vec, creator) -> object;
	creator() -> object;
	lvars item, count, lim = datalength(vec);

	for item in vec using_subscriptor subscrv do
		update_slot(object, item);
	endfor;
enddefine;

endsection;
