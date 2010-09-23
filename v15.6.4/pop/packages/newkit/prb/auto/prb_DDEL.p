/* --- Copyright University of Birmingham 1998. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_DDEL.p
 > Purpose:         Management of dependencies
 > Author:          Aaron Sloman, 17 Feb 1998
 >					Suggested by Brian Logan
 > Documentation:
 > Related Files:	LIB * prb_DADD
 */

/*
         CONTENTS

 define prb_DADD(rule_instance, action);
 define lconstant part_of_justification(item, lists) -> (found, newlists);
 define prb_DDEL(rule_instance, action);
 define do_DDEL(item);

*/


uses poprulebase

section;
compile_mode :pop11 +strict;

;;; Activate the action keywords.
"prb_DADD" -> prb_action_type("DADD");
"prb_DDEL" -> prb_action_type("DDEL");

;;; THE MAIN PROCEDURES

;;; Action procedure for actions of the form [DADD <item> d1 d2 d3 ....]
;;; where d1, d2, ... are IDs of things on which <item> depends.

define prb_DADD(rule_instance, action);
    lvars item, dependees;

    fast_destpair(fast_back(action)) -> (item, dependees);

    dlocal prb_found, popmatchvars = [];

    ;;; item must be fully instantiated, so use fast check
    unless prb_instance_present(item) then
		prb_add(item);
    endunless;

	;;; get a list of actual database items corresponding to the dependees
	lvars dependee, actual_dependees;
	[%
	  for dependee in dependees do
		if islist(dependee) then
			prb_match_apply(prb_database, dependee, identfn)
		endif
	  endfor
	%] -> actual_dependees;

	;;; [actual_dependees ^actual_dependees] ==>

    if actual_dependees == [] then
		;;; ???  Should this mishap??
	else
		lvars olddependees;
    	if prb_in_database(![justified ^item ??olddependees]) then

	    	;;; add new set of dependencies
			conspair(actual_dependees, olddependees) ->
					fast_back(fast_back(prb_found));
		else
	    	;;; create new [justified ...] assertion.
            prb_add([justified ^item ^actual_dependees]);
    	endif;
	endif;
enddefine;

/*
part_of_justification("cat", [[a is b][cat dog mouse] [1 2 3] [a cat]]) =>
** <true> [[a is b] [1 2 3]]
part_of_justification("hat", [[a is b][cat dog mouse] [1 2 3] [a cat]]) =>
** <false> []

*/

define lconstant part_of_justification(item, lists) -> (found, newlists);
	;;; If item is in one of the elements of lists set found = true,
	;;; otherwise false
	;;; If found is true also return a lists of those lists not containing
	;;; item, or [] if found is false.
	lvars list, found = false;
	[%for list in lists do
		if fast_lmember(item, list) then
			true -> found
		else
			list
		endif;
	endfor%] -> newlists;
	unless found then
		sys_grbg_list(newlists);
		[] -> newlists;
	endunless;
enddefine;

lconstant procedure do_DDEL;

;;; Action procedure for actions of the form [DDEL item]
;;; (or should it be [DDEL item_id ] ???)
define prb_DDEL(rule_instance, action);
    do_DDEL(fast_front(fast_back(action)));
enddefine;

;;; Recursively delete item and anything that depends on it.
;;; Used in prb_DDEL
define lconstant do_DDEL(item);

	lvars old_copy_modify = prb_copy_modify;

    dlocal prb_found, prb_copy_modify;

    ;;; Get rid of the item. This should set prb_found as a list containing the item.
    prb_flush1(item);

	returnunless(prb_found);

	fast_front(prb_found) -> item;

	lvars
		record,
		data = prb_database("justified");

	;;;;[data ^^data]==>

	;;; data is a list of records of form [justified <datum> <list> <list> ....]
	;;; where each list is a list of jointly sufficient justifications for
	;;; <datum>
	fast_for record in data do
		;;;;[checking ^item in ^record]==>
		lvars
			datum = fast_front(fast_back(record));
		if datum == item then
			;;; delete any record of what item depends on
			false -> prb_copy_modify;
    		prb_flush1(record);
			old_copy_modify -> prb_copy_modify;
		else
			;;; see if item is part of any justification in this record
			lvars
				dependees = fast_back(fast_back(record)),
				(found, newlists) = part_of_justification(item, dependees);

			if found then
				if newlists == [] then
					;;; no other justification for this datum, so remove it and
					;;; the justification record
					false -> prb_copy_modify;
    				prb_flush1(record);
					old_copy_modify -> prb_copy_modify;

					;;; found datum that depends on item, so delete it,
					;;; and things that depend on it
					do_DDEL(datum)
				else
					;;; Record only remaining dependencies not including item
					newlists -> fast_back(fast_back(record));
					;;; old tail is now garbage
					sys_grbg_list(dependees);
				endif;
			endif;
		endif;
	endfor;

enddefine;

endsection;
