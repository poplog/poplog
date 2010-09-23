/* --- Copyright University of Birmingham 2001. All rights reserved. ------
 > File:            $poplocal/local/newkit/prb/auto/prb_save_database.p
 > Purpose:			Copy parts of a database, possibly restore it later
 > Author:          Aaron Sloman, Mar  9 2001
					and Catriona Kennedy
 > Documentation:	HELP sim_agent, HELP Poprulebase
 > Related Files:	LIB sim_agent
 */
/*

;;; TESTS

vars prb_noprint_keys = [below on at]

vars db1 = prb_newdatabase(10, [[on a b][under c d][on p q][on e f][in p][in r]]);

datalist(db1)==>

;;; check that include keys override exclude keys
prb_save_database(db1, [under in on], [on])==>
prb_save_database(db1, [on], false)==>
prb_save_database(db1, false, [in])==>
prb_save_database(db1, false, false)==>

vars list = prb_save_database(db1, false, [on]);

list ==>


vars db2 = prb_newdatabase(10, [[over a b][under p q][in x] [in y]]);
datalist(db2) ==>

;;; restore at front
prb_restore_database(list, db2, true);
datalist(db2) ==>

vars db2 = prb_newdatabase(10, [[over a b][under p q][in x] [in y]]);
datalist(db2) ==>
;;; restore at end
prb_restore_database(list, db2, false);
datalist(db2) ==>

*/


uses prblib;
uses poprulebase

;;; This variable defined in LIB poprulebase. It gets the value of
;;; sim_noprint_keys in LIB sim_agent
vars prb_noprint_keys;	

define prb_save_database(db, include_keys, exclude_keys) -> dblist;
	[%
		fast_appproperty(db,
			procedure(key, value);
				if include_keys then
					if fast_lmember(key, include_keys) then
						value
					endif
				elseunless fast_lmember(key, prb_noprint_keys) then
					unless exclude_keys and fast_lmember(key, exclude_keys) then
						value
					endunless
				endif;
			endprocedure);
	%] -> dblist;
enddefine;


define prb_restore_database(dblist, db, atfront);
	lvars item;
	for item in dblist do
		lvars key = front(front(item));
		if atfront then
			item <> db(key) -> db(key)
		else
			db(key) <> item -> db(key)
		endif
	endfor

enddefine;
