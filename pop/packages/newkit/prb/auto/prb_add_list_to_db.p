/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/newsim/auto/prb_add_list_to_db.p
 > Purpose:         Add all elements of a list to the database
 > Author:          Aaron Sloman, Jul  7 1995
 > Documentation:
 > Related Files:	LIB * POPRULEBASE
 */

section;

;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr +global
			:vm +prmfix
			:popc -wrdflt -wrclos;

uses prblib;

define prb_add_list_to_db(list, dbtable);
	;;; add everything in the list to the table, not respecting order.
	lvars item, list, key, procedure dbtable;
	for item in list do
		front(item) -> key;
		conspair(item, dbtable(key)) -> dbtable(key);
	endfor
enddefine;
	
endsection;
