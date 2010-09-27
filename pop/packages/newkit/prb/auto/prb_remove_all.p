/* --- The University of Birmingham 1995.  --------------------------------
 > File:            $poplocal/local/prb/auto/prb_remove_all.p
 > Purpose:			Remove all items matching patterns in a list, and
					return a list of those removed.
 > Author:          Aaron Sloman, Jul 2 1995 (hash table version) (see revisions)
 > Documentation:	HELP * POPRULEBASE.
					See example tests at end of this file
 > Related Files:
 */


section;
;;; A utility to remove all the items matching a list of patterns and
;;; return them.

uses prblib;
uses poprulebase;

;;; Changed: DNDavis: Tue Jun 27 14:49:35 BST 1995
;;; Further changed by A.Sloman July 2 1995.

define global vars procedure prb_remove_all(list_of_patterns)-> found;
	lvars
		list_of_patterns, found = [], pattern, item, key,
		keyslist = [],	;;; patterns sorted by (constant) key
		nokeys = [];	;;; patterns with no constant key

	;;; sort patterns by key
	lblock lvars list;
		for pattern in list_of_patterns do
			front(pattern) -> key;
			if prb_is_var_key(key) then
				;;; pattern starts with variable pattern element
				conspair(pattern, nokeys) -> nokeys;
			else
				fast_lmember(key, keyslist) -> list;
				if list then
					fast_back(list) -> list;
					;;; add the pattern
					conspair(pattern, fast_front(list)) -> fast_front(list)
				else
					;;; key not yet in keyslist
					;;; [^key [^pattern] ^^keyslist] -> keyslist;
					conspair(key, conspair(conspair(pattern,[]), keyslist)) -> keyslist
				endif;
    		endif
		endfor;
	endlblock;

	;;; We can now deal with individual keys, unless there are patterns
	;;; with no keys, in which case search everything
	if nokeys == [] then
		;;; All patterns have constant keys, so deal with each
		;;; sub-database in turn
		lblock lvars patts, list, found_one;
			;;; iterate over keyslist = [key patterns key patterns ....]
			repeat
			quitif(keyslist == []);
				fast_destpair(fast_destpair(keyslist))
					-> (key, patts, keyslist);
				;;; patts is a list of patterns starting with key
				false -> found_one;
				[%
					fast_for item in prb_database(key) do
						fast_for pattern in patts do
							if item matches pattern then
								[^item ^^found] -> found;
								true -> found_one;
								nextloop(2);
							endif
						endfor;
						;;; save the item, it's not to be removed
						item
					endfor;
             	%] -> list;
				if found_one then
					;;; something changed, set up new database
					list -> prb_database(key)
				else
					;;; nothing found, restore list to free list
					sys_grbg_list(list)
				endif;
			endrepeat
		endlblock
	else
		;;; some patterns with no keys
		sys_grbg_list(nokeys);
		appproperty(
			prb_database,
			procedure(key,val);
				lvars list, found_one = false;
				lvars key, val;
				returnif(key == "prb_data_stack");
				returnif(key == "prb_rule_stack");
				[%
					fast_for item in val do
						fast_for pattern in list_of_patterns do
							if item matches pattern then
								[^item ^^found] -> found;
								true -> found_one;
								nextloop(2);
							endif
						endfor;
						item
					endfor;
             	%] -> list;
				if found_one then
					list -> prb_database(key)
				else
					;;; nothing found, restore list to free list
					sys_grbg_list(list)
				endif;
			endprocedure
		);
	endif;
	;;; The following probably no longer makes sense since use of properties?
	fast_ncrev(found) -> found;
enddefine;

/*
;;; test procedure

prb_newdatabase(20,
	[ 	[a 1][a 2][a 3][a 4][a 5]
		[b 1][b 2][b 3][b 4][b 6]
		[c 1][c 2][c 3][c 4][c 5]
		[d 1][d 2][d 3][d 4][d 6]
	]) -> prb_database;
prb_print_database();
=>
prb_remove_all([[==]]) =>
prb_remove_all([[= = =]]) =>
prb_remove_all([[= 2]]) =>
prb_remove_all([[a =]]) =>
prb_remove_all([[a =] [b =]]) =>
prb_remove_all([[a =] [b =] [= 2]]) =>

*/

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Jul 15 1995
	Made it ignore the data stack and the rulestack.
 */
