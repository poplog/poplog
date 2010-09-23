/* --- Copyright University of Birmingham 1997. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_RMODIFY.p
 > Purpose:			Recursive version of MODIFY
					Replaces values associated with key, and does it
					recursively on values that are lists. It does not
					recurse again after doing the substitution.
 > Author:          Aaron Sloman, Nov 11 1997
 > Documentation:	HELP * POPRULEBASE/MODIFY
 > Related Files:	LIB * POPRULEBASE/MODIFY
 */

section;
compile_mode :pop11 +strict;

uses poprulebase;

/*

copy_rmodify([a 1 b 2 c 3], [ x Y z W a CAT b DOG c W p q ]) =>
** [x Y z W a 1 b 2 c 3 p q]
copy_rmodify([a 1 b 2 c 3], [w X y Z p [a [the CAT] [b DOG] c W] p Q r [a T]]) =>
** [w X y Z p [a 1 [b DOG] c W] p Q r [a 1]]
copy_rmodify([a 1 b 2 c 3], [w X y Z p [a [the CAT] x [b DOG] c W] p Q r [a T]]) =>
** [w X y Z p [a 1 x [b 2] c 3] p Q r [a 1]]

*/


define copy_rmodify(modlist, list) -> list;
	;;; recursively do substitutions, in copy mode
	lvars value, key, oldval;
	unless atom(list) then
		[% until list == [] do
				fast_destpair(list) -> (key, list);
				key;
				if list == [] then
					;;; Odd item at end of list. Mishap??
					quitloop()
				endif;
				fast_destpair(list) -> (oldval, list);
				
				if prb_assoc(key, modlist) ->> value then
					value,
					;;; replaces next element
				elseif islist(oldval) then
					copy_rmodify(modlist, oldval)
				else
					oldval
				endif;
			enduntil
		%] -> list;
	endunless;
enddefine;

/*

vars
	tree1 = [ x Y z W a CAT b DOG c W p q ],
	tree2 = [w X y Z p [a [the CAT] [b DOG] c W] p Q r [a T]],
	tree3 =[w X y Z p [a [the CAT] x [b DOG] c W] p Q r [a T]];

nc_rmodify([a 1 b 2 c 3], tree1);
tree1 =>
** [x Y z W a 1 b 2 c 3 p q]

nc_rmodify([a 1 b 2 c 3], tree2);
tree2=>
** [w X y Z p [a 1 [b DOG] c W] p Q r [a 1]]

nc_rmodify([a 1 b 2 c 3], tree3);
tree3=>
** [w X y Z p [a 1 x [b 2] c 3] p Q r [a 1]]

*/

define nc_rmodify(modlist, list);
	;;; recursively do substitutions, in non-copy mode
	lvars value, key, oldval, oldlist;
	unless atom(list) then
		until list == [] do
			fast_destpair(list) -> (key, list);
			if list == [] then
				;;; Odd item at end of list. Mishap??
				quitloop()
			endif;
			list -> oldlist;
			fast_destpair(list) -> (oldval, list);
			if prb_assoc(key, modlist) ->> value then
				value -> fast_front(oldlist);
			elseif islist(oldval) then
				nc_rmodify(modlist, oldval);
			else
				;;; do nothing.
			endif;
		enduntil
	endunless;
enddefine;



define prb_RMODIFY(rule_instance, action);
	;;; Modlist is what followed [RMODIFY .. It should start with
	;;; either an integer n, or a pattern or list, followed by attribute
	;;; value pairs.
	;;; Remove the nth item of foundlist from prb_database, and
	;;; replace it with a modified version where the item following
	;;; key is the value. If prb_copy_modify is false then the
	;;; replacement is non-constructive, but modified items are
	;;; brought to the front of the database
	lvars n,
		foundlist = prb_foundof(rule_instance),
		modlist = fast_back(action),
		;

	dlocal prb_found = [], prb_recording = true; ;;; for prb_flush

	destpair(modlist) -> (n,  modlist);

	unless (listlength(modlist) mod 2) == 0 then
		mishap(modlist, 1, 'RMODIFY list has wrong number of elements')
	endunless;

	if isinteger(n) then
		;;;should match at most one thing.
		prb_do_DEL(n, foundlist);
	elseif ispair(n) then
		prb_flush(n)
	else
		mishap('INTEGER OR LIST NEEDED AFTER "RMODIFY"',
			[^action ^rule_instance])
	endif;

	;;; things deleted will now be in prb_found

	lvars item;
	if prb_copy_modify then
		fast_for item in prb_found do
			copy_rmodify(modlist, item) -> item;
			prb_add(item);
			;;; sys_grbg_list(prb_found);  ;;; ????? SAFE???
		endfor;
	else
		fast_for item in prb_found do
			nc_rmodify(modlist, item);
			prb_add(item);
			;;; sys_grbg_list(prb_found);  ;;; ????? SAFE???
		endfor;
		;;; sys_grbg_list(prb_found);  ;;; ????? SAFE???
	endif;

enddefine;

prb_RMODIFY -> prb_action_type("RMODIFY");

endsection;
