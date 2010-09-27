/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:            $poplocal/local/newkit/prb/auto/prb_check_cycle_limit_and_vars.p
 > Purpose:			New version handles intervals
 > Author:          Aaron Sloman, Jul  5 1999 (see revisions)
 > Documentation:
 > Related Files:
 */

/* --- Copyright University of Birmingham 1996. All rights reserved. ------
 > File:            $poplocal/local/prb/auto/prb_check_cycle_limit_and_vars.p
 > Purpose:			Given a rulesystem or ruleset check whether there's a
 >					cycle limit or matchvar spec
 > Author:          Aaron Sloman, Apr 20 1996
 > Documentation:
 > Related Files:
 */

/*

;;; test it

[] -> popmatchvars;
vars vva = 0, vec=undef, lim=undef;
vars list = [1 {[vva vvb] ^(procedure;999 -> vva; [vva ^vva] => end)} p q r ];
vars list2 = [{[vva vvb] ^(procedure;999 -> vva; [vva ^vva] => end)} 4 p q r s t];
vars list3 = [4 p q r s t];
vars list4 = [p q r s t];
list ==>
prb_check_cycle_limit_and_vars(list) -> (lim, vec, list);
lim =>
vec =>
list =>
prb_check_cycle_limit_and_vars(list2) =>
prb_check_cycle_limit_and_vars(list3) =>
prb_check_cycle_limit_and_vars(list4) =>
popmatchvars =>
[] -> popmatchvars;
*/

compile_mode :pop11 +strict;

section;
include IFSECTIONS.ph

define prb_check_cycle_limit_and_vars(list) -> (lim, vec, list);
	lvars lim = false, vec = false, item;
	unless islist(list) then
		mishap('List needed', [^list])
	endunless;

	unless list == [] then
		repeat
			;;; search for limit, and lvars vector or vars vector at beginning of
			;;; ruleset, also section
			;;; Assume the ruleset is not empty
			if ispair(list) and isprbrule(fast_front(list) ->> item) then
				return();
			elseif isvector(item) then
				lvars key = fast_subscrv(1, item);
				if key == "limit" then
				;;; Rulesets starts with an integer for cycle limit.
					item -> lim;
					fast_back(list) -> list
				elseif key == "interval" then
					item -> lim;
					fast_back(list) -> list
				elseif key == "rulesystem_interval" then
					;;; end of rulesystem declarations
					return();
				elseif (prb_check_vars_vec(item) ->> vec) then
					fast_back(list) -> list
					;;; continue, in case there are two vectors (one for vars, one for lvars)
				else
					mishap('Strange vector in rulesystem', [^vec]);
				endif
			IFSECTIONS
			elseif issection(item) and item /== current_section then
				item -> current_section;	;;; ";" needed for IFSECTIONS
			else
				return();
			endif;
			returnif(list == []);
		endrepeat;
	endunless
enddefine;

endsection;

/* --- Revision History ---------------------------------------------------
--- Aaron Sloman, Nov  7 2003
	Fixed endless loop reported by Brian Logan by inserting
			returnif(list == []);
	before endrepeat.
--- Aaron Sloman, Jul  5 1999
	Changed to handle intervals
 */
