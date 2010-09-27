/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_list_data.p
 > Purpose:			Concatenate all database entries to a single list
 > Author:          Aaron Sloman, Jun 12 1995
 > Documentation:
 > Related Files:
 */

section;
;;; compile_mode:pop11 +strict;

compile_mode:pop11 +varsch +defpdr -lprops +constr  :vm +prmfix  :popc -wrdflt -wrclos;

uses prblib;
uses poprulebase;

define global procedure prb_list_data( dbtable ) -> list;
	;;; Given a database table return a single list of the items in it

	lvars procedure dbtable, list = [];

	fast_appproperty(
		dbtable,
		procedure(item, val);
			lvars item, val;
			val <> list->list;
		endprocedure
	);
enddefine;

endsection;
